# -*- coding: utf-8 -*-
"""图谱构建器：将解析出的表与关系构建为前端可用的图谱 JSON"""
from typing import List, Dict, Any
from collections import defaultdict
from ..models import TableNode, RelationEdge


class GraphBuilder:
    def __init__(self):
        self.tables: Dict[str, TableNode] = {}
        # 累积原始关系 dict（去重前，含 file_path）
        self._raw_relations: List[dict] = []

    def add_tables_from_parse(self, table_list: List[dict]) -> None:
        for t in table_list:
            name = t.get("name", "").strip()
            if not name:
                continue
            tid = name
            if tid not in self.tables:
                self.tables[tid] = TableNode(
                    id=tid,
                    name=name,
                    display_name=t.get("comment") or name,
                    comment=t.get("comment", ""),
                    file_path=t.get("file_path", ""),
                    table_type=_infer_table_type(name),
                )
            else:
                if t.get("comment"):
                    self.tables[tid].comment = t["comment"]
                if t.get("file_path") and not self.tables[tid].file_path:
                    self.tables[tid].file_path = t["file_path"]

    def add_relations_from_parse(self, relation_list: List[dict]) -> None:
        # 暂存原始关系，最后统一去重/聚合/标记
        self._raw_relations.extend(relation_list)
        # 同时在 GraphBuilder 这层补齐涉及的表节点（延迟到 to_vis_json 再处理）
        for r in relation_list:
            for tbl in (r.get("source_table", ""), r.get("target_table", "")):
                if tbl and tbl not in self.tables:
                    self.tables[tbl] = TableNode(
                        id=tbl,
                        name=tbl,
                        display_name=tbl,
                        table_type=_infer_table_type(tbl),
                    )

    def to_vis_json(self) -> Dict[str, Any]:
        # ---- 1. 全局去重 + 聚合 ----
        key_map: Dict[tuple, dict] = {}
        for r in self._raw_relations:
            src = r.get("source_table", "")
            tgt = r.get("target_table", "")
            if not src or not tgt or src == tgt:
                continue
            key = (src, tgt)
            fp = r.get("file_path", "")
            if key not in key_map:
                key_map[key] = {
                    "source": src,
                    "target": tgt,
                    "source_column": r.get("source_column", ""),
                    "target_column": r.get("target_column", ""),
                    "relation_type": r.get("relation_type", "DATA_FLOW"),
                    "weight": 1,
                    "strength": r.get("strength", 50),
                    "confidence": r.get("confidence", 0.8),
                    "reason": r.get("reason", ""),
                    "sources": [fp] if fp else [],
                }
            else:
                e = key_map[key]
                e["weight"] += 1
                e["strength"] = max(e["strength"], r.get("strength", 50))
                e["confidence"] = (e["confidence"] + r.get("confidence", 0.8)) / 2.0
                if fp and fp not in e["sources"]:
                    e["sources"].append(fp)

        merged: List[dict] = list(key_map.values())

        # ---- 2. 转换为 RelationEdge 并计算节点关联数 ----
        edges: List[RelationEdge] = []
        rel_count: Dict[str, int] = defaultdict(int)
        for r in merged:
            edge = RelationEdge(
                source=r["source"],
                target=r["target"],
                relation_type=r.get("relation_type", "DATA_FLOW"),
                source_column=r.get("source_column", ""),
                target_column=r.get("target_column", ""),
                confidence=r.get("confidence", 0.8),
                strength=int(r.get("strength", 60)),
                reason=r.get("reason", ""),
                weight=r.get("weight", 1),
                sources=r.get("sources", []),
                is_transitive=False,
            )
            edges.append(edge)
            rel_count[r["source"]] += 1
            rel_count[r["target"]] += 1

        for n in self.tables.values():
            n.relation_count = rel_count.get(n.id, 0)

        # ---- 3. 输出 ----
        nodes_out = [n.to_dict() for n in self.tables.values()]
        links_out = []
        for e in edges:
            links_out.append({
                "source": e.source,
                "target": e.target,
                "relationType": e.relation_type,
                "sourceColumn": e.source_column,
                "targetColumn": e.target_column,
                "strength": e.strength,
                "confidence": e.confidence,
                "reason": e.reason,
                "weight": e.weight,
                "sources": e.sources,
                "isTransitive": False,
            })

        return {
            "nodes": nodes_out,
            "links": links_out,
            "meta": {
                "version": "1.0",
                "tableCount": len(nodes_out),
                "relationCount": len(links_out),
            },
        }


def _infer_table_type(name: str) -> str:
    name_lower = name.lower()
    if name_lower.startswith("v_"):
        return "view"
    if name_lower.startswith("dim_") or "dim_" in name_lower:
        return "dictionary"
    if name_lower.startswith("ods_"):
        return "core"
    if name_lower.startswith("dwd_") or name_lower.startswith("dws_"):
        return "core"
    if name_lower.startswith("ads_"):
        return "junction"
    if "temp" in name_lower or "_tmp" in name_lower or "_temp" in name_lower:
        return "temp"
    return "core"
