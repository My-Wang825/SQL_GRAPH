# SQL 知识图谱系统

基于数据集 `data` 与《sql-knowledge-graph-prompt.md》规格开发的 SQL 知识图谱系统。系统自动解析 SQL 脚本（支持 ETL 风格的 INSERT/SELECT/JOIN），提取表与表之间的数据流与 JOIN 关系，并以前端力导向图方式展示与查询。

## 应用启动步骤

### 1. 环境要求

- Python 3.8+
- 现代浏览器（Chrome / Edge / Firefox）

### 2. 安装依赖

在项目根目录执行：

```bash
pip install -r requirements.txt
```

### 3. 启动服务

在项目根目录（`SQL-graph2`）下执行：

```bash
python run_server.py
```

开发调试（自动热更新）：

```bash
python run_server.py --reload
```

如需手动使用 uvicorn，建议优先使用本机回环地址（更少触发 Windows 端口权限问题）：
启动服务：
```bash
python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
```
联调：
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080
### 4. 访问应用

**务必在项目根目录 `SQL-graph2` 下执行启动命令**（否则可能找不到 `frontend` 和 `data` 目录）。

浏览器打开：

- 前端页面：<http://localhost:8000/>
- 健康检查：<http://localhost:8000/health>
- 图谱数据 API：<http://localhost:8000/api/graph>

启动后前端会自动请求 `/api/graph` 获取图谱并渲染；若未启动后端，页面会提示“请确保后端已启动”。

### 5. 若页面打不开

- **确认在项目根目录启动**：在终端中先执行 `cd 项目根目录`（即包含 `backend`、`frontend`、`data` 的目录），再执行 `python run_server.py`。
- **确认端口未被占用**：若 8000 被占用，可改为 `--port 8080`，然后访问 <http://localhost:8080/>。
- **先测接口**：在浏览器访问 <http://localhost:8000/health>，若返回 `{"status":"ok"}` 说明服务正常；再访问 <http://localhost:8000/> 应能看到图谱页。
- **遇到 WinError 10013**：通常是端口权限/安全策略导致，优先改为 `--host 127.0.0.1`，或直接使用 `python run_server.py`（会自动挑选可用端口）。

### 6. 局域网用本机 IP 访问（如 `http://192.168.x.x:8080/`）打不开

**先分清：① 能开、② 不能开，多半是「监听地址」不对，不是防火墙。**

1. **看 `netstat`（最关键）**  
   服务启动后另开终端执行（端口改成你的，例如 8080）：
   ```text
   netstat -ano | findstr LISTENING | findstr :8080
   ```
   - 若出现 **`0.0.0.0:8080`** 或 **`[::]:8080`**：已监听所有网卡，才可以用 `http://192.168.x.x:8080/`（本机或其它电脑）。
   - 若只有 **`127.0.0.1:8080`**：进程**只接受本机回环**，此时 **`http://192.168.36.188:8080/` 一定连不上**，加防火墙规则也无效。必须改成下面第 2 步用 `0.0.0.0` 重启。

2. **必须用 `0.0.0.0` 监听**（与默认 `run_server.py` / `127.0.0.1` 不同）：
   ```bash
   python run_server.py --host 0.0.0.0 --port 8080
   ```
   或：
   ```bash
   python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080
   ```
   再执行一次第 1 步，确认已是 `0.0.0.0:8080`。

3. **Windows 防火墙**（仅当第 1 步已是 `0.0.0.0` 仍不行时）以**管理员** PowerShell 放行端口，并指定**三种网络类型**（避免规则只作用在域网）：
   ```powershell
   New-NetFirewallRule -DisplayName "SQL-graph 8080" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow -Profile Domain,Private,Public
   ```
   若仍不通，检查是否还有**第三方安全软件**自带防火墙。

4. **不要用 `http://0.0.0.0:8080/`** 当网址；本机请用 `http://127.0.0.1:8080/`，其他电脑用 `http://你的本机IPv4:8080/`（在 `ipconfig` 里看「以太网」或「WLAN」的 IPv4）。

---

## 项目文件及主要功能

### 项目结构

```
SQL-graph/
├── backend/                    # 后端（Python + FastAPI）
│   ├── __init__.py
│   ├── main.py                 # FastAPI 主入口，挂载前端静态与 API
│   ├── config.py               # 配置：DATA_DIR、SQL 扩展名等
│   ├── parser/
│   │   ├── __init__.py
│   │   └── etl_sql_parser.py    # ETL SQL 解析器
│   ├── analyzer/
│   │   ├── __init__.py
│   │   └── relation_analyzer.py # 关系合并与去重
│   ├── graph/
│   │   ├── __init__.py
│   │   └── graph_builder.py    # 图谱构建（表节点 + 关系边 → JSON）
│   ├── models/
│   │   ├── __init__.py
│   │   ├── table_node.py       # 表节点模型
│   │   ├── field_node.py       # 字段节点模型
│   │   └── relation_edge.py    # 关系边模型
│   └── api/
│       ├── __init__.py
│       ├── routes.py           # /api/graph、/api/graph/build
│       └── schemas.py          # 请求/响应模型
├── frontend/
│   ├── index.html              # 单页应用入口
│   ├── css/
│   │   └── styles.css          # 布局与图谱样式
│   └── js/
│       └── app.js              # 图谱加载、D3 渲染、搜索、详情面板
├── data/                       # SQL 数据集（ADS/DM/DWD 等）
├── sql-knowledge-graph-prompt.md  # 需求与设计说明
├── requirements.txt            # Python 依赖
└── README.md                   # 本说明
```

### 主要功能

