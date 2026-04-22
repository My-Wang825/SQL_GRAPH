# -*- coding: utf-8 -*-
"""关系分析器：合并多文件关系、去重、聚合 weight/sources/可推理标记"""
from typing import List, Dict, Set


class RelationAnalyzer:
    def __init__(self):
        self.relations: List[dict] = []

    def add_relations(self, relations: List[dict]) -> None:
        self.relations.extend(relations)

    def merge_and_deduplicate(self) -> List[dict]:
        """
        合并相同 (source, target) 的关系，聚合：
        - weight：出现次数
        - sources：来源文件路径列表（去重）
        - max_strength / avg_confidence
        同时标记可推理边（A->B,B->C则A->C）
        """
        # 第一步：去重聚合
        key_to_rel: Dict[tuple, dict] = {}
        for r in self.relations:
            src = r.get("source_table", "")
            tgt = r.get("target_table", "")
            if not src or not tgt or src == tgt:
                continue
            # 保留原始方向（A->B），不合并双向
            key = (src, tgt)
            fp = r.get("file_path", "")
            if key not in key_to_rel:
                key_to_rel[key] = {
                    "source_table": src,
                    "target_table": tgt,
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
                entry = key_to_rel[key]
                entry["weight"] += 1
                entry["strength"] = max(entry["strength"], r.get("strength", 50))
                entry["confidence"] = (entry["confidence"] + r.get("confidence", 0.8)) / 2.0
                if fp and fp not in entry["sources"]:
                    entry["sources"].append(fp)

        result: List[dict] = list(key_to_rel.values())

        # 第二步：计算可推理边（传递闭包）并标记
        nodes: List[str] = list({r["source_table"] for r in result}.union(
            {r["target_table"] for r in result}))
        # 构建邻接表（有向）
        adj: Dict[str, Set[str]] = {n: set() for n in nodes}
        for r in result:
            adj[r["source_table"]].add(r["target_table"])

        # 找所有传递路径 A->B->C（A!=C），则 A->C 标记为可推理
        transitive: Set[tuple] = set()
        for a in nodes:
            bfs_queue = list(adj.get(a, set()))
            visited: Set[str] = set(bfs_queue)
            while bfs_queue:
                b = bfs_queue.pop(0)
                for c in adj.get(b, set()):
                    if c == a:
                        continue
                    if c not in visited:
                        visited.add(c)
                        bfs_queue.append(c)
                        # A->C 可通过 A->...->C 推理
                        transitive.add((a, c))

        # 标记
        for r in result:
            k = (r["source_table"], r["target_table"])
            r["is_transitive"] = k in transitive
            # 可推理边默认弱化 strength
            if r["is_transitive"]:
                r["strength"] = max(10, int(r["strength"] * 0.5))

        return result
