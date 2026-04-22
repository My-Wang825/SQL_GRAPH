# -*- coding: utf-8 -*-
from typing import List, Optional, Dict
from pydantic import BaseModel, Field


class GraphResponse(BaseModel):
    nodes: List[dict]
    links: List[dict]
    meta: dict


class BuildGraphRequest(BaseModel):
    data_dir: Optional[str] = None  # 不传则用 config.DATA_DIR


class AgentAskRequest(BaseModel):
    question: str = Field(..., min_length=1, description="自然语言问题")
    sector: Optional[str] = ""
    data_dir: Optional[str] = ""


class AgentHighlight(BaseModel):
    node_ids: List[str] = []
    links: List[Dict[str, str]] = []


class AgentAskResponse(BaseModel):
    answer: str
    intent: str
    intent_label: str
    confidence: float = 0.0
    highlight: AgentHighlight
    matches: List[dict] = []


class MetricsLineageSummaryResponse(BaseModel):
    """GET /api/metrics/lineage/summary：指标 queryAll 解析摘要（不含全量边）。"""

    upstreamSuccess: bool = True
    upstreamCode: Optional[str] = None
    upstreamTraceId: Optional[str] = None
    upstreamError: Optional[str] = None
    counts: dict = Field(default_factory=dict)
    samples: dict = Field(default_factory=dict)
