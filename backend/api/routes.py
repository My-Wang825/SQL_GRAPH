# -*- coding: utf-8 -*-
from __future__ import annotations

import json
import os
import time
import logging
from threading import Lock
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from ..config import (
    MINIMAX_API_KEY,  # MiniMax API 密钥
    MINIMAX_BASE_URL,  # MiniMax API 基础 URL
    MINIMAX_MODEL,  # MiniMax API 模型
    METRICS_LINEAGE_QUERY_ALL_URL,
    METRICS_TENANT_ID,
    METRICS_AUTH_VALUE,
    METRICS_GOVERNANCE_MERGE_JSON,
    GRAPH_LOCAL_SQL_FALLBACK,
    SECTOR_DATA_DIRS,
    SQL_EXTENSIONS,
    SECTOR_LOCAL_PY_SCRIPT_CODES,
)
from ..parser import ETLSqlParser  # 解析器
from ..graph import GraphBuilder  # 图谱构建器
from ..graph.metrics_governance_merge import (
    merge_metrics_lineage_into_payload,
    should_apply_metrics_merge_for_sector,
)
from ..governance_sql_source import (
    fetch_sql_records_grouped,
    resolve_sector_codes,
    sector_sql_row_diagnostics,
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


def _ingest_local_sector_sql_files(
    builder: GraphBuilder,
    parser: ETLSqlParser,
    sector_codes: list,
    table_name_to_fp: dict[str, str] | None = None,
) -> dict:
    """
    从仓库 data/<SECTOR>/ 递归读取 .sql/.txt（电解铝/氧化铝/热电另含 .py），写入 builder。
    返回各板块成功打开并参与解析的文件数（与治理库 rows 计数语义接近）。
    若提供 table_name_to_fp，与治理库模式一致，把表名首次出现路径写入（供节点 filePath）。
    """
    counts: dict = {code: 0 for code in sector_codes}
    for code in sector_codes:
        root = SECTOR_DATA_DIRS.get(code)
        if not root or not os.path.isdir(root):
            continue
        local_exts = SQL_EXTENSIONS + ((".py",) if code in SECTOR_LOCAL_PY_SCRIPT_CODES else ())
        for dirpath, _, filenames in os.walk(root):
            for fn in filenames:
                low = fn.lower()
                if not any(low.endswith(ext) for ext in local_exts):
                    continue
                fp = os.path.join(dirpath, fn)
                try:
                    with open(fp, encoding="utf-8", errors="replace") as f:
                        content = f.read()
                except OSError as e:
                    logger.warning("读取本地 SQL 失败: %s error=%s", fp, e)
                    continue
                if not content.strip():
                    continue
                try:
                    table_list, relations, _ = parser.parse_content(content, fp)
                    if table_name_to_fp is not None:
                        for t in table_list:
                            tid = (t.get("name") or "").strip()
                            if tid and tid not in table_name_to_fp:
                                table_name_to_fp[tid] = fp
                        for r in relations:
                            for key in ("source_table", "target_table"):
                                tbl = (r.get(key) or "").strip()
                                if tbl and tbl not in table_name_to_fp:
                                    table_name_to_fp[tbl] = fp
                    builder.add_tables_from_parse(table_list)
                    builder.add_relations_from_parse(relations)
                    counts[code] = int(counts.get(code, 0)) + 1
                except Exception as e:
                    logger.warning("解析本地 SQL 失败: file=%s error=%s", fp, e)
    return counts


def build_graph_payload(sector: str, data_dir: str, use_cache: bool = True) -> dict:
    """构建图谱 JSON dict（nodes/links/meta）。默认仅使用治理库 ddd_code_detail.content；本地 data/ 回退见 GRAPH_LOCAL_SQL_FALLBACK。"""
    try:
        sector_codes = resolve_sector_codes(sector)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    codes_joined = ",".join(sector_codes)
    cache_key_db = f"DB|{codes_joined}"
    cache_key_local = f"LOCAL|{codes_joined}"
    now = time.time()
    if use_cache:
        with _GRAPH_CACHE_LOCK:
            item = _GRAPH_CACHE.get(cache_key_db)
            if item and (now - float(item.get("ts") or 0)) <= _GRAPH_CACHE_TTL_SEC:
                return item["payload"]

    parser = ETLSqlParser()
    builder = GraphBuilder()
    grouped = None
    db_err: Exception | None = None
    # 治理库模式：表名 -> 首次出现的脚本虚拟路径（供写回节点 filePath，避免混用 data/ 绝对路径）
    table_to_governance_fp: dict[str, str] = {}
    try:
        grouped = fetch_sql_records_grouped(sector)
    except ValueError as e:
        db_err = e
        if GRAPH_LOCAL_SQL_FALLBACK:
            logger.info("治理库不可用，尝试本地 SQL 回退: %s", e)
        else:
            logger.info("治理库不可用（未启用 GRAPH_LOCAL_SQL_FALLBACK，不使用 data/ SQL）: %s", e)
    except Exception as e:
        db_err = e
        if GRAPH_LOCAL_SQL_FALLBACK:
            logger.warning("治理库查询失败，尝试本地 SQL 回退: %s", e, exc_info=True)
        else:
            logger.warning("治理库查询失败（未启用本地 SQL 回退）: %s", e, exc_info=True)

    if grouped is not None:
        for code, records in grouped.items():
            for row in records:
                fp = f"governance_db://{code}/{row.get('sql_file_name', '')}"
                content = row.get("sql_content") or ""
                if not content.strip():
                    continue
                try:
                    table_list, relations, _ = parser.parse_content(content, fp)
                    for t in table_list:
                        tid = (t.get("name") or "").strip()
                        if tid and tid not in table_to_governance_fp:
                            table_to_governance_fp[tid] = fp
                    for r in relations:
                        for key in ("source_table", "target_table"):
                            tbl = (r.get(key) or "").strip()
                            if tbl and tbl not in table_to_governance_fp:
                                table_to_governance_fp[tbl] = fp
                    builder.add_tables_from_parse(table_list)
                    builder.add_relations_from_parse(relations)
                except Exception as e:
                    logger.warning("解析治理 SQL 失败: sector=%s file=%s error=%s", code, fp, e)
                    continue
        # 治理库能连上但该 project 下 0 条时，用仓库 data/<板块>/ 补充（与仅本地样例目录共存）
        need_local = [c for c in sector_codes if len((grouped or {}).get(c) or []) == 0]
        local_supplement: dict = {}
        if need_local:
            local_supplement = {
                c: n
                for c, n in _ingest_local_sector_sql_files(
                    builder, parser, need_local, table_to_governance_fp
                ).items()
                if n > 0
            }
        gov_meta = {
            "mode": "database+local_files" if local_supplement else "database",
            "sectors": {code: len(rows) for code, rows in grouped.items()},
        }
        if local_supplement:
            gov_meta["localFileSupplement"] = local_supplement
        cache_key = cache_key_db
    else:
        if not GRAPH_LOCAL_SQL_FALLBACK:
            with _GRAPH_CACHE_LOCK:
                _GRAPH_CACHE.pop(cache_key_local, None)
            if isinstance(db_err, ValueError):
                raise HTTPException(status_code=503, detail=str(db_err)) from db_err
            raise HTTPException(
                status_code=502,
                detail=(
                    f"治理平台数据库查询失败: {db_err}。"
                    "图谱仅使用库内 SQL 内容；离线调试可设置 GRAPH_LOCAL_SQL_FALLBACK=1 回退 data/ 目录。"
                ),
            ) from db_err
        if use_cache:
            with _GRAPH_CACHE_LOCK:
                item = _GRAPH_CACHE.get(cache_key_local)
                if item and (now - float(item.get("ts") or 0)) <= _GRAPH_CACHE_TTL_SEC:
                    return item["payload"]
        file_counts = _ingest_local_sector_sql_files(
            builder, parser, sector_codes, table_to_governance_fp
        )
        if sum(file_counts.values()) == 0:
            if isinstance(db_err, ValueError):
                raise HTTPException(status_code=503, detail=str(db_err)) from db_err
            raise HTTPException(
                status_code=502,
                detail=f"治理平台数据库查询失败: {db_err}；且未找到可回退的本地 SQL（请检查 data 目录或 DB 连接）",
            ) from db_err
        gov_meta = {
            "mode": "local_fallback",
            "sectors": file_counts,
            "dbError": str(db_err) if db_err else None,
        }
        cache_key = cache_key_local

    result = builder.to_vis_json()
    result_meta = result.setdefault("meta", {})
    result_meta["governanceSource"] = gov_meta

    # 仅在单板块且命中电解铝时，应用指标平台合并
    if len(sector_codes) == 1 and should_apply_metrics_merge_for_sector(sector_codes[0], data_dir, ""):
        result = merge_metrics_lineage_into_payload(result, METRICS_GOVERNANCE_MERGE_JSON)

    if table_to_governance_fp:
        for n in result.get("nodes") or []:
            if not isinstance(n, dict):
                continue
            tid = (n.get("id") or n.get("name") or "").strip()
            if tid in table_to_governance_fp:
                n["filePath"] = table_to_governance_fp[tid]

    if use_cache:
        with _GRAPH_CACHE_LOCK:
            _GRAPH_CACHE[cache_key] = {"ts": now, "payload": result}
            if cache_key == cache_key_db:
                _GRAPH_CACHE.pop(cache_key_local, None)
    return result


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
    """
    构建并返回图谱 JSON。前端为各板块传 `?sector=代码` 单板加载，例如
    `PRD_AL`（电解铝）、`PRD_AO`（氧化铝）、`PRD_RD`（热电）、`PUR`（采购）。
    `sector` 为空时治理库全板块合并（与首页独立请求单板的用法不同，慎用）。
    """
    result = build_graph_payload(sector, data_dir)
    return GraphResponse(**result)


@router.get("/governance/sector-diagnostics")
def get_governance_sector_diagnostics():
    """
    统计各板块在治理库中的行数与配置中 project_id 的对应情况。
    若某板块 `returnedToAppAfterContentStrip` 为 0，对照 `rowsAfterNameExcludesInSql` 与
    `rowsWithContentNotNull` 可判断是配错项目 id、无 content、还是被文件名关键词过滤光。
    """
    try:
        return sector_sql_row_diagnostics()
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"治理平台数据库查询失败: {e}") from e


