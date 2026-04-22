# -*- coding: utf-8 -*-
"""治理平台 SQL 数据源：从 datablau DB 拉取 SQL 脚本内容。"""
from __future__ import annotations

from typing import Callable, Dict, List, Optional, TypeVar
from urllib.parse import quote_plus

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import OperationalError

from .config import DB_HOST, DB_NAME, DB_PASSWORD, DB_PORT, DB_USER, GOVERNANCE_SECTOR_RULES


_ENGINE: Optional[Engine] = None

# MySQL 常见断连码：2013=查询中丢失连接，2006/2014=服务端已断开等，适合整池淘汰后重试
_TRANSIENT_MYSQL_CODES = frozenset({2006, 2013, 2014})


def _is_transient_mysql_read_error(exc: BaseException) -> bool:
    o = getattr(exc, "orig", exc)
    if o is not None and getattr(o, "args", None) and o.args[0] in _TRANSIENT_MYSQL_CODES:
        return True
    s = str(o or exc).lower()
    return "lost connection" in s or "gone away" in s or "2013" in s


T = TypeVar("T")


def _governance_read(fn: Callable[[], T], *, retries: int = 1) -> T:
    """只读操作：遇连接中途被服务端/网络踢掉时，清连接池后重试一次。"""
    global _ENGINE  # noqa: PLW0603 单例
    last: BaseException | None = None
    for attempt in range(1 + retries):
        try:
            return fn()
        except OperationalError as e:
            last = e
            if attempt < retries and _is_transient_mysql_read_error(e):
                if _ENGINE is not None:
                    _ENGINE.dispose()
                _ENGINE = None
                continue
            raise
    if last is not None:
        raise last
    raise RuntimeError("unreachable")  # pragma: no cover


def _build_engine() -> Engine:
    if not (DB_HOST and DB_USER and DB_NAME):
        raise ValueError("未配置治理库连接：请在 .env 设置 DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME")
    pwd = quote_plus(DB_PASSWORD or "")
    url = f"mysql+pymysql://{DB_USER}:{pwd}@{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"
    return create_engine(
        url,
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=10,
        # 略短于 MySQL 默认 8h wait_timeout，减少拿到已被服务端关掉的旧连接
        pool_recycle=1200,
        connect_args={"connect_timeout": 20},
        future=True,
    )


def _get_engine() -> Engine:
    global _ENGINE
    if _ENGINE is None:
        _ENGINE = _build_engine()
    return _ENGINE


def resolve_sector_codes(sector: str) -> List[str]:
    raw = (sector or "").strip()
    if not raw:
        return list(GOVERNANCE_SECTOR_RULES.keys())
    key = raw.upper().replace("-", "_")
    if key in GOVERNANCE_SECTOR_RULES:
        return [key]

    alias_map = {
        "PRD_POWER": "PRD_RD",
        "PRD_PROCUREMENT": "PUR",
    }
    if key in alias_map:
        return [alias_map[key]]

    zh_map = {
        "电解铝": "PRD_AL",
        "氧化铝": "PRD_AO",
        "热电": "PRD_RD",
        "采购": "PUR",
    }
    if raw in zh_map:
        return [zh_map[raw]]

    for code, rule in GOVERNANCE_SECTOR_RULES.items():
        if raw == str(rule.get("project_id", "")):
            return [code]
    raise ValueError(f"未知板块标识: {sector!r}")


def _coerce_governance_project_id(rule: dict) -> int:
    """与 ddd_code_tree_node.project_id 一致，以整型绑定参数。"""
    raw = (rule or {}).get("project_id", "")
    try:
        return int(str(raw).strip())
    except (TypeError, ValueError):
        return 0


def _exclude_filters_sql(
    rule: dict,
) -> tuple[str, dict[str, str]]:
    """与拉取 SQL 中 `a.name` 过滤完全相同的片段与参数字典。"""
    excludes = list(rule.get("exclude_name_keywords") or [])
    filters_sql = ""
    extra: dict = {}
    for idx, kw in enumerate(excludes):
        pname = f"exclude_{idx}"
        filters_sql += f" and a.name not like :{pname}"
        extra[pname] = f"%{kw}%"
    return filters_sql, extra


