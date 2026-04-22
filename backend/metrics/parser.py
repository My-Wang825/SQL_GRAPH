# -*- coding: utf-8 -*-
"""解析指标平台 queryAll 返回的 JSON。"""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from .models import LineageEdgeRecord, ParsedLineage, VertexRecord

# 物化/加速表：默认匹配 vertexId 中包含的子串（可用环境变量扩展，见 config）
_DEFAULT_MATERIALIZED_SUBSTRINGS = ("aloudatacan",)


def _physical_table_short_name(vertex_id: str) -> Optional[str]:
    if not vertex_id:
        return None
    parts = vertex_id.split(".")
    return parts[-1] if parts else None


def is_materialized_physical_table(vertex_id: str, hints: Tuple[str, ...]) -> bool:
    """判断 PHYSICAL_TABLE 是否归为「物化表」资产（启发式，可按 hints 调整）。"""
    low = vertex_id.lower()
    for h in hints:
        if h.strip() and h.strip().lower() in low:
            return True
    return False


def _normalize_vertex(raw: Dict[str, Any]) -> Optional[Tuple[str, str, str]]:
    if not raw:
        return None
    vid = (raw.get("vertexId") or raw.get("vertex_id") or "").strip()
    vtype = (raw.get("vertexType") or raw.get("vertex_type") or "").strip()
    if not vid or not vtype:
        return None
    tid = (raw.get("tenantId") or raw.get("tenant_id") or "").strip()
    return vid, vtype, tid


def parse_query_all_lineage(
    payload: Dict[str, Any],
    materialized_hints: Optional[Tuple[str, ...]] = None,
) -> ParsedLineage:
    """
    从 queryAll 完整响应体中解析。

    - ``datasets``：顶点类型为 DATASET（不含 DATASET_COLUMN）。
    - ``metrics``：顶点类型为 METRIC。
    - ``materialized_tables``：顶点类型为 PHYSICAL_TABLE 且 vertexId 匹配 materialized_hints。
    - ``edges``：原始 edgeList 全量保留（端点 tenant/type/id）。
    """
    hints = materialized_hints if materialized_hints is not None else _DEFAULT_MATERIALIZED_SUBSTRINGS

    out = ParsedLineage()
    out.upstream_success = bool(payload.get("success", True))
    out.upstream_code = payload.get("code")
    out.upstream_trace_id = payload.get("traceId") or payload.get("trace_id")
    err = payload.get("errorMsg") or payload.get("error_msg")
    detail = payload.get("detailErrorMsg") or payload.get("detail_error_msg")
    if err or detail:
        out.upstream_error = " | ".join(x for x in (err, detail) if x)

    data = payload.get("data") or {}
    edge_list = data.get("edgeList") or data.get("edge_list") or []
    if not isinstance(edge_list, list):
        edge_list = []

    vertices: Dict[Tuple[str, str], VertexRecord] = {}
    type_counts: Dict[str, int] = {}

    def note_vertex(vid: str, vtype: str, tid: str) -> None:
        key = (vid, vtype)
        if key not in vertices:
            short = _physical_table_short_name(vid) if vtype == "PHYSICAL_TABLE" else None
            vertices[key] = VertexRecord(
                vertex_id=vid,
                vertex_type=vtype,
                tenant_id=tid,
                physical_short_name=short,
            )
            type_counts[vtype] = type_counts.get(vtype, 0) + 1

    for edge in edge_list:
        if not isinstance(edge, dict):
            continue
        sv = edge.get("srcVertex") or edge.get("src_vertex") or {}
        dv = edge.get("dstVertex") or edge.get("dst_vertex") or {}
        ns = _normalize_vertex(sv)
        nd = _normalize_vertex(dv)
        if not ns or not nd:
            continue
        s_id, s_type, s_tid = ns
        t_id, t_type, t_tid = nd
        note_vertex(s_id, s_type, s_tid)
        note_vertex(t_id, t_type, t_tid)
        et = edge.get("edgeType") or edge.get("edge_type")
        out.edges.append(
            LineageEdgeRecord(
                source_vertex_id=s_id,
                source_vertex_type=s_type,
                target_vertex_id=t_id,
                target_vertex_type=t_type,
                source_tenant_id=s_tid,
                target_tenant_id=t_tid,
                edge_type=et if et else None,
            )
        )

    out.vertex_type_counts = dict(sorted(type_counts.items(), key=lambda x: -x[1]))

    for v in vertices.values():
        if v.vertex_type == "DATASET":
            out.datasets.append(v)
        elif v.vertex_type == "METRIC":
            out.metrics.append(v)
        elif v.vertex_type == "PHYSICAL_TABLE" and is_materialized_physical_table(v.vertex_id, hints):
            out.materialized_tables.append(v)

    def sort_key(rec: VertexRecord) -> str:
        return rec.vertex_id.lower()

    out.datasets.sort(key=sort_key)
    out.metrics.sort(key=sort_key)
    out.materialized_tables.sort(key=sort_key)
    return out
