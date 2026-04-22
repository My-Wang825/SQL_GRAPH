# -*- coding: utf-8 -*-
"""HTTP 调用指标平台 queryAll 血缘接口。"""
from __future__ import annotations

import json
import logging
import ssl
import urllib.error
import urllib.request
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


class MetricsLineageClientError(Exception):
    """请求失败或响应非 JSON / HTTP 错误。"""


def fetch_query_all_lineage(
    url: str,
    tenant_id: str,
    auth_type: str,
    auth_value: str,
    timeout_sec: float = 120.0,
    cafile: Optional[str] = None,
) -> Dict[str, Any]:
    """
    GET queryAll，返回解析后的 dict（与平台 JSON 结构一致）。

    :param url: 完整 URL，例如 http://host:port/anymetrics/api/v1/lineage/queryAll
    :param cafile: HTTPS 时可选传入 CA 证书路径；不传则使用默认校验。
    """
    if not (url or "").strip():
        raise MetricsLineageClientError("METRICS_LINEAGE_QUERY_ALL_URL 未配置")
    if not (tenant_id or "").strip():
        raise MetricsLineageClientError("METRICS_TENANT_ID 未配置")

    req = urllib.request.Request(
        url.strip(),
        method="GET",
        headers={
            "tenant-id": tenant_id.strip(),
            "auth-type": (auth_type or "UID").strip(),
            "auth-value": (auth_value or "").strip(),
            "Accept": "application/json",
        },
    )

    ctx = None
    if url.strip().lower().startswith("https://"):
        ctx = ssl.create_default_context(cafile=cafile)

    try:
        with urllib.request.urlopen(req, timeout=timeout_sec, context=ctx) as resp:
            raw = resp.read()
            charset = resp.headers.get_content_charset() or "utf-8"
    except urllib.error.HTTPError as e:
        body = e.read().decode(e.headers.get_content_charset() or "utf-8", errors="replace")[:2000]
        logger.warning("指标血缘 HTTP 错误 status=%s body_prefix=%s", e.code, body[:500])
        raise MetricsLineageClientError(f"HTTP {e.code}: {body[:300]}") from e
    except urllib.error.URLError as e:
        logger.warning("指标血缘连接失败: %s", e)
        raise MetricsLineageClientError(f"连接失败: {e}") from e

    try:
        data = json.loads(raw.decode(charset))
    except json.JSONDecodeError as e:
        logger.warning("指标血缘响应非 JSON，前缀=%s", raw[:200])
        raise MetricsLineageClientError("响应不是合法 JSON") from e

    if not isinstance(data, dict):
        raise MetricsLineageClientError("响应 JSON 根节点必须是对象")

    return data
