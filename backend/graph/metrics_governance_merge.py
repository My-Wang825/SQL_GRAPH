# -*- coding: utf-8 -*-
"""
将 lineage_for_governance_merge.json 中的 PHYSICAL_TABLE → DATASET 边并入图谱：
仅当 PHYSICAL_TABLE 的 vertexId 能与治理侧已有表节点 id 匹配时处理。

- 若治理表 id 与 DATASET 的 vertexId 同名（忽略大小写）：仅在表节点上标注
  metricsSameAsDataset，不创建数据集节点、不增加 METRICS_DATASET 边。
- 否则：添加「治理表 → 指标数据集节点」边（与此前逻辑一致）。
未匹配的物理表边不展示。
"""
from __future__ import annotations

import json
import logging
import os
from collections import defaultdict
from typing import Any, Dict, List, Optional, Set, Tuple

logger = logging.getLogger(__name__)

DATASET_NODE_PREFIX = "__metric_ds__:"
RELATION_TYPE = "METRICS_DATASET"


def _physical_match_candidates(vertex_id: str) -> List[str]:
    """从平台 PHYSICAL_TABLE vertexId 得到可与治理表名比对的候选串。"""
    vid = (vertex_id or "").strip()
    if not vid:
        return []
    last = vid.rsplit(".", 1)[-1].strip()
    out: List[str] = []
    for c in (last, vid):
        if c and c not in out:
            out.append(c)
    return out


def _index_graph_table_ids(nodes: List[dict]) -> Dict[str, str]:
    """小写表名 -> 图中实际 id（治理侧主键）。"""
    m: Dict[str, str] = {}
    for n in nodes:
        if not isinstance(n, dict):
            continue
        nid = (n.get("id") or n.get("name") or "").strip()
        if not nid or nid.startswith(DATASET_NODE_PREFIX):
            continue
        m[nid.lower()] = nid
    return m


def _resolve_table_id(candidates: List[str], by_lower: Dict[str, str]) -> Optional[str]:
    for c in candidates:
        if not c:
            continue
        hit = by_lower.get(c.lower())
        if hit:
            return hit
    return None


def _dataset_node_id(dataset_vertex_id: str) -> str:
    return f"{DATASET_NODE_PREFIX}{dataset_vertex_id.strip()}"


def _names_same_for_metrics(gov_table_id: str, dataset_vertex_id: str) -> bool:
    """数据源表（治理节点 id）与指标平台 DATASET vertexId 是否视为同一名称。"""
    a = (gov_table_id or "").strip().lower()
    b = (dataset_vertex_id or "").strip().lower()
    return bool(a) and a == b


def _annotate_table_same_as_dataset(
    node: dict,
    dataset_vertex_id: str,
    physical_vertex_id: str,
) -> None:
    """在数据流表节点上标注：物理源与目标数据集同名，不增加冗余边。"""
    node["metricsSameAsDataset"] = True
    node["metricsDatasetVertexId"] = dataset_vertex_id
    node["metricsPhysicalVertexId"] = physical_vertex_id
    tags = node.get("tags")
    if not isinstance(tags, list):
        tags = []
    t = "metrics_same_as_dataset"
    if t not in tags:
        tags.append(t)
    node["tags"] = tags


