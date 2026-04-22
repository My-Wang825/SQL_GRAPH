# -*- coding: utf-8 -*-
import os
import json
import time
import logging
from threading import Lock
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from ..config import (
    BASE_DIR,
    DATA_DIR,   # 全量数据目录
    SQL_EXTENSIONS,
    SECTOR_DATA_DIRS,  # 业务板块数据目录
    MINIMAX_API_KEY,  # MiniMax API 密钥
    MINIMAX_BASE_URL,  # MiniMax API 基础 URL
    MINIMAX_MODEL,  # MiniMax API 模型
    METRICS_LINEAGE_QUERY_ALL_URL,
    METRICS_TENANT_ID,
    METRICS_AUTH_VALUE,
    METRICS_GOVERNANCE_MERGE_JSON,
)
from ..parser import ETLSqlParser  # 解析器
from ..graph import GraphBuilder  # 图谱构建器
from ..graph.metrics_governance_merge import (
    merge_metrics_lineage_into_payload,
    should_apply_metrics_merge_for_sector,
)
from .schemas import (
    GraphResponse,  # 图谱响应
    BuildGraphRequest,
    AgentAskRequest,
    AgentAskResponse,
    AgentHighlight,
    MetricsLineageSummaryResponse,
)
from ..metrics import MetricsLineageClientError
from ..metrics.service import fetch_parsed_lineage
from ..agent.minimax_client import (
    answer_with_graph_and_files,
    stream_answer_with_graph_and_files,
)

router = APIRouter(prefix="/api", tags=["api"])
logger = logging.getLogger(__name__)
_GRAPH_CACHE = {}
_GRAPH_CACHE_LOCK = Lock()
_GRAPH_CACHE_TTL_SEC = 120.0


def _collect_sql_files(data_dir: str):
    files = []
    data_dir = os.path.abspath(data_dir)
    if not os.path.isdir(data_dir):
        return files
    for root, _, names in os.walk(data_dir):
        for name in names:
            if name.lower().endswith(SQL_EXTENSIONS):
                files.append(os.path.join(root, name))
    return files


def build_graph_payload(sector: str, data_dir: str, use_cache: bool = True) -> dict:
    """构建图谱 JSON dict（nodes/links/meta），供 /api/graph 与 Agent 复用。"""
    dir_to_use = _resolve_graph_dir(sector, data_dir)
    if not os.path.isdir(dir_to_use):
        raise HTTPException(status_code=400, detail=f"数据目录不存在: {dir_to_use}")
    cache_key = f"{(sector or '').strip().upper()}|{os.path.abspath(dir_to_use)}"
    now = time.time()
    if use_cache:
        with _GRAPH_CACHE_LOCK:
            item = _GRAPH_CACHE.get(cache_key)
            if item and (now - float(item.get("ts") or 0)) <= _GRAPH_CACHE_TTL_SEC:
                return item["payload"]
    parser = ETLSqlParser() #扫描到的每个 .sql/.txt 调用 parser.parse_file(fp)，得到表列表和关系列表
    builder = GraphBuilder() #将表列表和关系列表添加到图谱中
    sql_files = _collect_sql_files(dir_to_use) 
    for fp in sql_files:
        try:
            table_list, relations, _ = parser.parse_file(fp)
            builder.add_tables_from_parse(table_list)
            builder.add_relations_from_parse(relations)
        except Exception as e:
            logger.warning("解析文件失败: %s, error=%s", fp, e)
            continue
    result = builder.to_vis_json()
    if should_apply_metrics_merge_for_sector(sector, data_dir, dir_to_use):
        result = merge_metrics_lineage_into_payload(result, METRICS_GOVERNANCE_MERGE_JSON)
    if use_cache:
        with _GRAPH_CACHE_LOCK:
            _GRAPH_CACHE[cache_key] = {"ts": now, "payload": result}
    return result


def _resolve_graph_dir(sector: str, data_dir: str) -> str:
    """解析图谱数据目录：优先 sector 白名单，其次受限的自定义路径。"""
    key = (sector or "").strip().upper().replace("-", "_")
    if key:
        if key not in SECTOR_DATA_DIRS:
            raise HTTPException(
                status_code=400,
                detail=f"未知板块 sector={sector!r}，可选: {', '.join(SECTOR_DATA_DIRS)}",
            )
        return SECTOR_DATA_DIRS[key]
    if (data_dir or "").strip():
        raw = data_dir.strip()
        path = raw if os.path.isabs(raw) else os.path.join(BASE_DIR, os.path.normpath(raw))
        path = os.path.abspath(path)
        base = os.path.abspath(BASE_DIR)
        try:
            under = os.path.commonpath([path, base]) == base
        except ValueError:
            under = False
        if not under:
            raise HTTPException(status_code=400, detail="数据目录必须在项目根目录内")
        if not os.path.isdir(path):
            raise HTTPException(status_code=400, detail=f"数据目录不存在: {path}")
        return path
    return SECTOR_DATA_DIRS["PRD_AL"]


