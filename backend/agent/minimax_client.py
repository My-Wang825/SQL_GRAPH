# -*- coding: utf-8 -*-
"""
MiniMax 文本模型（OpenAI 兼容接口）：基于图谱上下文生成最终问答回答。
API Key 必须通过环境变量 MINIMAX_API_KEY 配置，勿写入代码库。
"""
from __future__ import annotations

import json
import logging
import os
import re
from urllib import error, request
from typing import Any, Dict, Iterator, List, Union

logger = logging.getLogger(__name__)


def _clean_model_text(text: str) -> str:
    if not text:
        return ""
    t = text.strip()
    # 部分模型会输出思考标签，展示前去掉
    t = re.sub(r"<think>[\s\S]*?</think>", "", t, flags=re.I)
    t = re.sub(r"<thinking>[\s\S]*?</thinking>", "", t, flags=re.I)
    return t.strip()


def _message_content_to_str(content: Union[str, List[Any], None]) -> str:
    """OpenAI 兼容 message.content：字符串或 content-parts 列表。"""
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: List[str] = []
        for block in content:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "text":
                t = block.get("text")
                if isinstance(t, str):
                    parts.append(t)
            elif isinstance(block.get("text"), str):
                parts.append(block["text"])
        return "".join(parts)
    return str(content)


def _delta_text_chunk(delta: Dict[str, Any]) -> str:
    """
    从流式 choices[].delta 提取可见文本。
    兼容：标准 content、多模态 content 数组、reasoning_content、MiniMax reasoning_details。
    """
    if not isinstance(delta, dict):
        return ""
    out: List[str] = []
    c = delta.get("content")
    if isinstance(c, str) and c:
        out.append(c)
    elif isinstance(c, list):
        out.append(_message_content_to_str(c))
    rc = delta.get("reasoning_content")
    if isinstance(rc, str) and rc.strip():
        out.append(rc)
    rd = delta.get("reasoning_details")
    if isinstance(rd, list):
        for item in rd:
            if isinstance(item, dict):
                tx = item.get("text")
                if isinstance(tx, str) and tx:
                    out.append(tx)
    return "".join(out)


def _call_minimax_openai_compatible(
    *,
    api_key: str,
    base_url: str,
    model: str,
    system: str,
    user_payload: str,
    timeout_sec: float,
) -> str:
    """
    直接调用 MiniMax OpenAI 兼容接口，显式带 Authorization 头，
    避免 SDK/代理层差异导致鉴权头未被正确发送。
    """
    endpoint = base_url.rstrip("/") + "/chat/completions"
    body = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user_payload},
        ],
        "temperature": 0.3,
        "max_tokens": 2048,
    }
    payload = json.dumps(body).encode("utf-8")
    req = request.Request(
        endpoint,
        data=payload,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
    )
    try:
        with request.urlopen(req, timeout=timeout_sec) as resp:
            data = json.loads(resp.read().decode("utf-8", errors="ignore") or "{}")
    except error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"HTTP {e.code}: {detail}") from e
    except Exception as e:
        raise RuntimeError(str(e)) from e

    choices = data.get("choices") or []
    if not choices:
        raise RuntimeError(f"MiniMax 返回缺少 choices: {data}")
    message = choices[0].get("message") or {}
    raw = _message_content_to_str(message.get("content"))
    if not (raw or "").strip():
        raw = _delta_text_chunk(message)  # 少数实现把片段放在与 delta 同形字段里
    return _clean_model_text(raw)


def _call_openai_compatible_stream(
    *,
    api_key: str,
    base_url: str,
    model: str,
    system: str,
    user_payload: str,
    timeout_sec: float,
) -> Iterator[str]:
    """
    OpenAI 兼容流式输出（SSE）：逐段返回 content delta。
    """
    endpoint = base_url.rstrip("/") + "/chat/completions"
    body = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user_payload},
        ],
        "temperature": 0.25,
        "max_tokens": 2500,
        "stream": True,
    }
    payload = json.dumps(body).encode("utf-8")
    req = request.Request(
        endpoint,
        data=payload,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
    )

    try:
        with request.urlopen(req, timeout=timeout_sec) as resp:
            for raw in resp:
                line = raw.decode("utf-8", errors="ignore").strip()
                if not line or not line.startswith("data:"):
                    continue
                data_str = line[5:].strip()
                if not data_str or data_str == "[DONE]":
                    continue
                try:
                    obj = json.loads(data_str)
                except Exception:
                    continue
                choices = obj.get("choices") or []
                if not choices:
                    continue
                ch0 = choices[0] if isinstance(choices[0], dict) else {}
                delta = ch0.get("delta") or {}
                chunk = _delta_text_chunk(delta)
                if not chunk:
                    msg = ch0.get("message") or {}
                    if isinstance(msg, dict):
                        chunk = _message_content_to_str(msg.get("content"))
                if not chunk and isinstance(ch0.get("text"), str):
                    chunk = ch0["text"]
                if chunk:
                    yield chunk
    except error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"HTTP {e.code}: {detail}") from e
    except Exception as e:
        raise RuntimeError(str(e)) from e


