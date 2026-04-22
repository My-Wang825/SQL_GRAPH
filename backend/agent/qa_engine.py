# -*- coding: utf-8 -*-
"""
基于规则与内存图遍历的智能问答：意图识别 → 查询 → 自然语言 + 高亮结构。
不依赖外部 LLM，便于离线部署。
"""
from __future__ import annotations

import re
import difflib
from collections import deque
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# 分层判定（与前端 tableDataLayer 对齐）
# ---------------------------------------------------------------------------


def _base_name(name: str) -> str:
    n = (name or "").lower()
    return n[2:] if n.startswith("v_") else n


def is_ods(name: str) -> bool:
    return _base_name(name).startswith("ods_")


def is_dwd(name: str) -> bool:
    b = _base_name(name)
    return b.startswith("dwd_") or b.startswith("dws_")


def is_ads(name: str) -> bool:
    return _base_name(name).startswith("ads_")


def is_dm_dim(name: str) -> bool:
    b = _base_name(name)
    return b.startswith("dim_") or b.startswith("dm_")


LAYER_PREDICATES: Dict[str, Callable[[str], bool]] = {
    "ODS": is_ods,
    "DWD": is_dwd,
    "DWS": lambda n: _base_name(n).startswith("dws_"),
    "ADS": is_ads,
    "DM": is_dm_dim,
    "DIM": is_dm_dim,
}

SECTOR_LABELS = {
    "PRD_AL": "电解铝（PRD_AL）",
    "PRD_AO": "氧化铝（PRD_AO）",
}


def _sector_from_file_path(fp: str) -> str:
    if not fp:
        return ""
    low = fp.replace("\\", "/").lower()
    if "prd_ao" in low or "prd-ao" in low:
        return "氧化铝"
    if "prd_al" in low or "prd-al" in low:
        return "电解铝"
    return ""


# ---------------------------------------------------------------------------
# 图结构
# ---------------------------------------------------------------------------


def _build_adjacency(
    links: List[dict],
) -> Tuple[Dict[str, Set[str]], Dict[str, Set[str]]]:
    pred: Dict[str, Set[str]] = {}
    succ: Dict[str, Set[str]] = {}
    for e in links:
        s, t = e.get("source"), e.get("target")
        if not s or not t or s == t:
            continue
        pred.setdefault(t, set()).add(s)
        succ.setdefault(s, set()).add(t)
        pred.setdefault(s, set())
        succ.setdefault(t, set())
    return pred, succ


def _collect_node_ids(nodes: List[dict]) -> Set[str]:
    return {n.get("id") or n.get("name") for n in nodes if (n.get("id") or n.get("name"))}


def _upstream_all(node: str, pred: Dict[str, Set[str]]) -> Set[str]:
    """沿数据流逆向：谁汇入 node（含多跳）。"""
    seen: Set[str] = set()
    q = deque([node])
    seen.add(node)
    while q:
        u = q.popleft()
        for p in pred.get(u, ()):
            if p not in seen:
                seen.add(p)
                q.append(p)
    return seen


def _downstream_all(node: str, succ: Dict[str, Set[str]]) -> Set[str]:
    seen: Set[str] = set()
    q = deque([node])
    seen.add(node)
    while q:
        u = q.popleft()
        for v in succ.get(u, ()):
            if v not in seen:
                seen.add(v)
                q.append(v)
    return seen


def _bfs_path(start: str, goal: str, succ: Dict[str, Set[str]]) -> Optional[List[str]]:
    if start == goal:
        return [start]
    if start not in succ and start not in {x for vs in succ.values() for x in vs}:
        # 孤立点仍可能只在 pred 侧出现
        pass
    q = deque([(start, [start])])
    visit = {start}
    while q:
        u, path = q.popleft()
        for v in succ.get(u, ()):
            if v in visit:
                continue
            np = path + [v]
            if v == goal:
                return np
            visit.add(v)
            q.append((v, np))
    return None


def _bfs_to_layer(
    start: str,
    layer_to: Callable[[str], bool],
    succ: Dict[str, Set[str]],
    max_depth: int = 80,
) -> Optional[List[str]]:
    """从 start 沿 succ 前进，第一次到达满足 layer_to 的节点（可与起点不同）。"""
    q = deque([(start, [start])])
    seen = {start}
    while q:
        u, path = q.popleft()
        if layer_to(u) and u != start:
            return path
        if len(path) >= max_depth:
            continue
        for v in succ.get(u, ()):
            if v not in seen:
                seen.add(v)
                q.append((v, path + [v]))
    return None


