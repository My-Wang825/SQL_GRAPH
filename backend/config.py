# -*- coding: utf-8 -*-
"""配置文件"""
import os

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - 缺依赖时仍允许项目启动
    load_dotenv = None

# 项目根目录
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 优先加载本地 .env，其次回退到已配置好的 .env.example
# 文件中的配置应覆盖历史 shell 环境变量，避免改了配置文件却仍读到旧值。
if load_dotenv is not None:
    env_path = os.path.join(BASE_DIR, ".env")
    example_env_path = os.path.join(BASE_DIR, ".env.example")
    if os.path.isfile(env_path):
        load_dotenv(env_path, override=True, encoding="utf-8")
    elif os.path.isfile(example_env_path):
        load_dotenv(example_env_path, override=True, encoding="utf-8")

# 默认 SQL 数据目录（全量 data，一般不再作为默认图谱入口）
DATA_DIR = os.path.join(BASE_DIR, "data")

# 业务板块子目录（供 /api/graph?sector= 独立加载，避免多板块混在一个图里）
SECTOR_DATA_DIRS = {
    "PRD_AL": os.path.join(BASE_DIR, "data", "PRD_AL"),
    "PRD_AO": os.path.join(BASE_DIR, "data", "PRD_AO"),
}

# 支持的 SQL 文件扩展名
SQL_EXTENSIONS = (".sql", ".txt")

# 解析器配置
PARSER_CONFIG = {
    "default_schema": "sdhq",
    "normalize_table_name": True,  # 统一使用短表名（去掉 schema）
}

# 图谱元数据
GRAPH_VERSION = "1.0"

def _pick_env(*keys: str, default: str = "") -> str:
    for key in keys:
        value = os.environ.get(key, "")
        if value and str(value).strip():
            return str(value).strip()
    return default


# 模型配置（OpenAI 兼容）：同时兼容 OPENAI_* 与 MINIMAX_* 命名。
# 为避免历史 MINIMAX_* 残留覆盖当前配置，优先使用 OPENAI_*。
MINIMAX_API_KEY = _pick_env("OPENAI_API_KEY", "MINIMAX_API_KEY")
MINIMAX_BASE_URL = _pick_env(
    "OPENAI_BASE_URL",
    "MINIMAX_BASE_URL",
    default="https://api.minimax.io/v1",
)
MINIMAX_MODEL = _pick_env("OPENAI_MODEL", "MINIMAX_MODEL", default="MiniMax-M2.7")

# 指标平台血缘 queryAll（与数仓 SQL 图谱融合的前置拉取；密钥勿提交仓库）
METRICS_LINEAGE_QUERY_ALL_URL = os.environ.get("METRICS_LINEAGE_QUERY_ALL_URL", "").strip()
METRICS_TENANT_ID = os.environ.get("METRICS_TENANT_ID", "").strip()
METRICS_AUTH_TYPE = os.environ.get("METRICS_AUTH_TYPE", "UID").strip()
METRICS_AUTH_VALUE = os.environ.get("METRICS_AUTH_VALUE", "").strip()
METRICS_HTTP_TIMEOUT_SEC = float(os.environ.get("METRICS_HTTP_TIMEOUT_SEC", "120") or "120")
# 逗号分隔：PHYSICAL_TABLE 的 vertexId 包含任一子串则归为「物化表」
METRICS_MATERIALIZED_HINTS = os.environ.get("METRICS_MATERIALIZED_HINTS", "aloudatacan").strip()

# 电解铝图谱合并：lineage_for_governance_merge.json（PHYSICAL_TABLE→DATASET 与治理表对齐后入图）
_METRICS_MERGE_DEFAULT = os.path.join(
    BASE_DIR, "exports", "metrics_lineage_test", "lineage_for_governance_merge.json"
)
_mgj = os.environ.get("METRICS_GOVERNANCE_MERGE_JSON", "").strip()
if _mgj:
    METRICS_GOVERNANCE_MERGE_JSON = (
        _mgj if os.path.isabs(_mgj) else os.path.join(BASE_DIR, os.path.normpath(_mgj))
    )
else:
    METRICS_GOVERNANCE_MERGE_JSON = _METRICS_MERGE_DEFAULT
