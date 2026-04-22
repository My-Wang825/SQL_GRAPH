# -*- coding: utf-8 -*-
"""表节点模型"""
from typing import List, Optional
from dataclasses import dataclass, field


@dataclass
class TableNode:
    """知识图谱中的表节点"""

    id: str
    name: str
    display_name: str = ""
    schema: str = ""
    comment: str = ""
    file_path: str = ""
    field_count: int = 0
    fields: List[dict] = field(default_factory=list)
    table_type: str = "core"  # core, dictionary, junction, temp, view
    relation_count: int = 0
    level: int = 0
    importance: float = 0.0
    tags: List[str] = field(default_factory=list)

    def __post_init__(self):
        if not self.display_name:
            self.display_name = self.name

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "displayName": self.display_name,
            "schema": self.schema,
            "comment": self.comment,
            "filePath": self.file_path,
            "fieldCount": self.field_count,
            "fields": self.fields,
            "tableType": self.table_type,
            "relationCount": self.relation_count,
            "level": self.level,
            "importance": self.importance,
            "tags": self.tags,
        }
