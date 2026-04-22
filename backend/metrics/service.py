# -*- coding: utf-8 -*-
"""组合配置、HTTP 拉取与解析。"""
from __future__ import annotations

from typing import Tuple

from ..config import (
    METRICS_AUTH_TYPE,
    METRICS_AUTH_VALUE,
    METRICS_HTTP_TIMEOUT_SEC,
    METRICS_LINEAGE_QUERY_ALL_URL,
    METRICS_MATERIALIZED_HINTS,
    METRICS_TENANT_ID,
)
from .client import fetch_query_all_lineage
from .models import ParsedLineage
from .parser import parse_query_all_lineage


def materialized_hints_tuple() -> Tuple[str, ...]:
    raw = (METRICS_MATERIALIZED_HINTS or "").strip()
    if not raw:
        return ("aloudatacan",)
    return tuple(x.strip() for x in raw.split(",") if x.strip())


def fetch_parsed_lineage() -> ParsedLineage:
    """按当前环境变量拉取 queryAll 并解析为 ParsedLineage。"""
    raw = fetch_query_all_lineage(
        METRICS_LINEAGE_QUERY_ALL_URL,
        METRICS_TENANT_ID,
        METRICS_AUTH_TYPE,
        METRICS_AUTH_VALUE,
        timeout_sec=METRICS_HTTP_TIMEOUT_SEC,
    )
    return parse_query_all_lineage(raw, materialized_hints=materialized_hints_tuple())
