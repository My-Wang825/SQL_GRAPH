# -*- coding: utf-8 -*-
"""
ETL SQL 解析器：
用于后端构建知识图谱时解析每个SQL脚本文件
从 INSERT INTO ... SELECT ... FROM ... JOIN 等语句中提取表名、表关系（来自 JOIN ON）及注释
"""
import re # 正则表达式
from pathlib import Path 
from typing import List, Dict, Tuple # 类型注解

# 表名匹配：`schema`.`table` 或 schema.table 或 table
TABLE_NAME_PATTERN = r"(?:`?\w+`?\.)?`?(\w+)`?"  
# INSERT INTO schema.table (cols) 或 INSERT INTO table
INSERT_INTO_PATTERN = re.compile(
    r"insert\s+into\s+" + TABLE_NAME_PATTERN + r"(?:\s*\([^)]*\))?",
    re.IGNORECASE | re.DOTALL,
)
# TRUNCATE TABLE schema.table
TRUNCATE_PATTERN = re.compile(
    r"truncate\s+table\s+" + TABLE_NAME_PATTERN,
    re.IGNORECASE,
)
# DELETE FROM table
DELETE_FROM_PATTERN = re.compile(
    r"delete\s+from\s+" + TABLE_NAME_PATTERN,
    re.IGNORECASE,
)
# FROM schema.table [alias] 或 FROM ( subquery ) alias
FROM_JOIN_PATTERN = re.compile(
    r"(?:from|join)\s+(?:" + TABLE_NAME_PATTERN + r")\s+(\w+)|"
    r"(?:from|join)\s+" + TABLE_NAME_PATTERN,
    re.IGNORECASE,
)
# 表名后的合法结束符（含分号、行注释 --，常见：FROM schema.table; 或 FROM schema.table--备注）
_FROM_JOIN_SUFFIX = r"(?:\s|;|$|\)|,|--)"

# 更精确：FROM table [as] alias 或 JOIN table [as] alias
FROM_JOIN_TABLE_ALIAS = re.compile(
    r"(?:from|join)\s+([a-zA-Z0-9_.`]+)\s+(?:as\s+)?(\w+)" + _FROM_JOIN_SUFFIX,
    re.IGNORECASE,
)
FROM_JOIN_TABLE_ONLY = re.compile(
    r"(?:from|join)\s+([a-zA-Z0-9_.`]+)" + _FROM_JOIN_SUFFIX,
    re.IGNORECASE,
)

SQL_KEYWORDS = {
    "select", "from", "join", "where", "on", "and", "or", "group", "order",
    "by", "left", "right", "inner", "outer", "full", "cross", "union",
    "all", "case", "when", "then", "else", "end", "as", "with", "into",
}


def _normalize_table(s: str) -> str:
    """去掉反引号和 schema，只保留表名"""
    s = s.strip().strip("`")
    if "." in s:
        return s.split(".")[-1].strip("`")
    return s


def _extract_subquery_aliases(content: str) -> set:
    """
    提取子查询别名，例如：
      FROM (SELECT ...) deprec
      LEFT JOIN (SELECT ...) dine_fgs
    """
    pattern = re.compile(
        r"(?:from|join)\s*\([\s\S]*?\)\s*(?:as\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=,|\s+(?:left|right|inner|outer|full|cross|join|on|where|group|order|union)\b|$)",
        re.IGNORECASE,
    )
    return {m.group(1).lower() for m in pattern.finditer(content)}


def _is_valid_table_token(token: str, subquery_aliases: set) -> bool:
    """过滤明显不是表名的 token。"""
    if not token:
        return False
    t = token.strip().strip("`").lower()
    if not t or t in SQL_KEYWORDS:
        return False
    if t in subquery_aliases:
        return False
    if "(" in t or ")" in t:
        return False
    # 通配符、数字字面量等
    if t.startswith("'") or t.startswith('"') or t.isdigit():
        return False
    return True


def _extract_comment_from_sql(content: str) -> str:
    """从 SQL 文件开头的 /* */ 或 -- 描述 中提取描述"""
    # /* ... 描述：xxx ... */
    m = re.search(r"描述[：:]\s*([^\n*]+)", content)
    if m:
        return m.group(1).strip()
    # -- 描述：xxx
    m = re.search(r"--\s*描述[：:]\s*([^\n]+)", content)
    if m:
        return m.group(1).strip()
    return ""