@router.get("/governance/sql-content")
def get_governance_sql_content(sector: str = "", limit: int = 20):
    """
    查看治理平台 SQL 原文（按板块分组）。
    - sector 为空：返回全部 4 个板块
    - sector 可传：PRD_AL/PRD_AO/PRD_RD/PUR，或中文板块名
    """
    if limit < 1:
        limit = 1
    if limit > 200:
        limit = 200
    try:
        grouped = fetch_sql_records_grouped(sector)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"治理平台数据库查询失败: {e}") from e

    out = {}
    for code, rows in grouped.items():
        out[code] = {
            "total": len(rows),
            "items": rows[:limit],
        }
    return {
        "sector": sector,
        "limit": limit,
        "data": out,
    }


@router.post("/graph/build", response_model=GraphResponse)
def build_graph(req: BuildGraphRequest):
    """触发重建图谱（治理平台数据库模式）。"""
    result = build_graph_payload("", req.data_dir or "", use_cache=False)
    return GraphResponse(**result)


def _sector_code_from_request(sector: str, data_dir: str) -> str:
    s = (sector or "").strip()
    if s:
        try:
            return resolve_sector_codes(s)[0]
        except Exception:
            pass
    raw = (data_dir or "").replace("\\", "/")
    for code in ("PRD_AO", "PRD_AL", "PRD_RD", "PUR"):
        if code.lower() in raw.lower():
            return code
    return "PRD_AL"


@router.post("/agent/ask", response_model=AgentAskResponse)
def agent_ask(req: AgentAskRequest):
    """自然语言问答：仅通过模型结合图谱结构生成回答。"""
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