def _shortest_path_layer_to_layer(
    layer_from: Callable[[str], bool],
    layer_to: Callable[[str], bool],
    succ: Dict[str, Set[str]],
    node_ids: Set[str],
) -> Optional[List[str]]:
    sources = [n for n in node_ids if layer_from(n)]
    if not sources:
        return None
    best: Optional[List[str]] = None
    for s in sources[:400]:
        path = _bfs_to_layer(s, layer_to, succ)
        if path and (best is None or len(path) < len(best)):
            best = path
    return best


def _longest_simple_path_layer_to_layer(
    layer_from: Callable[[str], bool],
    layer_to: Callable[[str], bool],
    succ: Dict[str, Set[str]],
    node_ids: Set[str],
    max_depth: int = 56,
) -> Optional[List[str]]:
    """
    在深度上限内找一条尽量长的简单路径：起点满足 layer_from，终点满足 layer_to。
    用于「完整链路」类问题（区别于最短路径）。
    """
    sources = [n for n in node_ids if layer_from(n)]
    if not sources:
        return None
    best: Optional[List[str]] = None

    def dfs(u: str, path: List[str], seen: Set[str]) -> None:
        nonlocal best
        if len(path) > max_depth:
            return
        extended = False
        for v in succ.get(u, ()):
            if v in seen:
                continue
            extended = True
            seen.add(v)
            path.append(v)
            dfs(v, path, seen)
            path.pop()
            seen.remove(v)
        if not extended and len(path) >= 2:
            if layer_to(path[-1]):
                if best is None or len(path) > len(best):
                    best = list(path)

    for s in sources[:320]:
        dfs(s, [s], {s})
    return best


# ---------------------------------------------------------------------------
# 实体：从问句中解析表名
# ---------------------------------------------------------------------------


def _strip_question_noise(text: str) -> str:
    """去掉常见口语，减少误把整句拿去和表名比对。"""
    s = (text or "").strip()
    for pat in (
        r"请[问]?[分析]?[一下]?",
        r"这[个张幅]?",
        r"该[张表]?",
        r"的?(?:上游|下游|来源|去向|血缘|依赖|影响).*?$",
        r"[？?！!。.]+$",
    ):
        s = re.sub(pat, "", s, flags=re.UNICODE)
    return s.strip()


def _extract_sql_like_identifiers(text: str) -> List[str]:
    """提取疑似表名片段：字母开头、含下划线的标识符。"""
    return re.findall(r"\b[a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z][a-zA-Z0-9_]*)?\b", text or "")


def _resolve_table_name(text: str, node_ids: List[str]) -> Optional[str]:
    """优先匹配问句中出现的完整标识符，再做最长子串匹配（避免整句误命中短表名）。"""
    if not (text or "").strip():
        return None
    ids_sorted = sorted(node_ids, key=len, reverse=True)
    lowered = {n.lower(): n for n in node_ids}

    # 1) schema.table 或裸表名与节点 id 完全一致（忽略大小写）
    for tok in _extract_sql_like_identifiers(text):
        short = tok.split(".")[-1].lower()
        if short in lowered:
            return lowered[short]

    # 2) 在「去口语」后的文本上做最长 id 子串匹配
    t = _strip_question_noise(text).lower()
    if not t:
        t = (text or "").lower()
    for nid in ids_sorted:
        nl = nid.lower()
        if nl in t:
            return nid
    return None


def _extract_two_tables(
    text: str, node_ids: List[str]
) -> Tuple[Optional[str], Optional[str]]:
    """匹配「从 A 到 B」类句式，再尝试解析表名。"""
    m = re.search(
        r"从\s*([^到\n]+?)\s*到\s*([^？\?\n]+)", text, re.UNICODE
    )
    if not m:
        return None, None
    a_raw, b_raw = m.group(1).strip(), m.group(2).strip()
    # 去掉常见修饰
    for chunk in (a_raw, b_raw):
        pass
    a = _resolve_entity(a_raw, node_ids)
    b = _resolve_entity(b_raw, node_ids)
    return a, b


def _resolve_entity(fragment: str, node_ids: List[str]) -> Optional[str]:
    frag = fragment.strip()
    if not frag:
        return None
    # 层名而非具体表
    upper = frag.upper()
    for key in ("ODS", "DWD", "DWS", "ADS", "DM", "DIM"):
        if key in upper and len(frag) < 20:
            return None
    # 直接命中
    hit = _resolve_table_name(frag, node_ids)
    if hit:
        return hit
    # 片段即短名
    low = frag.lower()
    for nid in node_ids:
        if nid.lower() == low:
            return nid
    return None


