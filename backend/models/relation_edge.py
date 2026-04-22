# -*- coding: utf-8 -*-
"""关系边模型"""
from dataclasses import dataclass, field
from typing import List


@dataclass
class RelationEdge:
    """知识图谱中的关系边"""

    source: str  # 源表 id
    target: str  # 目标表 id
    relation_type: str = "DATA_FLOW"  # FOREIGN_KEY, CONTAINS, SIMILAR, DATA_FLOW
    source_column: str = ""
    target_column: str = ""
    constraint_name: str = ""
    on_update: str = ""
    on_delete: str = ""
    confidence: float = 1.0
    strength: int = 100
    reason: str = ""
    # 聚合属性
    weight: int = 1           # 该 (src,tgt) 出现的次数
    sources: List[str] = field(default_factory=list)  # 来源文件列表
    # 可推理标记
    is_transitive: bool = False

    def to_dict(self) -> dict:
        return {
            "source": self.source,
            "target": self.target,
            "relationType": self.relation_type,
            "sourceColumn": self.source_column,
            "targetColumn": self.target_column,
            "constraintName": self.constraint_name,
            "onUpdate": self.on_update,
            "onDelete": self.on_delete,
            "confidence": self.confidence,
            "strength": self.strength,
            "reason": self.reason,
            "weight": self.weight,
            "sources": self.sources,
            "isTransitive": self.is_transitive,
        }