def fetch_sql_records_by_sector_code(sector_code: str) -> List[Dict[str, str]]:
    rule = GOVERNANCE_SECTOR_RULES.get(sector_code)
    if not rule:
        raise ValueError(f"未知板块 code={sector_code!r}")

    project_id = _coerce_governance_project_id(rule)
    params = {"project_id": project_id}
    filters_sql, ex_params = _exclude_filters_sql(rule)
    params.update(ex_params)

    sql = text(
        f"""
        SELECT
            c.name AS project_name,
            a.name AS sql_file_name,
            b.content AS sql_content
        FROM ddd_code_tree_node a
        LEFT JOIN ddd_code_detail b ON a.code_detail_id = b.id
        LEFT JOIN ddd_project c ON a.project_id = c.id
        WHERE a.project_id = :project_id
          AND b.content IS NOT NULL
          {filters_sql}
        """
    )

    def _query_rows() -> list:
        engine = _get_engine()
        with engine.connect() as conn:
            return list(conn.execute(sql, params).mappings().all())

    rows = _governance_read(_query_rows)

    out: List[Dict[str, str]] = []
    for row in rows:
        content = str(row.get("sql_content") or "").strip()
        if not content:
            continue
        out.append(
            {
                "project_name": str(row.get("project_name") or rule.get("project_name") or ""),
                "sql_file_name": str(row.get("sql_file_name") or ""),
                "sql_content": content,
                "sector_code": sector_code,
                "project_id": str(project_id),
            }
        )
    return out


def fetch_sql_records_grouped(sector: str = "") -> Dict[str, List[Dict[str, str]]]:
    grouped: Dict[str, List[Dict[str, str]]] = {}
    for code in resolve_sector_codes(sector):
        grouped[code] = fetch_sql_records_by_sector_code(code)
    return grouped


def sector_sql_row_diagnostics() -> dict:
    """
    对 GOVERNANCE_SECTOR_RULES 中各板块统计治理库行数，用于核对 project_id 与 name 过滤是否将数据滤成 0。
    不修改全局 Engine；查询失败时抛出，由 API 转 502。
    """
    engine = _get_engine()
    out: dict = {
        "projectsInDb": [],
        "configuredProjectIds": [
            (code, (rule or {}).get("project_id"))
            for code, rule in GOVERNANCE_SECTOR_RULES.items()
        ],
        "sectors": {},
    }
    with engine.connect() as conn:
        prows = (
            conn.execute(
                text("SELECT id, name FROM ddd_project ORDER BY id"),
            )
            .mappings()
            .all()
        )
        out["projectsInDb"] = [dict(x) for x in prows]

    for code, rule in GOVERNANCE_SECTOR_RULES.items():
        project_id = _coerce_governance_project_id(rule or {})
        conf_raw = str((rule or {}).get("project_id", ""))
        fs, extra = _exclude_filters_sql(rule or {})
        with engine.connect() as conn:
            c_tree = conn.execute(
                text(
                    "SELECT COUNT(*) AS c FROM ddd_code_tree_node a WHERE a.project_id = :project_id"
                ),
                {"project_id": project_id},
            ).scalar()
            c_content = conn.execute(
                text(
                    f"""
                SELECT COUNT(*) AS c
                FROM ddd_code_tree_node a
                LEFT JOIN ddd_code_detail b ON a.code_detail_id = b.id
                WHERE a.project_id = :project_id
                  AND b.content IS NOT NULL
                """
                ),
                {"project_id": project_id},
            ).scalar()
            params = {"project_id": project_id, **extra}
            c_after_name_filter = conn.execute(
                text(
                    f"""
                SELECT COUNT(*) AS c
                FROM ddd_code_tree_node a
                LEFT JOIN ddd_code_detail b ON a.code_detail_id = b.id
                WHERE a.project_id = :project_id
                  AND b.content IS NOT NULL
                {fs}
                """
                ),
                params,
            ).scalar()
        rows = fetch_sql_records_by_sector_code(code)
        out["sectors"][code] = {
            "projectIdInConfig": conf_raw,
            "projectIdQueryBound": project_id,
            "projectNameInConfig": (rule or {}).get("project_name", ""),
            "treeNodesInProject": int(c_tree or 0),
            "rowsWithContentNotNull": int(c_content or 0),
            "rowsAfterNameExcludesInSql": int(c_after_name_filter or 0),
            "returnedToAppAfterContentStrip": len(rows),
            "excludeNameKeywords": list((rule or {}).get("exclude_name_keywords") or []),
        }
    return out