def _parse_layer_token(text: str) -> Optional[str]:
    u = text.upper()
    for k in ("ODS", "DWD", "DWS", "ADS", "DM", "DIM"):
        if k in u:
            return k
    return None


# ---------------------------------------------------------------------------
# 模糊搜索
# ---------------------------------------------------------------------------


def _fuzzy_matches(keyword: str, nodes: List[dict], limit: int = 25) -> List[dict]:
    kw = (keyword or "").strip()
    if not kw:
        return []
    kw_low = kw.lower()
    scored: List[Tuple[float, dict]] = []
    for n in nodes:
        nid = n.get("id") or n.get("name") or ""
        name = (n.get("name") or nid).lower()
        comment = (n.get("comment") or "").lower()
        disp = (n.get("displayName") or "").lower()
        best = 0.0
        if kw_low in name:
            best = max(best, 0.95 + 0.05 * min(1.0, len(kw_low) / max(len(name), 1)))
        elif kw_low in comment or kw_low in disp:
            best = max(best, 0.88)
        else:
            r1 = difflib.SequenceMatcher(None, kw_low, name).ratio()
            r2 = difflib.SequenceMatcher(None, kw_low, comment[:120]).ratio() if comment else 0
            best = max(r1, r2) * 0.85
        if best > 0.35:
            scored.append((best, {"id": nid, "name": n.get("name"), "score": round(best, 3)}))
    scored.sort(key=lambda x: -x[0])
    return [x[1] for x in scored[:limit]]


def _normalize_keyword_candidate(text: str) -> str:
    s = _strip_question_noise(text or "")
    s = s.strip().strip("「」『』\"'`").strip()
    s = re.sub(r"^(?:请问|帮我|麻烦|看下|看一下)\s*", "", s, flags=re.I)
    s = re.sub(r"^(?:表名|表|库表)\s*(?:中)?\s*", "", s, flags=re.I)
    s = re.sub(r"^(?:包含|含有|搜索|查找)\s*", "", s, flags=re.I)
    s = re.sub(r"^(?:关键词|关键字)\s*(?:是|为)?\s*", "", s, flags=re.I)
    for _ in range(3):
        prev = s
        s = re.sub(r"\s*(?:相关信息|关键字|关键词)\s*$", "", s, flags=re.I)
        s = re.sub(
            r"\s*(?:的)?(?:表名|表|库表)\s*(?:有哪[些]|有哪些|有那些|有多少|列表|清单)?\s*$",
            "",
            s,
            flags=re.I,
        )
        s = re.sub(r"\s*(?:有哪[些]|有哪些|有那些|有多少|列表|清单|吗|么)\s*$", "", s, flags=re.I)
        s = s.strip("：:，,。；;？? ")
        if s == prev:
            break
    return s.strip()


def _fallback_identifier_keyword(text: str) -> Optional[str]:
    stopwords = {
        "contains",
        "contain",
        "search",
        "find",
        "keyword",
    }
    toks = [
        tok.split(".")[-1]
        for tok in _extract_sql_like_identifiers(text)
        if tok and tok.lower() not in stopwords
    ]
    if not toks:
        return None
    toks.sort(key=len, reverse=True)
    return toks[0]


def _extract_keyword_phrase(q: str) -> Optional[str]:
    text = _strip_question_noise(q or "")
    m2 = re.search(r"['\"]([^'\"]{2,64})['\"]", q)
    if m2:
        return m2.group(1).strip()
    patterns = [
        r"(?:表名|表|库表)?\s*(?:包含|含有)\s*[「『\"']?(.+?)[」』\"']?\s*(?:的)?(?:表名|表|库表)?(?:有哪[些]|有哪些|有那些|有多少|列表|清单)?\s*$",
        r"(?:搜索|查找)\s*[「『\"']?(.+?)[」』\"']?\s*(?:相关信息)?(?:的)?(?:表名|表|库表)?(?:有哪[些]|有哪些|有那些|有多少|列表|清单)?\s*$",
        r"(?:关键词|关键字)\s*(?:是|为)?\s*[「『\"']?(.+?)[」』\"']?\s*(?:的)?(?:表名|表|库表)?(?:有哪[些]|有哪些|有那些|有多少|列表|清单)?\s*$",
    ]
    for pat in patterns:
        m = re.search(pat, text, flags=re.I)
        if not m:
            continue
        kw = _normalize_keyword_candidate(m.group(1))
        if kw:
            return kw
    kw = _normalize_keyword_candidate(text)
    if kw and kw != text:
        return kw
    return None


