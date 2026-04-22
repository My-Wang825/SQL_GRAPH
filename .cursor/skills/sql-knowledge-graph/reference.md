# SQL 知识图谱 — 参考说明

本文档补充 `SKILL.md` 的字段细节与可选模块，便于在其它仓库对照实现。

## 1. 节点（`nodes[]`）常用字段

参考 `backend/models/table_node.py` 的 `to_dict()` 输出：

| JSON 字段 | 说明 |
|-------------|------|
| `id` | 与边 `source`/`target` 一致，一般为短表名 |
| `name` | 表名（常与 `id` 相同） |
| `displayName` | 展示用，缺省同 `name` |
| `schema` | 可选，库/schema 名 |
| `comment` | 业务描述 |
| `filePath` | 首次出现的 SQL 路径（若有） |
| `fieldCount` | 字段数（ETL 主路径可为 0） |
| `fields` | 字段列表（可选） |
| `tableType` | 如 `core`、`dictionary`、`junction`、`temp`、`view`；前端可能按**表名前缀**再做分层 |
| `relationCount` | 合并后与该表相连的边数（实现定义） |
| `level` / `importance` / `tags` | 扩展占位 |

指标合并后可能出现额外字段（如 `metricsSameAsDataset`），前端应对未知字段保持兼容。

## 2. 边（`links[]`）常用字段

参考 `backend/models/relation_edge.py` 映射到 JSON 的驼峰命名：

| JSON 字段 | 说明 |
|-------------|------|
| `source` / `target` | 表节点 `id` |
| `relationType` | 主路径为 `DATA_FLOW`；合并指标后可能出现 `METRICS_DATASET` 等 |
| `sourceColumn` / `targetColumn` | JOIN/血缘列（可为空） |
| `strength` / `confidence` / `reason` | 强度、置信度、可读原因 |
| `weight` | 同向边合并后的出现次数 |
| `sources` | 来源文件路径列表 |
| `isTransitive` | 当前主路径输出可为固定 `false` |

## 3. `meta` 对象

至少包含：

- `version`：图谱结构版本字符串
- `tableCount` / `relationCount`：节点数与边数

指标合并参考实现会在 `meta` 中写入 `metricsMerge` 子对象（路径、新增边数、跳过数等），其它仓库可沿用或删减。

## 4. 板块（sector）与数据目录

参考 `backend/config.py`：

- `SECTOR_DATA_DIRS`：`dict`，键为大写板块代码（如 `PRD_AL`），值为绝对路径。
- `GET /api/graph`：`sector` 优先于自定义 `data_dir`；二者解析逻辑在 `backend/api/routes.py` 的 `_resolve_graph_dir`。
- 指标治理合并：参考 `should_apply_metrics_merge_for_sector`，仅对指定板块启用（参考实现中 `PRD_AO` 不合并）。

新仓库可只保留一个默认板块，但仍建议保留 `?sector=` 参数以便扩展。

## 5. 可选模块与参考文件（本仓库路径）

| 能力 | 主要文件 |
|------|-----------|
| ETL 解析 | `backend/parser/etl_sql_parser.py` |
| 图谱合并输出 | `backend/graph/graph_builder.py` |
| 指标血缘并入 | `backend/graph/metrics_governance_merge.py` |
| API 与缓存 | `backend/api/routes.py` |
| Pydantic 模型 | `backend/api/schemas.py` |
| 指标 HTTP 客户端 | `backend/metrics/*.py` |
| Agent 问答 | `backend/agent/minimax_client.py`、`qa_engine.py` |
| 前端 | `frontend/js/app.js`、`frontend/index.html`、`frontend/ao.html` |
| 离线脚本 | `scripts/metrics_lineage_to_excel.py`、`scripts/filter_lineage_vertex_types.py` |
| 合并用 JSON 示例 | `exports/metrics_lineage_test/lineage_for_governance_merge.json` |

## 6. 与 `sql-knowledge-graph-prompt.md` 的关系

该提示词描述更广的能力（多方言 CREATE TABLE、外键推理、字段级节点等）。**本 Skill 与参考实现聚焦 ETL 表级 DATA_FLOW**。在新仓库若按提示词扩展，应在文档中明确与「本契约」的差异，避免前后端字段不一致。
