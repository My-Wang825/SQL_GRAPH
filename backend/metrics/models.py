# -*- coding: utf-8 -*-
"""指标平台血缘：解析后的结构化模型（供后续与 SQL 图谱融合）。"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional


@dataclass(frozen=True)
class VertexRecord:
    """从 queryAll 的边端点聚合出的顶点。"""

    vertex_id: str
    vertex_type: str
    tenant_id: str = ""
    physical_short_name: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        d: Dict[str, Any] = {
            "vertexId": self.vertex_id,
            "vertexType": self.vertex_type,
            "tenantId": self.tenant_id or None,
        }
        if self.physical_short_name:
            d["physicalShortName"] = self.physical_short_name
        return d


@dataclass
class LineageEdgeRecord:
    """单条有向边（保留平台原始结构，便于融合时映射）。"""

    source_vertex_id: str
    source_vertex_type: str
    target_vertex_id: str
    target_vertex_type: str
    source_tenant_id: str = ""
    target_tenant_id: str = ""
    edge_type: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "sourceVertexId": self.source_vertex_id,
            "sourceVertexType": self.source_vertex_type,
            "targetVertexId": self.target_vertex_id,
            "targetVertexType": self.target_vertex_type,
            "sourceTenantId": self.source_tenant_id or None,
            "targetTenantId": self.target_tenant_id or None,
            "edgeType": self.edge_type,
        }


@dataclass
class ParsedLineage:
    """parse_query_all_lineage 的输出。"""

    datasets: List[VertexRecord] = field(default_factory=list)
    metrics: List[VertexRecord] = field(default_factory=list)
    materialized_tables: List[VertexRecord] = field(default_factory=list)
    edges: List[LineageEdgeRecord] = field(default_factory=list)
    upstream_success: bool = True
    upstream_code: Optional[str] = None
    upstream_trace_id: Optional[str] = None
    upstream_error: Optional[str] = None
    vertex_type_counts: Dict[str, int] = field(default_factory=dict)

    def to_summary_dict(self, sample_limit: int = 20) -> Dict[str, Any]:
        def sample(records: List[VertexRecord]) -> List[Dict[str, Any]]:
            return [r.to_dict() for r in records[:sample_limit]]

        return {
            "upstreamSuccess": self.upstream_success,
            "upstreamCode": self.upstream_code,
            "upstreamTraceId": self.upstream_trace_id,
            "upstreamError": self.upstream_error,
            "counts": {
                "datasets": len(self.datasets),
                "metrics": len(self.metrics),
                "materializedTables": len(self.materialized_tables),
                "edges": len(self.edges),
                "vertexTypes": dict(self.vertex_type_counts),
            },
            "samples": {
                "datasets": sample(self.datasets),
                "metrics": sample(self.metrics),
                "materializedTables": sample(self.materialized_tables),
            },
        }