# ---------------------------------------------------------------------------
# 意图
# ---------------------------------------------------------------------------


def _from_to_segments(text: str) -> Optional[Tuple[str, str]]:
    m = re.search(r"从\s*([^到\n]+?)\s*到\s*([^？\?\n]+)", text, re.UNICODE)
    if not m:
        return None
    return m.group(1).strip(), m.group(2).strip()


def _looks_like_path_query(text: str) -> bool:
    """路径意图：避免用整句里出现的 ods_/ads_ 表名误判为「分层路径」。"""
    if not re.search(r"从\s*.+\s*到", text):
        return False
    if any(x in text for x in ("链路", "路径", "完整", "数据流", "走向")):
        return True
    seg = _from_to_segments(text)
    if not seg:
        return False
    a, b = seg
    # 分层：两侧多为短词且带层名
    if len(a) <= 16 and len(b) <= 16:
        if _parse_layer_token(a + " " + b):
            return True
        if re.search(r"(ODS|DWD|DWS|ADS|DM|DIM|贴源|明细|应用)(层|表)?", a + b, re.I):
            return True
    # 两表：典型表名片段
    if "_" in a or "_" in b:
        return True
    return False


def _detect_intent(q: str) -> str:
    text = q.strip()
    # 路径 / 链路（不再用整句 "ODS" in text.upper()，否则会与表名 ods_xxx 冲突）
    if _looks_like_path_query(text):
        return "path_query"
    if ("路径" in text and any(x in text for x in ("哪", "怎么", "如何"))) and re.search(r"从.+到", text):
        return "path_query"
    # 影响分析须先于泛「下游」匹配，避免「影响下游 ADS」被判成 downstream_trace
    if "影响" in text:
        if any(
            x in text
            for x in ("ADS", "ads", "应用层", "下游", "下游表", "结果表")
        ):
            return "impact_analysis"
        if "dwd" in text.lower() or "dws" in text.lower():
            return "impact_analysis"
    # 关联统计（收紧「最多」类，避免与普通「哪个最多」混淆）
    if ("关联" in text or "边" in text or "度数" in text or "扇入" in text or "扇出" in text) and any(
        x in text for x in ("最多", "最大", "最少", "最小")
    ) and ("表" in text or "节点" in text or "哪张" in text or "哪个" in text):
        return "assoc_stats"
    if "几条边" in text or "多少条边" in text:
        return "assoc_stats"
    # 业务域
    if any(x in text for x in ("业务域", "哪个域", "哪个板块", "属于哪", "数据集")):
        return "node_property"
    # 上下游都要看（「上下游」里含子串「下游」，必须先于 downstream 判断）
    if "上下游" in text or "上下级" in text:
        return "lineage_both"
    # 下游血缘：「上下游」中的「下游」前为「上」，正则不匹配
    if re.search(r"(?<![上])下游|下游表|下级表|downstream", text, re.I):
        return "downstream_trace"
    if any(
        x in text
        for x in (
            "去向",
            "输出了",
            "汇聚到",
            "谁用到了",
            "被哪些表用",
        )
    ):
        return "downstream_trace"
    # 上游 / 依赖（不要用单独「来源」二字，易与英文/字段片段误匹配）
    if any(
        x in text
        for x in (
            "依赖",
            "上游",
            "溯源",
            "来自哪些",
            "数据来自",
            "数据来源",
            "用到哪些",
            "基于哪些",
            "汇入",
        )
    ):
        return "upstream_trace"
    # 模糊
    if any(x in text for x in ("包含", "含有", "关键词", "模糊", "搜索", "查找")):
        return "fuzzy_search"
    return "unknown"


def _repair_intent(q: str, intent: str) -> str:
    """二次纠正：避免上游关键词误抢「下游」类问题。"""
    t = q or ""
    if intent == "upstream_trace" and re.search(
        r"(?<![上])下游|下游表|下级表|downstream", t, re.I
    ):
        return "downstream_trace"
    return intent


# ---------------------------------------------------------------------------
# 主入口
# ---------------------------------------------------------------------------


