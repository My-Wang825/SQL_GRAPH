---
name: sql-knowledge-graph
description: >-
  基于 ETL 脚本（INSERT INTO … SELECT … FROM/JOIN）构建表级 SQL 知识图谱，产出 DATA_FLOW 边、
  可选按板块（sector）划分的数据目录、FastAPI JSON 接口与 D3 力导向前端。
  适用于搭建数仓血缘、将 SQL-graph 规范迁移到其他仓库、批量解析 .sql/.txt 表依赖，
  或让新项目与本套约定对齐。
---

# SQL 知识图谱（可迁移规范）

本 Skill 描述一套可在**任意 Git 仓库**复用的约定：从数仓 ETL 类 SQL 批量解析**表节点**与**显式数据流边**，经后端合并为 JSON，再由前端力导向图展示。实现细节以参考实现为准；本仓库中完整代码见根目录 `backend/`、`frontend/`、`run_server.py`。

## 何时启用

- 在新仓库中按**同一套架构**搭建「SQL → 图谱 JSON → Web」流水线。
- 评审他人实现的血缘解析是否与下述**契约**一致。
- 扩展板块（多 `sector`）、合并外部血缘（如指标平台 JSON）、或增加 Agent 问答层。

## 规范总览（跨仓库不变部分）

### 1. 目录与职责

| 区域 | 建议路径 | 职责 |
|------|-----------|------|
| 后端包 | `backend/` | `parser`（ETL SQL）、`graph`（合并与 JSON）、`api`（路由与 Schema）、`config`（根目录与数据根路径） |
| 前端静态 | `frontend/` | `index.html`、板块页、`css/`、`js/app.js`；通过相对路径请求 `/api/graph` |
| SQL 数据 | `data/<SECTOR>/...` | 递归扫描；扩展名白名单见配置 |
| 启动脚本 | 项目根 `run_server.py`（可选） | 统一 uvicorn 入口、端口与访问提示 |
| 参考实现 | 本仓库根目录 | 与 `开发说明文档.md`、`README.md` 交叉对照 |

新仓库可改名，但须在 Skill 的「适配清单」中逐项替换路径与导入模块名，保持**数据流语义**与 **API 契约**不变。

### 2. 解析语义（核心）

- **输入**：UTF-8 文本的 `.sql` / `.txt`（可配置扩展名）。
- **表名**：物理表出现在 `INSERT INTO` 目标、`TRUNCATE`/`DELETE FROM` 目标、`FROM`/`JOIN` 中；**规范化**为短表名（去掉 schema，如 `sdhq.fact` → `fact`）。
- **边类型（主路径）**：在同一 `INSERT INTO 目标 … SELECT …` 语句上下文中，凡 `FROM`/`JOIN` 解析到的**源表** → **该 INSERT 目标表**，关系类型为 **`DATA_FLOW`**。不依赖传递闭包补边、不删除「共父」边（与脚本显式出现一致）。
- **表注释**：优先从文件头注释中匹配「描述：」类文案（实现见参考解析器）。

### 3. 图谱 JSON 契约（前后端对齐）

HTTP 响应体顶层：

- `nodes`：对象数组，至少含 `id`、`name`、`tableType`、`comment`、`relationCount` 等（完整字段见同目录 `reference.md`）。
- `links`：对象数组，`source` / `target` 为**与节点 `id` 一致的字符串**；含 `relationType`（主为 `DATA_FLOW`）、`weight`、`sources`、`isTransitive` 等。
- `meta`：对象，含 `version`、`tableCount`、`relationCount`；合并外部血缘后可附加自定义统计字段。

前端用 `body.dataset.sector`（或等价方式）选择板块，请求：

`GET /api/graph?sector=<CODE>`（`sector` 为空时使用配置的默认板块）。

### 4. 后端构建顺序（须在其它仓库保持一致）

1. 将 `sector` / `data_dir` 解析为**磁盘上的数据目录**；`data_dir` 若支持自定义，应限制在**项目根目录内**（防路径穿越）。
2. 递归收集 SQL 文件列表。
3. 对每个文件：`parse_file` → `(tables, relations, …)`；单文件失败记录日志并跳过。
4. 累积到 `GraphBuilder`：`add_tables_from_parse`、`add_relations_from_parse`。
5. `to_vis_json()`：按 `(source, target)` 去重，累加 `weight`、合并 `sources`，计算节点 `relationCount`。
6. （可选）按业务规则对 payload 做二次合并（例如仅某 sector 合并指标 JSON）。
7. （可选）短期内存缓存，TTL 与绕过策略（如 POST build 强制重算）需文档化。

### 5. API 最小集

| 方法 | 路径 | 用途 |
|------|------|------|
| GET | `/health` | 存活探测 |
| GET | `/api/graph` | 返回 `GraphResponse` |
| POST | `/api/graph/build` | 指定目录重建（建议禁用缓存） |

扩展接口（指标摘要、Agent 流式问答等）见 `reference.md`，新仓库可按需裁剪。

### 6. 前端最小约定

- 使用 D3（或等价库）做力导向；从 `/api/graph?sector=…` 拉取 JSON。
- 层级筛选、搜索、血缘高亮等行为与**节点 `id` 及边的端点字符串**严格一致。
- 多板块：多入口 HTML，通过 `data-sector` 区分请求参数。

### 7. 配置与环境变量

- **路径**：项目根、`DATA_DIR`、板块代码 → 目录映射表（白名单）。
- **解析器**：默认 schema、是否规范化表名等，集中在单一配置模块。
- **密钥类**：仅通过环境变量或 `.env`（勿提交仓库）。参考键名见仓库根目录 `.env.example`；复制到新仓库时勿保留真实密钥。

### 8. 依赖（Python）

与参考实现对齐时至少包含：`fastapi`、`uvicorn`、`pydantic`、`python-dotenv`；若启用 OpenAI 兼容客户端、Excel 处理等，再增加对应包（见根目录 `requirements.txt`）。

## 在新仓库落地的操作顺序

1. 建立 `backend/`、`frontend/`、`data/<板块>/` 骨架，复制或重写解析器与 `GraphBuilder`，保证 **JSON 契约**与前端一致。
2. 实现 `config`：`BASE_DIR`、板块映射、`SQL_EXTENSIONS`。
3. 注册 FastAPI 路由：`/` 返回首页 HTML；**先**注册显式路由（`/health`、`/api/*`），**再**挂载静态根路径，避免静态文件抢掉 API。
4. 放置样例 SQL，调用 `GET /api/graph` 验证节点与边数量。
5. 再按需加指标合并、Agent、缓存。

## 本仓库内延伸阅读

- `开发说明文档.md`：端到端流程与附录清单。
- `README.md`：模块表、布局说明、启动与排障。
- `sql-knowledge-graph-prompt.md`：原始需求文档；**其中部分能力与当前实现不一致**，以代码与上述契约为准。
- `reference.md`（本 Skill 目录）：字段表、可选模块、参考文件路径。
- `examples.md`（本 Skill 目录）：最小 SQL 与响应片段示例。

## 注意事项

- 不要将含真实密钥的 `.env` 提交 Git。
- 大体积血缘原始 JSON 适合留在 `exports/` 或 CI 产物，不必嵌入 Skill 正文。
- 子查询别名、非物理表 token 须在解析器中过滤，避免伪节点污染图谱。