| 模块 | 文件 | 功能说明 |
|------|------|----------|
| **入口与配置** | `backend/main.py` | 启动 FastAPI，挂载 CORS、API 路由、前端静态目录；`/` 返回前端，`/api/*` 走接口。 |
| | `backend/config.py` | 项目根目录、`data` 目录、`SECTOR_DATA_DIRS`（`PRD_AL` / `PRD_AO` 子目录）、SQL 扩展名、图谱版本等。 |
| **SQL 解析** | `backend/parser/etl_sql_parser.py` | 解析 ETL 风格 SQL：识别 `INSERT INTO`、`TRUNCATE`、`DELETE FROM`、`FROM`/`JOIN` 中的表名；从 `INSERT...SELECT...FROM/JOIN` 提取 **DATA_FLOW** 数据流关系；从文件头注释提取“描述”作为表注释。 |
| **关系分析** | `backend/analyzer/relation_analyzer.py` | 对多文件解析结果做关系合并与去重，并按需要累加关系强度。 |
| **图谱构建** | `backend/graph/graph_builder.py` | 全库合并后对相同 `(source, target)` 去重并累加 `weight`；**不做**传递闭包标记、**不做**共父源表剪枝，输出边均为解析得到的显式关系；节点含类型、注释、关联数等。 |
| **数据模型** | `backend/models/*.py` | `TableNode`、`FieldNode`、`RelationEdge` 及 to_dict，供图谱 JSON 使用。 |
| **API** | `backend/api/routes.py` | `GET /api/graph`：默认仅扫描 `data/PRD_AL`；`?sector=PRD_AO` 仅扫描 `data/PRD_AO`；亦可传 `data_dir`（须位于项目根目录内）。`POST /api/graph/build`：同上规则解析 `data_dir`。 |
| **前端** | `index.html` / `ao.html` + `css/styles.css` + `js/app.js` | 力导向；单块时全画布数仓分层；**多块时按连通分量分格 + 块内局部分层 + 强锚定簇心**，拉开无关联块；与电解铝/氧化铝共用配色与椭圆节点；保留层级勾选。 |

### 图谱展示方案（节点 / 关系规则与布局）

#### 1. 节点（表）如何生成

- **来源**：解析阶段在 SQL 中出现的表（`INSERT`/`TRUNCATE`/`DELETE` 目标表，以及 `FROM`/`JOIN` 中的物理表名）；若某表仅作为关系的端点出现，也会在合并阶段**补全为节点**。
- **标识**：节点 `id` / `name` 为**短表名**（去掉 schema，如 `sdhq.xxx` → `xxx`）。
- **属性**：`tableType` 由表名启发式推断（`dim_`/`dm_`→字典层、`ods_`/`dwd_`/`dws_`→核心明细、`ads_`→应用层、含 temp 等→临时等）；`comment` 优先来自文件头「描述」；`relationCount` 为合并后与该表相连的边数（去重后的有向边）。

#### 2. 关系（边）如何生成

- **DATA_FLOW**：同一 `INSERT INTO 目标表 … SELECT …` 语句块内，凡在 `FROM`/`JOIN` 中识别到的**源表** → **该目标表**，每条 `(源, 目标)` 产生数据流边；多文件或多处重复则合并为一条边并增大 `weight`。（当前解析器仅产出 `DATA_FLOW`；`RelationEdge` 模型保留其它 `relationType` 供扩展。）
- **不追加**算法推导的「间接边」；**不删除**共父源表之间的边（与旧版不同），以保证与脚本中显式出现的关系一致。
- **边样式**：`weight` 仅用于前端线宽（出现次数越多略粗）；`isTransitive` 字段固定为 `false`，不再参与展示逻辑。

#### 3. 前端可读性与布局

- **纵向**：按表名前缀将节点锚定到数仓分层带（上→下：ODS、DWD/DWS、DM/DIM、其它/视图、ADS），用 `forceY` 弱约束，减少跨层连线交叉。
- **横向 / 多块分离（不混布局）**：无向连通分量各占**独立槽位**：槽位间有 **gutter**，且每槽有**最小宽高**（4 块时约为视口短边的 38%～42% 量级），数据坐标上先拉开再 fit 缩放；`forceX` / `anchorY` **强锚定**槽心，并略降全局斥力。可选绘制**虚线槽位底框**便于肉眼区分区块。块内仍为 ODS→ADS **相对槽心**的局部纵向分层。
- **其它**：斥力与碰撞避免节点堆叠；跨层边的链长略加长；边渲染为**向本连通块簇心弯曲**的二次贝塞尔路径并做法向微偏移，减轻与其它区块直线的视觉缠绕；支持缩放平移与血缘点击高亮；**层级勾选**仍会隐藏未选层中的节点及其关联边，但不会在「全选层」时丢弃无边节点。

### 数据集说明

- `data/PRD_AL`、`data/PRD_AO` 等为板块子目录，内含 ETL SQL（无 CREATE TABLE）：含 `INSERT INTO ... SELECT ... FROM ... JOIN`、`TRUNCATE`、`DELETE` 等。
- 浏览器打开 `/` 为电解铝图谱，`/ao.html` 为氧化铝图谱。
- 解析器会从这些语句中抽取**表名**与**表关系**（数据流 + JOIN ON 列关联），并利用文件头 `描述：xxx` 作为表注释，用于图谱展示与搜索。

### 技术栈

- **后端**：Python 3、FastAPI、Pydantic
- **前端**：原生 HTML/CSS/JS、D3.js v7（力导向图）
- **数据**：内存构建图谱，通过 JSON API 提供给前端

---

**文档版本**：1.1  
**适用场景**：基于现有 SQL 脚本（尤其是 ETL）构建表级知识图谱、理解库表依赖与数据流。