def _compact_node(node: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": node.get("id") or node.get("name") or "",
        "displayName": node.get("displayName") or "",
        "comment": node.get("comment") or "",
        "tableType": node.get("tableType") or "",
        "relationCount": int(node.get("relationCount") or 0),
    }


LIST_ONLY_INTENTS = {"fuzzy_search", "assoc_stats", "node_property"}
LINEAGE_INTENTS = {
    "upstream_trace",
    "downstream_trace",
    "impact_analysis",
    "path_query",
    "lineage_both",
}


def _is_list_only_question(question: str, result: Dict[str, Any]) -> bool:
    intent = (result.get("intent") or "").strip()
    q = (question or "").strip()
    if intent in LIST_ONLY_INTENTS:
        return True
    # “有哪些表 / 列出 / 查看所有” 这类问题，只给模型传匹配节点，避免被邻接边带偏
    if any(x in q for x in ("有哪些表", "哪些表", "列出", "查看所有", "都有谁", "都有什么表")):
        if intent not in LINEAGE_INTENTS:
            return True
    return False


def _select_focus_nodes(nodes: List[dict], result: Dict[str, Any]) -> List[dict]:
    node_by_id = {
        (n.get("id") or n.get("name")): n
        for n in nodes
        if (n.get("id") or n.get("name"))
    }
    selected: List[dict] = []
    seen = set()

    for nid in (result.get("highlight") or {}).get("node_ids") or []:
        if nid in node_by_id and nid not in seen:
            selected.append(node_by_id[nid])
            seen.add(nid)

    for item in result.get("matches") or []:
        nid = item.get("id")
        if nid in node_by_id and nid not in seen:
            selected.append(node_by_id[nid])
            seen.add(nid)

    if selected:
        return selected[:60]

    fallback = sorted(
        [n for n in nodes if (n.get("id") or n.get("name"))],
        key=lambda n: int(n.get("relationCount") or 0),
        reverse=True,
    )
    return fallback[:20]


def _select_focus_links(links: List[dict], focus_nodes: List[dict], result: Dict[str, Any]) -> List[dict]:
    focus_ids = {
        (n.get("id") or n.get("name"))
        for n in focus_nodes
        if (n.get("id") or n.get("name"))
    }
    hl_pairs = {
        ((e.get("source") or ""), (e.get("target") or ""))
        for e in ((result.get("highlight") or {}).get("links") or [])
        if e.get("source") and e.get("target")
    }

    selected: List[dict] = []
    seen = set()
    if hl_pairs:
        for link in links:
            pair = (link.get("source") or "", link.get("target") or "")
            if pair in hl_pairs and pair not in seen:
                selected.append(link)
                seen.add(pair)
        if selected:
            return selected[:160]

    for link in links:
        src, tgt = link.get("source"), link.get("target")
        if src in focus_ids or tgt in focus_ids:
            pair = (src or "", tgt or "")
            if pair not in seen:
                selected.append(link)
                seen.add(pair)
    return selected[:160]


def _select_neighbor_nodes(nodes: List[dict], focus_links: List[dict], focus_nodes: List[dict]) -> List[dict]:
    node_by_id = {
        (n.get("id") or n.get("name")): n
        for n in nodes
        if (n.get("id") or n.get("name"))
    }
    focus_ids = {
        (n.get("id") or n.get("name"))
        for n in focus_nodes
        if (n.get("id") or n.get("name"))
    }
    neighbor_ids = []
    seen = set()
    for l in focus_links:
        for nid in (l.get("source") or "", l.get("target") or ""):
            if nid and nid not in focus_ids and nid in node_by_id and nid not in seen:
                neighbor_ids.append(nid)
                seen.add(nid)
    return [node_by_id[nid] for nid in neighbor_ids[:60]]