@router.get("/metrics/lineage/summary", response_model=MetricsLineageSummaryResponse)
def metrics_lineage_summary(sample_limit: int = 20):
    """
    调用指标平台 queryAll，解析并返回数据集 / 指标 / 物化表数量及样例顶点。
    依赖环境变量 METRICS_LINEAGE_QUERY_ALL_URL、METRICS_TENANT_ID、METRICS_AUTH_VALUE 等。
    """
    if not METRICS_LINEAGE_QUERY_ALL_URL:
        raise HTTPException(
            status_code=503,
            detail="未配置 METRICS_LINEAGE_QUERY_ALL_URL，无法拉取指标血缘",
        )
    if not METRICS_TENANT_ID or not METRICS_AUTH_VALUE:
        raise HTTPException(
            status_code=503,
            detail="未配置 METRICS_TENANT_ID 或 METRICS_AUTH_VALUE",
        )
    if sample_limit < 1:
        sample_limit = 1
    if sample_limit > 200:
        sample_limit = 200
    try:
        parsed = fetch_parsed_lineage()
    except MetricsLineageClientError as e:
        logger.warning("指标血缘拉取失败: %s", e)
        raise HTTPException(status_code=502, detail=str(e)) from e
    d = parsed.to_summary_dict(sample_limit=sample_limit)
    return MetricsLineageSummaryResponse(**d)


@router.get("/graph", response_model=GraphResponse)
def get_graph(sector: str = "", data_dir: str = ""):
    """构建并返回图谱 JSON。默认仅电解铝 PRD_AL；氧化铝使用 ?sector=PRD_AO"""
    result = build_graph_payload(sector, data_dir)
    return GraphResponse(**result)


@router.post("/graph/build", response_model=GraphResponse)
def build_graph(req: BuildGraphRequest):
    """从指定目录构建图谱"""
    result = build_graph_payload("", req.data_dir or "", use_cache=False)
    return GraphResponse(**result)


def _sector_code_from_request(sector: str, data_dir: str) -> str:
    s = (sector or "").strip().upper().replace("-", "_")
    if s:
        return s
    raw = (data_dir or "").replace("\\", "/")
    for code in ("PRD_AO", "PRD_AL"):
        if code.lower() in raw.lower():
            return code
    return "PRD_AL"


@router.post("/agent/ask", response_model=AgentAskResponse)
def agent_ask(req: AgentAskRequest):
    """自然语言问答：仅通过模型结合图谱与 data SQL 文件生成回答。"""
    payload = build_graph_payload(req.sector or "", req.data_dir or "")
    out = answer_with_graph_and_files(
        req.question.strip(),
        payload.get("nodes") or [],
        payload.get("links") or [],
        api_key=MINIMAX_API_KEY,
        base_url=MINIMAX_BASE_URL,
        model=MINIMAX_MODEL,
    )
    hl = out.get("highlight") or {}
    return AgentAskResponse(
        answer=out.get("answer", ""),
        intent=out.get("intent", "unknown"),
        intent_label=out.get("intent_label", "未知"),
        confidence=float(out.get("confidence") or 0),
        highlight=AgentHighlight(
            node_ids=hl.get("node_ids") or [],
            links=hl.get("links") or [],
        ),
        matches=out.get("matches") or [],
    )


@router.post("/agent/ask/stream")
def agent_ask_stream(req: AgentAskRequest):
    """自然语言问答（流式）：逐段返回文本，结束时附带高亮与元信息。"""
    payload = build_graph_payload(req.sector or "", req.data_dir or "")

    def _event_stream():
        for evt in stream_answer_with_graph_and_files(
            req.question.strip(),
            payload.get("nodes") or [],
            payload.get("links") or [],
            api_key=MINIMAX_API_KEY,
            base_url=MINIMAX_BASE_URL,
            model=MINIMAX_MODEL,
        ):
            yield "data: " + json.dumps(evt, ensure_ascii=False) + "\n\n"

    return StreamingResponse(
        _event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