def merge_metrics_lineage_into_payload(
    vis_json: Dict[str, Any],
    merge_json_path: str,
) -> Dict[str, Any]:
    """
    在 vis_json 副本上合并指标侧 PHYSICAL_TABLE→DATASET（仅匹配治理表成功时）。

    :param merge_json_path: lineage_for_governance_merge.json 绝对或相对路径
    """
    out = {
        "nodes": list(vis_json.get("nodes") or []),
        "links": list(vis_json.get("links") or []),
        "meta": dict(vis_json.get("meta") or {}),
    }
    path = (merge_json_path or "").strip()
    if not path:
        return out
    if not os.path.isfile(path):
        logger.info("指标合并 JSON 不存在，跳过: %s", path)
        return out

    try:
        with open(path, "r", encoding="utf-8") as f:
            payload = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        logger.warning("读取指标合并 JSON 失败: %s error=%s", path, e)
        return out

    data = payload.get("data") or {}
    edge_list = data.get("edgeList") or []
    if not isinstance(edge_list, list):
        return out

    by_lower = _index_graph_table_ids(out["nodes"])
    existing_link_keys: Set[Tuple[str, str, str]] = set()
    for lk in out["links"]:
        if not isinstance(lk, dict):
            continue
        s, t = lk.get("source"), lk.get("target")
        rt = lk.get("relationType") or "DATA_FLOW"
        if s and t:
            existing_link_keys.add((str(s), str(t), str(rt)))

    nodes_by_id: Dict[str, dict] = {n["id"]: n for n in out["nodes"] if isinstance(n, dict) and n.get("id")}

    added_edges = 0
    skipped_no_match = 0
    same_name_annotated = 0
    dataset_ids_added: Set[str] = set()
    same_name_nodes: Set[str] = set()

    for edge in edge_list:
        if not isinstance(edge, dict):
            continue
        sv = edge.get("srcVertex") or edge.get("src_vertex") or {}
        dv = edge.get("dstVertex") or edge.get("dst_vertex") or {}
        if not isinstance(sv, dict) or not isinstance(dv, dict):
            continue
        st = (sv.get("vertexType") or "").strip()
        dt = (dv.get("vertexType") or "").strip()
        if st != "PHYSICAL_TABLE" or dt != "DATASET":
            continue
        phy_id = (sv.get("vertexId") or "").strip()
        ds_id = (dv.get("vertexId") or "").strip()
        if not phy_id or not ds_id:
            continue

        gov_table_id = _resolve_table_id(_physical_match_candidates(phy_id), by_lower)
        if not gov_table_id:
            skipped_no_match += 1
            continue

        # 表名与数据集 vertexId 一致：仅标注当前表节点，不创建数据集节点、不增加 METRICS_DATASET 边
        if _names_same_for_metrics(gov_table_id, ds_id):
            tbl = nodes_by_id.get(gov_table_id)
            if isinstance(tbl, dict):
                if gov_table_id not in same_name_nodes:
                    _annotate_table_same_as_dataset(tbl, ds_id, phy_id)
                    same_name_nodes.add(gov_table_id)
                    same_name_annotated += 1
            continue

        target_nid = _dataset_node_id(ds_id)
        lk = (gov_table_id, target_nid, RELATION_TYPE)
        if lk in existing_link_keys:
            continue
        existing_link_keys.add(lk)

        if target_nid not in nodes_by_id:
            nodes_by_id[target_nid] = {
                "id": target_nid,
                "name": ds_id,
                "displayName": f"指标数据集 · {ds_id}",
                "schema": "",
                "comment": "指标平台 DATASET，经 PHYSICAL_TABLE 与数仓表对齐后展示",
                "filePath": "",
                "fieldCount": 0,
                "fields": [],
                "tableType": "metrics_dataset",
                "relationCount": 0,
                "level": 0,
                "importance": 0.0,
                "tags": ["metrics_platform", "DATASET"],
            }
            out["nodes"].append(nodes_by_id[target_nid])
            dataset_ids_added.add(target_nid)

        reason = f"指标血缘: {phy_id} → {ds_id}（已对齐治理表 {gov_table_id}）"
        out["links"].append(
            {
                "source": gov_table_id,
                "target": target_nid,
                "relationType": RELATION_TYPE,
                "sourceColumn": "",
                "targetColumn": "",
                "strength": 55,
                "confidence": 0.95,
                "reason": reason,
                "weight": 1,
                "sources": [os.path.basename(path)],
                "isTransitive": False,
            }
        )
        added_edges += 1

    # 重算 relationCount
    rel_count: Dict[str, int] = defaultdict(int)
    for lk in out["links"]:
        if not isinstance(lk, dict):
            continue
        s, t = lk.get("source"), lk.get("target")
        if s:
            rel_count[str(s)] += 1
        if t:
            rel_count[str(t)] += 1
    for n in out["nodes"]:
        if isinstance(n, dict) and n.get("id"):
            n["relationCount"] = rel_count.get(n["id"], 0)

    meta = out["meta"]
    meta["metricsMerge"] = {
        "mergeJsonPath": path,
        "edgesAdded": added_edges,
        "datasetNodesAdded": len(dataset_ids_added),
        "physicalTableEdgesSkippedNoMatch": skipped_no_match,
        "nodesAnnotatedSameAsDataset": same_name_annotated,
    }
    meta["tableCount"] = len(out["nodes"])
    meta["relationCount"] = len(out["links"])
    return out


def should_apply_metrics_merge_for_sector(sector: str, data_dir: str, resolved_data_dir: str) -> bool:
    """仅电解铝 PRD_AL 默认数据目录启用指标合并；氧化铝 PRD_AO 不合并。"""
    key = (sector or "").strip().upper().replace("-", "_")
    if key == "PRD_AO":
        return False
    if key == "PRD_AL":
        return True
    if key:
        return False
    if (data_dir or "").strip():
        norm = resolved_data_dir.replace("\\", "/").upper()
        return "PRD_AL" in norm
    return True