def _build_graph_context(question: str, nodes: List[dict], links: List[dict], result: Dict[str, Any]) -> str:
    focus_nodes = _select_focus_nodes(nodes, result)
    list_only = _is_list_only_question(question, result)
    focus_links = [] if list_only else _select_focus_links(links, focus_nodes, result)
    neighbor_nodes = [] if list_only else _select_neighbor_nodes(nodes, focus_links, focus_nodes)

    payload = {
        "question": question,
        "context_mode": "matched_nodes_only" if list_only else "lineage_subgraph",
        "graph_meta": {
            "node_count": len(nodes),
            "link_count": len(links),
        },
        "rule_engine_reference": {
            "intent": result.get("intent"),
            "intent_label": result.get("intent_label"),
            "confidence": float(result.get("confidence") or 0),
            "answer": result.get("answer") or "",
        },
        "focus_nodes": [_compact_node(n) for n in focus_nodes],
        "neighbor_nodes": [_compact_node(n) for n in neighbor_nodes],
        "focus_links": [
            {
                "source": l.get("source") or "",
                "target": l.get("target") or "",
                "relationType": l.get("relationType") or l.get("relation_type") or "DATA_FLOW",
                "weight": int(l.get("weight") or 1),
            }
            for l in focus_links
        ],
    }
    return json.dumps(payload, ensure_ascii=False, indent=2)


def answer_with_graph_context(
    question: str,
    nodes: List[dict],
    links: List[dict],
    result: Dict[str, Any],
    *,
    api_key: str,
    base_url: str,
    model: str,
    timeout_sec: float = 90.0,
) -> Dict[str, Any]:
    """
    基于图谱上下文 + 规则引擎定位结果，调用 MiniMax 生成最终用户可见回答。
    不改变 intent / highlight / matches（仍以本地规则/图遍历结果为准）。
    """
    graph_context = _build_graph_context(question, nodes, links, result)
    if not graph_context.strip():
        return result

    system = (
        "你是数据仓库血缘图谱智能问答助手。"
        "你将收到一个由程序从当前图谱中提取的结构化上下文。"
        "你必须严格基于这些上下文回答，不得编造不存在的表、边、层级关系或统计值。"
        "如果上下文不足以支撑结论，要明确说明“当前图谱上下文不足以确认”。"
        "回答使用简体中文，可使用简洁 Markdown。"
        "优先直接回答用户问题，再补充 1-3 条依据。"
        "若 context_mode=matched_nodes_only，则只能根据匹配节点列表作答，不得把邻接表、上下游表写进答案。"
        "若 context_mode=lineage_subgraph，则可以结合 focus_links 与 neighbor_nodes 解释血缘关系。"
    )
    user_payload = (
        "请根据下面知识图谱上下文回答用户问题。\n\n"
        f"{graph_context}\n\n"
        "要求：\n"
        "1. 先直接给出结论。\n"
        "2. 若是路径/上下游/影响分析，优先引用上下文中的节点名与边方向。\n"
        "3. 不要输出你的思考过程。\n"
        "4. 不要超出上下文臆断。"
    )

    try:
        answered = _call_minimax_openai_compatible(
            api_key=api_key,
            base_url=base_url,
            model=model,
            system=system,
            user_payload=user_payload,
            timeout_sec=timeout_sec,
        )
        if answered:
            out = dict(result)
            out["answer"] = answered
            return out
    except Exception as e:
        logger.warning("MiniMax 调用失败，使用规则原文: %s", e)

    return result


def _safe_float(v: Any, default: float = 0.0) -> float:
    try:
        return float(v)
    except Exception:
        return default


def _clamp_confidence(v: Any) -> float:
    x = _safe_float(v, 0.0)
    if x < 0:
        return 0.0
    if x > 1:
        return 1.0
    return x


def _extract_json_object(text: str) -> Optional[Dict[str, Any]]:
    raw = _clean_model_text(text or "").strip()
    if not raw:
        return None
    if raw.startswith("```"):
        raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.I)
        raw = re.sub(r"\s*```$", "", raw)
    try:
        obj = json.loads(raw)
        if isinstance(obj, dict):
            return obj
    except Exception:
        pass
    m = re.search(r"\{[\s\S]*\}", raw)
    if not m:
        return None
    try:
        obj = json.loads(m.group(0))
        if isinstance(obj, dict):
            return obj
    except Exception:
        return None
    return None


