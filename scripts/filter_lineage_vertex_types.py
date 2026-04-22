# -*- coding: utf-8 -*-
"""
从 queryAll 原始 JSON 中仅保留 PHYSICAL_TABLE、DATASET、ANALYSIS_VIEW 相关边与顶点，
生成用于与治理平台资产在知识图谱中打通的精简 JSON。

规则：
- 只保留两端 vertexType 均在允许集合内的 edgeList 边；
- edgeList 内完全相同的边去重；
- vertexList 中按 vertexId 去重（同一 vertexId 若曾出现不同 vertexType，保留首次并写入 meta.vertexId_type_collisions）。

用法::

    python scripts/filter_lineage_vertex_types.py \\
        --in exports/metrics_lineage_test/lineage_queryAll_raw.json \\
        --out exports/metrics_lineage_test/lineage_for_governance_merge.json
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

ALLOWED_TYPES = frozenset({"PHYSICAL_TABLE", "DATASET", "ANALYSIS_VIEW"})


def _norm_vertex(raw: Any) -> Optional[Dict[str, str]]:
    if not isinstance(raw, dict):
        return None
    vid = (raw.get("vertexId") or raw.get("vertex_id") or "").strip()
    vtype = (raw.get("vertexType") or raw.get("vertex_type") or "").strip()
    tid = (raw.get("tenantId") or raw.get("tenant_id") or "").strip()
    if not vid or not vtype:
        return None
    return {"tenantId": tid, "vertexId": vid, "vertexType": vtype}


def filter_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    data = payload.get("data") or {}
    edge_list = data.get("edgeList") or data.get("edge_list") or []
    if not isinstance(edge_list, list):
        edge_list = []

    filtered_edges: List[Dict[str, Any]] = []
    seen_edge: Set[Tuple[str, str, str, str, str]] = set()
    vertices_by_id: Dict[str, Dict[str, str]] = {}
    collisions: List[Dict[str, str]] = []

    for edge in edge_list:
        if not isinstance(edge, dict):
            continue
        sv = _norm_vertex(edge.get("srcVertex") or edge.get("src_vertex"))
        dv = _norm_vertex(edge.get("dstVertex") or edge.get("dst_vertex"))
        if not sv or not dv:
            continue
        if sv["vertexType"] not in ALLOWED_TYPES or dv["vertexType"] not in ALLOWED_TYPES:
            continue

        et = edge.get("edgeType") or edge.get("edge_type") or ""
        et = et if isinstance(et, str) else str(et)
        ek = (sv["vertexId"], sv["vertexType"], dv["vertexId"], dv["vertexType"], et)
        if ek in seen_edge:
            continue
        seen_edge.add(ek)

        out_edge: Dict[str, Any] = {
            "srcVertex": dict(sv),
            "dstVertex": dict(dv),
        }
        if et:
            out_edge["edgeType"] = et
        filtered_edges.append(out_edge)

        for v in (sv, dv):
            vid = v["vertexId"]
            if vid not in vertices_by_id:
                vertices_by_id[vid] = dict(v)
            else:
                ex = vertices_by_id[vid]
                if ex.get("vertexType") != v.get("vertexType"):
                    collisions.append(
                        {
                            "vertexId": vid,
                            "kept_vertexType": ex.get("vertexType", ""),
                            "skipped_vertexType": v.get("vertexType", ""),
                        }
                    )

    vertex_list = sorted(vertices_by_id.values(), key=lambda x: (x["vertexType"], x["vertexId"].lower()))

    out: Dict[str, Any] = {
        "success": bool(payload.get("success", True)),
        "code": payload.get("code"),
        "errorMsg": payload.get("errorMsg"),
        "detailErrorMsg": payload.get("detailErrorMsg"),
        "traceId": payload.get("traceId"),
        "data": {
            "vertexList": vertex_list,
            "edgeList": filtered_edges,
        },
        "meta": {
            "description": "仅保留 PHYSICAL_TABLE、DATASET、ANALYSIS_VIEW，用于与治理平台表级资产在知识图谱中打通。",
            "allowed_vertex_types": sorted(ALLOWED_TYPES),
            "vertex_count_unique_by_vertexId": len(vertex_list),
            "edge_count_after_filter": len(filtered_edges),
            "edge_count_before_filter": len(edge_list),
            "vertexId_type_collisions": collisions,
        },
    }
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="in_path", required=True, help="原始 lineage_queryAll JSON 路径")
    ap.add_argument("--out", dest="out_path", required=True, help="输出 JSON 路径")
    args = ap.parse_args()
    in_path = Path(args.in_path)
    out_path = Path(args.out_path)
    if not in_path.is_file():
        raise SystemExit(f"输入文件不存在: {in_path}")

    with open(in_path, "r", encoding="utf-8") as f:
        payload = json.load(f)
    if not isinstance(payload, dict):
        raise SystemExit("根节点必须是 JSON 对象")

    out = filter_payload(payload)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    meta = out.get("meta") or {}
    print(f"已写入: {out_path}")
    print(
        f"边: 过滤前 {meta.get('edge_count_before_filter')} -> "
        f"过滤后 {meta.get('edge_count_after_filter')}；"
        f"顶点(vertexId 去重): {meta.get('vertex_count_unique_by_vertexId')}"
    )
    cc = meta.get("vertexId_type_collisions") or []
    if cc:
        print(f"警告: vertexId 类型冲突 {len(cc)} 条（详见输出 JSON 的 meta.vertexId_type_collisions）")


if __name__ == "__main__":
    main()