def answer_question(
    question: str,
    nodes: List[dict],
    links: List[dict],
    sector_code: str = "",
) -> Dict[str, Any]:
    q = (question or "").strip()
    node_ids_list = sorted(_collect_node_ids(nodes))
    node_ids = set(node_ids_list)
    pred, succ = _build_adjacency(links)
    sector_label = SECTOR_LABELS.get(sector_code.upper().replace("-", "_"), sector_code or "当前图谱")

    empty_highlight = {"node_ids": [], "links": []}

    if not q:
        return {
            "answer": "请输入自然语言问题，例如：某张 ADS 表依赖哪些 ODS 表？",
            "intent": "unknown",
            "intent_label": "未知",
            "confidence": 0.0,
            "highlight": empty_highlight,
            "matches": [],
        }

    intent = _repair_intent(q, _detect_intent(q))

    # ---------- 关联统计 ----------
    if intent == "assoc_stats":
        best_n = None
        best_d = -1
        for n in nodes:
            nid = n.get("id")
            if not nid:
                continue
            d = int(n.get("relationCount") or 0)
            if d > best_d:
                best_d = d
                best_n = n
        if best_n:
            nid = best_n.get("id")
            hl_nodes = [nid]
            hl_links = []
            for e in links:
                if e.get("source") in (nid,) or e.get("target") == nid:
                    hl_links.append(
                        {"source": e["source"], "target": e["target"]}
                    )
            ans = (
                f"在当前图谱中，关联边数最多的是表「{nid}」，共有 {best_d} 条边与之相连（与后端 relationCount 一致）。"
                f"可在图中查看其上下游。"
            )
            return {
                "answer": ans,
                "intent": "assoc_stats",
                "intent_label": "关联统计",
                "confidence": 1.0,
                "highlight": {"node_ids": hl_nodes, "links": hl_links[:500]},
                "matches": [],
            }

    # ---------- 节点属性（业务域）----------
    if intent == "node_property":
        tid = _resolve_table_name(q, node_ids_list)
        if not tid:
            return {
                "answer": "未能识别问题中的表名，请写出完整表名或包含表名的片段。",
                "intent": "node_property",
                "intent_label": "节点属性",
                "confidence": 0.4,
                "highlight": empty_highlight,
                "matches": [],
            }
        node = next((n for n in nodes if (n.get("id") or n.get("name")) == tid), None)
        fp = (node or {}).get("filePath") or ""
        sub = _sector_from_file_path(fp)
        if sub:
            domain = sub
        else:
            domain = sector_label
        ans = f"表「{tid}」属于业务域「{domain}」（依据当前加载的板块 / 文件路径推断）。"
        return {
            "answer": ans,
            "intent": "node_property",
            "intent_label": "节点属性",
            "confidence": 0.95 if sub else 0.85,
            "highlight": {"node_ids": [tid], "links": []},
            "matches": [],
        }

    # ---------- 模糊搜索 ----------
    if intent == "fuzzy_search":
        kw = _extract_keyword_phrase(q)
        if not kw:
            kw = q.replace("包含", "").replace("哪些", "").replace("表", "").strip("？? ")
        if len(kw.strip()) <= 1:
            ident_kw = _fallback_identifier_keyword(q)
            if ident_kw and len(ident_kw) > len(kw.strip()):
                kw = ident_kw
        matches = _fuzzy_matches(kw, nodes, 30)
        if not matches:
            return {
                "answer": f"没有找到与「{kw}」匹配的表（已尝试表名与注释模糊匹配）。",
                "intent": "fuzzy_search",
                "intent_label": "模糊搜索",
                "confidence": 0.5,
                "highlight": empty_highlight,
                "matches": [],
            }
        hl = [m["id"] for m in matches[:20]]
        conf = matches[0]["score"] if matches else 0.5
        lines = [f"- {m['name']}（匹配度 {m['score']:.0%}）" for m in matches[:12]]
        ans = (
            f"包含「{kw}」相关信息的表共 {len(matches)} 条（展示前 {min(12, len(matches))} 条）：\n"
            + "\n".join(lines)
        )
        return {
            "answer": ans,
            "intent": "fuzzy_search",
            "intent_label": "模糊搜索",
            "confidence": conf,
            "highlight": {"node_ids": hl, "links": []},
            "matches": matches,
        }

    # ---------- 路径查询 ----------
    if intent == "path_query":
        a, b = _extract_two_tables(q, node_ids_list)
        path_links: List[dict] = []

        if a and b:
            path = _bfs_path(a, b, succ)
            if not path:
                return {
                    "answer": f"未找到从「{a}」到「{b}」的有向数据流路径（或二者不连通）。",
                    "intent": "path_query",
                    "intent_label": "路径查询",
                    "confidence": 0.9,
                    "highlight": {"node_ids": [a, b], "links": []},
                    "matches": [],
                }
            for i in range(len(path) - 1):
                path_links.append({"source": path[i], "target": path[i + 1]})
            chain = " → ".join(path)
            ans = f"从「{a}」到「{b}」的一条最短数据链路为：{chain}（共 {len(path)} 个节点，{len(path)-1} 跳）。"
            return {
                "answer": ans,
                "intent": "path_query",
                "intent_label": "路径查询",
                "confidence": 1.0,
                "highlight": {"node_ids": path, "links": path_links},
                "matches": [],
            }

        # 层到层
        mlay = re.search(
            r"从\s*([^\s到]+)\s*到\s*([^\s？\?]+)", q
        )
        if mlay:
            raw_a, raw_b = mlay.group(1).strip(), mlay.group(2).strip()
            la = _parse_layer_token(raw_a) or "ODS"
            lb = _parse_layer_token(raw_b) or "ADS"
            pf = LAYER_PREDICATES.get(la, is_ods)
            pt = LAYER_PREDICATES.get(lb, is_ads)
            want_full = any(
                x in q for x in ("完整", "最长", "尽可能长", "全部", "中间层", "经过")
            )
            if want_full:
                path = _longest_simple_path_layer_to_layer(pf, pt, succ, node_ids)
            else:
                path = _shortest_path_layer_to_layer(pf, pt, succ, node_ids)
            if not path:
                path = _shortest_path_layer_to_layer(pf, pt, succ, node_ids)
            if path:
                for i in range(len(path) - 1):
                    path_links.append({"source": path[i], "target": path[i + 1]})
                chain = " → ".join(path)
                mode = "尽量长（在深度上限内）的" if want_full and len(path) > 2 else "一条"
                ans = (
                    f"从 {la} 层到 {lb} 层，{mode}数据链路为：{chain}"
                    f"（共 {len(path)} 个节点，{len(path) - 1} 跳）。"
                )
                if want_full and len(path) == 2:
                    ans += " 说明：图中存在更短的直连；若需必经中间层，可补充「经过 DWD」等描述。"
                return {
                    "answer": ans,
                    "intent": "path_query",
                    "intent_label": "路径查询",
                    "confidence": 0.88 if want_full else 0.85,
                    "highlight": {"node_ids": path, "links": path_links},
                    "matches": [],
                }

        return {
            "answer": "路径类问题请使用「从 表A 到 表B」或「从 ODS 到 ADS」这类描述。",
            "intent": "path_query",
            "intent_label": "路径查询",
            "confidence": 0.3,
            "highlight": empty_highlight,
            "matches": [],
        }

    # ---------- 影响分析 ----------
    if intent == "impact_analysis":
        tid = _resolve_table_name(q, node_ids_list)
        if not tid or tid not in node_ids:
            return {
                "answer": "未能识别要分析的表名，请包含完整表名（如 dwd_xxx / ads_xxx）。",
                "intent": "impact_analysis",
                "intent_label": "影响分析",
                "confidence": 0.4,
                "highlight": empty_highlight,
                "matches": [],
            }
        down = _downstream_all(tid, succ)
        ads_down = sorted([x for x in down if is_ads(x) and x != tid])
        hl_nodes = [tid] + ads_down
        hl_links = []
        for e in links:
            s, t = e.get("source"), e.get("target")
            if not s or not t:
                continue
            if s in down and t in down:
                if is_ads(t) or t == tid or s == tid:
                    hl_links.append({"source": s, "target": t})
        ans = (
            f"若以「{tid}」为起点沿数据流向下游追溯，共影响 {len(ads_down)} 张 ADS 表"
            f"（仅统计可达的 ads_ 前缀表）。"
        )
        if ads_down:
            ans += f" 例如：{', '.join(ads_down[:8])}" + (
                " 等。" if len(ads_down) > 8 else "。"
            )
        else:
            ans += " 当前未找到可达的 ADS 下游表。"
        return {
            "answer": ans,
            "intent": "impact_analysis",
            "intent_label": "影响分析",
            "confidence": 0.92,
            "highlight": {"node_ids": hl_nodes[:200], "links": hl_links[:800]},
            "matches": [],
        }

    # ---------- 上下游一览 ----------
    if intent == "lineage_both":
        tid = _resolve_table_name(q, node_ids_list)
        if not tid:
            fuzzy = _fuzzy_matches(_strip_question_noise(q) or q, nodes, 5)
            if len(fuzzy) == 1:
                tid = fuzzy[0]["id"]
            elif fuzzy:
                return {
                    "answer": "请明确表名。候选：" + "、".join(f["name"] for f in fuzzy[:5]),
                    "intent": "lineage_both",
                    "intent_label": "上下游",
                    "confidence": fuzzy[0]["score"],
                    "highlight": empty_highlight,
                    "matches": fuzzy,
                }
            else:
                return {
                    "answer": "未能识别表名，请在问题中写出完整表名（可含 schema）。",
                    "intent": "lineage_both",
                    "intent_label": "上下游",
                    "confidence": 0.35,
                    "highlight": empty_highlight,
                    "matches": [],
                }
        up = _upstream_all(tid, pred)
        down = _downstream_all(tid, succ)
        ods_n = len([x for x in up if is_ods(x)])
        dwd_n = len([x for x in up if is_dwd(x)])
        ads_n = len([x for x in down if is_ads(x)])
        hl_nodes = list(up | down)
        hl_links = []
        for e in links:
            s, t = e.get("source"), e.get("target")
            if not s or not t:
                continue
            if (s in up or s in down) and (t in up or t in down):
                hl_links.append({"source": s, "target": t})
        ans = (
            f"表「{tid}」：向上游可追溯约 {len(up)-1} 跳（含自身），其中约 {ods_n} 张 ODS、{dwd_n} 张 DWD/DWS；"
            f"向下游可达约 {len(down)-1} 跳，其中约 {ads_n} 张 ADS（均为表名前缀启发式统计）。"
        )
        return {
            "answer": ans,
            "intent": "lineage_both",
            "intent_label": "上下游",
            "confidence": 0.88,
            "highlight": {"node_ids": hl_nodes[:220], "links": hl_links[:900]},
            "matches": [],
        }

    # ---------- 下游溯源 ----------
    if intent == "downstream_trace":
        tid = _resolve_table_name(q, node_ids_list)
        if not tid:
            fuzzy = _fuzzy_matches(_strip_question_noise(q) or q, nodes, 5)
            if len(fuzzy) == 1:
                tid = fuzzy[0]["id"]
            elif fuzzy:
                return {
                    "answer": "请明确表名。候选：" + "、".join(f["name"] for f in fuzzy[:5]),
                    "intent": "downstream_trace",
                    "intent_label": "下游溯源",
                    "confidence": fuzzy[0]["score"],
                    "highlight": empty_highlight,
                    "matches": fuzzy,
                }
            else:
                return {
                    "answer": "未能识别表名，请在问题中写出完整表名。",
                    "intent": "downstream_trace",
                    "intent_label": "下游溯源",
                    "confidence": 0.35,
                    "highlight": empty_highlight,
                    "matches": [],
                }
        want_direct = any(
            x in q for x in ("哪个", "哪张", "直接", "一级", "1跳", "一跳", "立即")
        )
        direct = sorted(succ.get(tid, ()))
        down = _downstream_all(tid, succ)
        want_ads = "ads" in q.lower() or "应用" in q

        if want_direct:
            hl_nodes = [tid] + direct
            hl_links = [{"source": tid, "target": t} for t in direct]
            if len(direct) == 1:
                ans = f"「{tid}」的直接下游（1 跳）表为：{direct[0]}。"
            elif direct:
                ans = f"「{tid}」的直接下游（1 跳）共 {len(direct)} 张表：{', '.join(direct[:25])}" + (
                    " 等。" if len(direct) > 25 else "。"
                )
            else:
                ans = (
                    f"在当前图谱的解析结果中，「{tid}」没有出边（无直接下游表）。"
                    f"若该表在画布上应有下游，请确认层级筛选未隐藏目标表。"
                )
            return {
                "answer": ans,
                "intent": "downstream_trace",
                "intent_label": "下游溯源",
                "confidence": 0.92,
                "highlight": {"node_ids": hl_nodes[:200], "links": hl_links[:200]},
                "matches": [],
            }

        if want_ads:
            layer_list = sorted([x for x in down if is_ads(x) and x != tid])
        else:
            layer_list = sorted([x for x in down if x != tid])
        hl_nodes = [tid] + layer_list
        hl_links = []
        for e in links:
            s, t = e.get("source"), e.get("target")
            if not s or not t:
                continue
            if s in down and t in down:
                hl_links.append({"source": s, "target": t})
        other_cnt = max(0, len(down) - 1)
        ans = f"从「{tid}」沿数据流向下游追溯，可达 {other_cnt} 张其它表（含多跳，去重后统计）。"
        if want_ads:
            ans += f" 其中 ADS 层共 {len(layer_list)} 张。"
            if layer_list:
                ans += f" 例如：{', '.join(layer_list[:10])}" + (" 等。" if len(layer_list) > 10 else "。")
        else:
            if layer_list:
                ans += f" 下游表节选：{', '.join(layer_list[:15])}" + (" 等。" if len(layer_list) > 15 else "。")
            else:
                ans += " 当前未解析到除自身外的下游表。"
        return {
            "answer": ans,
            "intent": "downstream_trace",
            "intent_label": "下游溯源",
            "confidence": 0.9,
            "highlight": {"node_ids": hl_nodes[:200], "links": hl_links[:800]},
            "matches": [],
        }

    # ---------- 上游溯源（默认）----------
    if intent == "upstream_trace" or intent == "unknown":
        tid = _resolve_table_name(q, node_ids_list)
        if not tid:
            # 再试模糊（用去口语后的短句，避免整句与表名算相似度）
            fuzzy = _fuzzy_matches(_strip_question_noise(q) or q, nodes, 3)
            if len(fuzzy) == 1:
                tid = fuzzy[0]["id"]
            elif fuzzy:
                return {
                    "answer": "请明确表名。候选：" + "、".join(f['name'] for f in fuzzy[:5]),
                    "intent": "upstream_trace",
                    "intent_label": "上游溯源",
                    "confidence": fuzzy[0]["score"],
                    "highlight": empty_highlight,
                    "matches": fuzzy,
                }
            else:
                return {
                    "answer": (
                        "未能识别表名。你可以问：\n"
                        "• 某 ADS 表依赖哪些 ODS 表\n"
                        "• 修改某 DWD 表会影响哪些 ADS 表\n"
                        "• 从 ODS 到 ADS 的数据链路\n"
                        "• 包含某关键词的表有哪些"
                    ),
                    "intent": "unknown",
                    "intent_label": "未知",
                    "confidence": 0.2,
                    "highlight": empty_highlight,
                    "matches": [],
                }

        up = _upstream_all(tid, pred)
        qlow = q.lower()
        want_ods = "ods" in qlow or "贴源" in q
        want_dwd = "dwd" in qlow or "dws" in qlow
        ods_set = sorted([x for x in up if is_ods(x) and x != tid])
        dwd_set = sorted([x for x in up if is_dwd(x) and x != tid])

        hl_nodes = [tid] + ods_set + dwd_set
        hl_links = []
        for e in links:
            s, t = e.get("source"), e.get("target")
            if not s or not t:
                continue
            if t in up and s in up:
                hl_links.append({"source": s, "target": t})

        if want_ods and not want_dwd:
            ans = (
                f"「{tid}」的上游中，ODS 层共 {len(ods_set)} 张表"
                f"（多跳血缘汇总）。"
            )
            if ods_set:
                ans += f" 包括：{', '.join(ods_set[:10])}" + (" 等。" if len(ods_set) > 10 else "。")
            else:
                ans += " 未发现 ods_ 前缀的上游表。"
            hl_nodes = [tid] + ods_set
        elif want_dwd:
            ans = f"「{tid}」的上游中，DWD/DWS 层共 {len(dwd_set)} 张表。"
            if dwd_set:
                ans += f" 例如：{', '.join(dwd_set[:10])}" + (" 等。" if len(dwd_set) > 10 else "。")
            hl_nodes = [tid] + dwd_set
        else:
            ans = (
                f"「{tid}」依赖的上游表中：约 {len(ods_set)} 张 ODS 表、{len(dwd_set)} 张 DWD/DWS 表"
                f"（均按表名前缀统计，含多跳血缘）。"
            )

        return {
            "answer": ans,
            "intent": "upstream_trace",
            "intent_label": "上游溯源",
            "confidence": 0.93,
            "highlight": {
                "node_ids": list(dict.fromkeys(hl_nodes))[:200],
                "links": hl_links[:800],
            },
            "matches": [],
        }

    return {
        "answer": "暂无法处理该问题。",
        "intent": "unknown",
        "intent_label": "未知",
        "confidence": 0.0,
        "highlight": empty_highlight,
        "matches": [],
    }