def _question_terms(question: str) -> List[str]:
    q = (question or "").strip()
    seen = set()
    terms: List[str] = []
    for tok in re.findall(r"\b[a-zA-Z][a-zA-Z0-9_]{1,}\b", q):
        low = tok.lower()
        if low not in seen:
            seen.add(low)
            terms.append(low)
    for tok in re.findall(r"[\u4e00-\u9fff]{2,}", q):
        if tok not in seen:
            seen.add(tok)
            terms.append(tok)
    return terms


def _score_node_for_question(node: Dict[str, Any], question: str, terms: List[str]) -> float:
    name = str(node.get("name") or node.get("id") or "")
    disp = str(node.get("displayName") or "")
    comment = str(node.get("comment") or "")
    blob = " ".join([name, disp, comment]).lower()
    question_low = (question or "").lower()
    score = 0.0
    if name and name.lower() in question_low:
        score += 10.0
    for term in terms:
        term_low = term.lower()
        if not term_low:
            continue
        if term_low == name.lower():
            score += 9.0
        elif term_low in name.lower():
            score += 6.0
        elif term_low in disp.lower():
            score += 3.0
        elif term_low in comment.lower():
            score += 2.5
    score += min(_safe_float(node.get("relationCount"), 0.0), 20.0) * 0.02
    if not terms and blob:
        score += 0.1
    return score


def _compact_node_for_agent(node: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": node.get("id") or node.get("name") or "",
        "name": node.get("name") or node.get("id") or "",
        "displayName": node.get("displayName") or "",
        "comment": node.get("comment") or "",
        "filePath": node.get("filePath") or "",
        "tableType": node.get("tableType") or "",
        "relationCount": int(node.get("relationCount") or 0),
    }


def _select_focus_nodes_for_agent(question: str, nodes: List[dict], limit: int = 12) -> List[dict]:
    terms = _question_terms(question)
    scored: List[Tuple[float, dict]] = []
    for node in nodes:
        s = _score_node_for_question(node, question, terms)
        if s > 0:
            scored.append((s, node))
    if not scored:
        fallback = sorted(
            nodes,
            key=lambda n: int(n.get("relationCount") or 0),
            reverse=True,
        )
        return fallback[: min(limit, 8)]
    scored.sort(key=lambda x: (-x[0], str(x[1].get("name") or x[1].get("id") or "")))
    return [n for _, n in scored[:limit]]


def _select_focus_links_for_agent(links: List[dict], focus_ids: List[str], limit: int = 80) -> List[dict]:
    focus = set(focus_ids)
    scored: List[Tuple[int, dict]] = []
    for link in links:
        s = link.get("source") or ""
        t = link.get("target") or ""
        both = int(s in focus and t in focus)
        one = int(s in focus or t in focus)
        if not one:
            continue
        scored.append((both * 10 + one, link))
    scored.sort(
        key=lambda x: (
            -x[0],
            -(int(x[1].get("weight") or 1)),
            str(x[1].get("source") or ""),
            str(x[1].get("target") or ""),
        )
    )
    return [l for _, l in scored[:limit]]


def _select_neighbor_nodes_for_agent(nodes: List[dict], focus_links: List[dict], focus_ids: List[str], limit: int = 30) -> List[dict]:
    node_by_id = {
        (n.get("id") or n.get("name")): n
        for n in nodes
        if (n.get("id") or n.get("name"))
    }
    focus_set = set(focus_ids)
    out: List[dict] = []
    seen = set()
    for link in focus_links:
        for nid in (link.get("source") or "", link.get("target") or ""):
            if not nid or nid in focus_set or nid in seen or nid not in node_by_id:
                continue
            out.append(node_by_id[nid])
            seen.add(nid)
            if len(out) >= limit:
                return out
    return out


def _candidate_file_paths(focus_nodes: List[dict], focus_links: List[dict], limit: int = 6) -> List[str]:
    out: List[str] = []
    seen = set()
    for node in focus_nodes:
        fp = str(node.get("filePath") or "").strip()
        if fp and fp not in seen:
            out.append(fp)
            seen.add(fp)
    for link in focus_links:
        for fp in link.get("sources") or []:
            p = str(fp or "").strip()
            if p and p not in seen:
                out.append(p)
                seen.add(p)
            if len(out) >= limit:
                return out
    return out[:limit]


