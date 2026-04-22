# -*- coding: utf-8 -*-
"""字段节点模型"""
from dataclasses import dataclass
from typing import Optional


@dataclass
class FieldNode:
    """知识图谱中的字段节点"""

    id: str
    name: str
    table_id: str
    display_name: str = ""
    data_type: str = ""
    raw_type: str = ""
    is_nullable: bool = True
    is_primary_key: bool = False
    is_foreign_key: bool = False
    default_value: Optional[str] = None
    comment: str = ""
    ordinal_position: int = 0

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "tableId": self.table_id,
            "displayName": self.display_name or self.name,
            "dataType": self.data_type,
            "rawType": self.raw_type,
            "isNullable": self.is_nullable,
            "isPrimaryKey": self.is_primary_key,
            "isForeignKey": self.is_foreign_key,
            "defaultValue": self.default_value,
            "comment": self.comment,
            "ordinalPosition": self.ordinal_position,
        }