class ETLSqlParser:
    """解析 ETL 风格 SQL（INSERT/SELECT/JOIN），提取表与关系。"""

    def __init__(self, default_schema: str = "sdhq"):
        self.default_schema = default_schema

    def parse_file(self, file_path: str) -> Tuple[List[dict], List[dict], str]:
        """
        解析单个 SQL 文件。
        返回: (表信息列表, 关系列表, 文件级注释)
        """
        path = Path(file_path)
        if not path.exists():
            return [], [], ""
        content = path.read_text(encoding="utf-8", errors="ignore")
        return self.parse_content(content, str(path))

    def parse_content(
        self, content: str, source_path: str = ""
    ) -> Tuple[List[dict], List[dict], str]:
        """
        解析 SQL 内容。
        返回: (表信息列表, 关系列表, 描述注释)
        """
        comment = _extract_comment_from_sql(content)
        tables_found: Dict[str, dict] = {}
        relations: List[dict] = []
        global_subquery_aliases = _extract_subquery_aliases(content)

        # 1) 收集所有出现的表名（INSERT INTO, TRUNCATE, DELETE, FROM, JOIN）
        for m in INSERT_INTO_PATTERN.finditer(content):
            t = _normalize_table(m.group(1))
            tables_found.setdefault(t, {"name": t, "comment": comment, "file_path": source_path, "role": "target"})

        for m in TRUNCATE_PATTERN.finditer(content):
            t = _normalize_table(m.group(1))
            tables_found.setdefault(t, {"name": t, "comment": comment, "file_path": source_path, "role": "target"})

        for m in DELETE_FROM_PATTERN.finditer(content):
            t = _normalize_table(m.group(1))
            tables_found.setdefault(t, {"name": t, "comment": comment, "file_path": source_path, "role": "target"})

        # FROM / JOIN table [alias]
        for m in FROM_JOIN_TABLE_ALIAS.finditer(content):
            full = m.group(1).strip().strip("`")
            alias = m.group(2).strip()
            t = _normalize_table(full)
            if _is_valid_table_token(t, global_subquery_aliases):
                tables_found.setdefault(t, {"name": t, "comment": "", "file_path": source_path, "role": "source"})
                tables_found[t]["alias"] = alias

        for m in FROM_JOIN_TABLE_ONLY.finditer(content):
            full = m.group(1).strip().strip("`")
            t = _normalize_table(full)
            if _is_valid_table_token(t, global_subquery_aliases):
                tables_found.setdefault(t, {"name": t, "comment": "", "file_path": source_path, "role": "source"})

        # 2) 提取 INSERT INTO target ... SELECT ... FROM/JOIN 的 target -> source 数据流关系
        # 以及 JOIN ON alias.col = alias.col 的显式列关联
        insert_target = None
        # 按语句块：找到 INSERT INTO target 后的 FROM/JOIN 直到下一个 INSERT 或结尾
        chunks = re.split(r"\binsert\s+into\b", content, flags=re.IGNORECASE)
        for i, chunk in enumerate(chunks):
            if i == 0:
                continue
            # chunk 开头是 table_name (cols)? ...
            m = re.match(r"\s*[a-zA-Z0-9_.`]+\s*(?:\([^)]*\))?\s*", chunk)
            if m:
                target_part = chunk[: m.end()].strip()
                table_part = re.sub(r"\s*\([^)]*\)\s*", " ", target_part).strip()
                insert_target = _normalize_table(table_part.split()[0] if table_part else "")
            else:
                insert_target = None

            if not insert_target:
                continue

            # 在本段中找 FROM / JOIN 得到 source 表列表
            segment = chunk
            # 去掉 VALUES (...) 块，只保留 SELECT ... FROM 部分
            if " values " in segment.lower():
                segment = segment.lower().split(" values ")[0]
            segment_subquery_aliases = _extract_subquery_aliases(segment)
            from_joins = re.findall(
                r"(?:from|join)\s+([a-zA-Z0-9_.`]+)(?:\s+(?:as\s+)?(\w+))?"
                + _FROM_JOIN_SUFFIX,
                segment,
                re.IGNORECASE,
            )
            alias_to_table: Dict[str, str] = {}
            source_name_map: Dict[str, str] = {}
            sources: List[str] = []
            for full, alias in from_joins:
                t = _normalize_table(full)
                if _is_valid_table_token(t, segment_subquery_aliases):
                    sources.append(t)
                    source_name_map[t.lower()] = t
                    if alias:
                        alias_to_table[alias.lower()] = t

            for s in sources:
                if s != insert_target:
                    relations.append({
                        "source_table": s,
                        "target_table": insert_target,
                        "source_column": "",
                        "target_column": "",
                        "relation_type": "DATA_FLOW",
                        "confidence": 0.9,
                        "strength": 70,
                        "reason": "INSERT-SELECT 数据流",
                    })

        table_list = [{"name": v["name"], "comment": v.get("comment", ""), "file_path": v.get("file_path", "")} for v in tables_found.values()]
        return table_list, relations, comment