def _read_text_file(path: str) -> str:
    for enc in ("utf-8", "utf-8-sig", "gb18030", "gbk"):
        try:
            with open(path, "r", encoding=enc) as f:
                return f.read()
        except UnicodeDecodeError:
            continue
        except OSError:
            return ""
    try:
        with open(path, "r", encoding="latin-1", errors="ignore") as f:
            return f.read()
    except OSError:
        return ""


def _best_matching_window(text: str, terms: List[str], max_chars: int = 2200) -> str:
    clean = text or ""
    if not clean:
        return ""
    low = clean.lower()
    best_idx = -1
    for term in terms:
        tl = term.lower()
        if not tl:
            continue
        idx = low.find(tl)
        if idx >= 0:
            best_idx = idx
            break
    if best_idx < 0:
        return clean[:max_chars]
    start = max(0, best_idx - max_chars // 3)
    end = min(len(clean), start + max_chars)
    return clean[start:end]


def _read_file_snippets(paths: List[str], question: str, limit: int = 6) -> List[Dict[str, str]]:
    snippets: List[Dict[str, str]] = []
    terms = _question_terms(question)
    for path in paths:
        if len(snippets) >= limit:
            break
        p = os.path.abspath(path)
        if not os.path.isfile(p):
            continue
        text = _read_text_file(p)
        if not text.strip():
            continue
        excerpt = _best_matching_window(text, terms, 3200).strip()
        if not excerpt:
            continue
        snippets.append({
            "path": p,
            "excerpt": excerpt,
        })
    return snippets


def _build_agent_context(question: str, nodes: List[dict], links: List[dict]) -> Dict[str, Any]:
    focus_nodes = _select_focus_nodes_for_agent(question, nodes, 18)
    focus_ids = [(n.get("id") or n.get("name")) for n in focus_nodes if (n.get("id") or n.get("name"))]
    focus_links = _select_focus_links_for_agent(links, focus_ids, 120)
    neighbor_nodes = _select_neighbor_nodes_for_agent(nodes, focus_links, focus_ids, 40)
    file_paths = _candidate_file_paths(focus_nodes, focus_links, 8)
    file_snippets = _read_file_snippets(file_paths, question, 6)
    return {
        "question": question,
        "graph_meta": {
            "node_count": len(nodes),
            "link_count": len(links),
        },
        "focus_nodes": [_compact_node_for_agent(n) for n in focus_nodes],
        "neighbor_nodes": [_compact_node_for_agent(n) for n in neighbor_nodes],
        "focus_links": [
            {
                "source": l.get("source") or "",
                "target": l.get("target") or "",
                "relationType": l.get("relationType") or l.get("relation_type") or "DATA_FLOW",
                "weight": int(l.get("weight") or 1),
                "sources": (l.get("sources") or [])[:5],
            }
            for l in focus_links
        ],
        "file_snippets": file_snippets,
    }


def _error_result(message: str) -> Dict[str, Any]:
    return {
        "answer": message,
        "intent": "agent_answer",
        "intent_label": "智能回答",
        "confidence": 0.0,
        "highlight": {"node_ids": [], "links": []},
        "matches": [],
    }


def _fallback_payload_from_context(context: Dict[str, Any]) -> Dict[str, Any]:
    fallback_nodes = [n["id"] for n in context["focus_nodes"][:12] if n.get("id")]
    fallback_links = [
        {"source": l["source"], "target": l["target"]}
        for l in context["focus_links"][:40]
        if l.get("source") and l.get("target")
    ]
    fallback_matches = [
        {
            "id": n["id"],
            "name": n.get("name") or n["id"],
            "score": 0.66,
        }
        for n in context["focus_nodes"][:18]
        if n.get("id")
    ]
    return {
        "node_ids": fallback_nodes,
        "links": fallback_links,
        "matches": fallback_matches,
    }


def _build_agent_prompt(context: Dict[str, Any]) -> Dict[str, str]:
    system = (
        "你是数据仓库知识图谱智能问答 Agent。"
        "你必须只基于提供给你的知识图谱节点、关系边和 SQL 文件片段回答。"
        "你不能假设任何未在上下文出现的表、字段、路径或血缘关系。"
        "如果上下文不足，请明确说“当前图谱与文件上下文不足以确认”。"
        "请输出严格 JSON，不要输出 Markdown 代码块，不要输出额外解释。"
    )
    user_payload = json.dumps(
        {
            "instruction": {
                "task": "基于知识图谱和 SQL 文件片段回答问题，并给出可用于前端高亮的节点/边。",
                "output_schema": {
                    "answer": "string",
                    "intent": "string",
                    "intent_label": "string",
                    "confidence": "0~1 float",
                    "highlight": {
                        "node_ids": ["node id"],
                        "links": [{"source": "node id", "target": "node id"}],
                    },
                    "matches": [{"id": "node id", "name": "table name", "score": "0~1 float"}],
                },
                "requirements": [
                    "answer 用简体中文，先直接结论，再给至少 3 条可追溯依据（节点/关系/文件片段）。",
                    "优先给出结构化业务信息：统计值、关键节点、关键关系方向。",
                    "highlight.node_ids 和 matches.id 必须来自上下文中的真实节点 id。",
                    "highlight.links 必须来自上下文中的真实 source/target 关系。",
                    "如果问题是在找表，可列出相关表；如果是在问血缘，就依据 focus_links 和 file_snippets 解释。",
                    "如果无法确认，不要编造。",
                ],
            },
            "context": context,
        },
        ensure_ascii=False,
    )
    return {"system": system, "user_payload": user_payload}


def _build_stream_prompt(context: Dict[str, Any]) -> Dict[str, str]:
    system = (
        "你是数据仓库知识图谱智能问答助手。"
        "必须严格基于提供的图谱上下文回答。"
        "先给结论，再给依据，回答要详细且可读。"
        "不要输出 JSON。"
    )
    user_payload = json.dumps(
        {
            "task": "请输出可直接展示给业务用户的最终答案（Markdown）。",
            "style": {
                "format": "先结论，后依据",
                "details": "至少包含：关键统计、关键节点、关键关系方向、必要时列出表名",
                "traceability": "每条依据尽量引用 node id 或 source->target",
            },
            "context": context,
        },
        ensure_ascii=False,
    )
    return {"system": system, "user_payload": user_payload}


def answer_with_graph_and_files(
    question: str,
    nodes: List[dict],
    links: List[dict],
    *,
    api_key: str,
    base_url: str,
    model: str,
    timeout_sec: float = 90.0,
) -> Dict[str, Any]:
    """
    仅通过模型 + 知识图谱 + data 中 SQL 文件片段回答，不回退到本地规则引擎。
    """
    if not (api_key or "").strip():
        return _error_result("未配置智能回答模型：请先设置环境变量 `LLM_API_KEY`（或 `OPENAI_API_KEY`），Agent 才能基于图谱与 SQL 文件回答。")

    context = _build_agent_context(question, nodes, links)
    if not context["focus_nodes"] and not context["file_snippets"]:
        return _error_result("当前图谱中没有可用于回答的问题上下文，无法生成智能回答。")

    node_ids = {
        (n.get("id") or n.get("name"))
        for n in nodes
        if (n.get("id") or n.get("name"))
    }
    valid_pairs = {
        ((l.get("source") or ""), (l.get("target") or ""))
        for l in links
        if (l.get("source") or "") and (l.get("target") or "")
    }

    prompt = _build_agent_prompt(context)

    try:
        content = _call_minimax_openai_compatible(
            api_key=api_key,
            base_url=base_url,
            model=model,
            system=prompt["system"],
            user_payload=prompt["user_payload"],
            timeout_sec=timeout_sec,
        )
    except Exception as e:
        logger.warning("智能回答模型调用失败: %s", e)
        return _error_result(f"智能回答模型调用失败：{e}")
    parsed = _extract_json_object(content)
    fallback = _fallback_payload_from_context(context)
    fallback_nodes = fallback["node_ids"]
    fallback_links = fallback["links"]
    fallback_matches = fallback["matches"]

    if not parsed:
        answered = _clean_model_text(content)
        if answered:
            return {
                "answer": answered,
                "intent": "agent_answer",
                "intent_label": "智能回答",
                "confidence": 0.55,
                "highlight": {"node_ids": fallback_nodes, "links": fallback_links},
                "matches": fallback_matches,
            }
        return _error_result("智能回答模型返回内容不可解析，无法生成有效回答。")

    answer = str(parsed.get("answer") or "").strip()
    if not answer:
        return _error_result("智能回答模型未返回有效答案。")

    hl = parsed.get("highlight") or {}
    node_ids_out = []
    for nid in hl.get("node_ids") or []:
        sid = str(nid or "").strip()
        if sid and sid in node_ids and sid not in node_ids_out:
            node_ids_out.append(sid)
    if not node_ids_out:
        node_ids_out = fallback_nodes

    links_out = []
    seen_pairs = set()
    for e in hl.get("links") or []:
        s = str((e or {}).get("source") or "").strip()
        t = str((e or {}).get("target") or "").strip()
        if not s or not t or (s, t) not in valid_pairs or (s, t) in seen_pairs:
            continue
        links_out.append({"source": s, "target": t})
        seen_pairs.add((s, t))
    if not links_out:
        links_out = fallback_links

    matches_out = []
    seen_match_ids = set()
    for item in parsed.get("matches") or []:
        nid = str((item or {}).get("id") or "").strip()
        if not nid or nid not in node_ids or nid in seen_match_ids:
            continue
        matches_out.append({
            "id": nid,
            "name": str((item or {}).get("name") or nid),
            "score": _clamp_confidence((item or {}).get("score")),
        })
        seen_match_ids.add(nid)
    if not matches_out:
        matches_out = fallback_matches

    return {
        "answer": answer,
        "intent": str(parsed.get("intent") or "agent_answer"),
        "intent_label": str(parsed.get("intent_label") or "智能回答"),
        "confidence": _clamp_confidence(parsed.get("confidence")),
        "highlight": {"node_ids": node_ids_out[:30], "links": links_out[:80]},
        "matches": matches_out[:30],
    }


def stream_answer_with_graph_and_files(
    question: str,
    nodes: List[dict],
    links: List[dict],
    *,
    api_key: str,
    base_url: str,
    model: str,
    timeout_sec: float = 90.0,
) -> Iterator[Dict[str, Any]]:
    """
    流式回答：先持续输出 answer 文本，再在结束时输出 highlight/meta。
    """
    if not (api_key or "").strip():
        yield {"type": "error", "message": "未配置智能回答模型（缺少 API Key）"}
        return

    context = _build_agent_context(question, nodes, links)
    if not context["focus_nodes"] and not context["file_snippets"]:
        yield {"type": "error", "message": "当前图谱中没有可用于回答的问题上下文。"}
        return

    fallback = _fallback_payload_from_context(context)
    prompt = _build_stream_prompt(context)
    yield {"type": "meta", "intent": "agent_answer", "intent_label": "智能回答", "confidence": 0.7}

    chunks: List[str] = []
    try:
        for delta in _call_openai_compatible_stream(
            api_key=api_key,
            base_url=base_url,
            model=model,
            system=prompt["system"],
            user_payload=prompt["user_payload"],
            timeout_sec=timeout_sec,
        ):
            chunks.append(delta)
            yield {"type": "delta", "text": delta}
    except Exception as e:
        yield {"type": "error", "message": f"智能回答模型调用失败：{e}"}
        return

    answer = _clean_model_text("".join(chunks))
    if not answer:
        # 部分厂商流式仅填充 reasoning_details / 或非标准分片，回退一次非流式补全
        try:
            answer = _call_minimax_openai_compatible(
                api_key=api_key,
                base_url=base_url,
                model=model,
                system=prompt["system"],
                user_payload=prompt["user_payload"],
                timeout_sec=timeout_sec,
            )
            answer = _clean_model_text(answer)
        except Exception as e:
            logger.warning("智能回答流式无文本，非流式回退失败: %s", e)
            yield {
                "type": "error",
                "message": f"模型未返回有效内容（流式解析为空且非流式回退失败：{e}）。",
            }
            return
    if not answer:
        yield {"type": "error", "message": "模型未返回有效内容。"}
        return

    yield {
        "type": "done",
        "answer": answer,
        "intent": "agent_answer",
        "intent_label": "智能回答",
        "confidence": 0.78,
        "highlight": {
            "node_ids": fallback["node_ids"][:30],
            "links": fallback["links"][:80],
        },
        "matches": fallback["matches"][:30],
    }
