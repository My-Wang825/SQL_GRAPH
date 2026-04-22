---
AIGC:
    ContentProducer: Minimax Agent AI
    ContentPropagator: Minimax Agent AI
    Label: AIGC
    ProduceID: f33cf578df1133604cd33868ac59c242
    PropagateID: f33cf578df1133604cd33868ac59c242
    ReservedCode1: 3046022100a500105798bdf02b8e3c6f46753a353dacc96a8a6b6e5be9c7be1b2613c6548302210097cedeb873424182e76497a8a64ed73ca011701b31a6fa85ded5ff52eff61fe3
    ReservedCode2: 3045022100bb1b5c9795464b9207c09c71abcfa110c10092d7d5efa2367b8fc02583fcc11b02206d821ff389ca5587d714e236d0ccc14f6509b3253e2b2855c53ebd324e71bb4f
---

# SQL 知识图谱系统开发提示词

您需要开发一个智能化的 SQL 知识图谱系统，该系统能够自动解析多个 SQL 脚本文件，提取其中的数据表结构信息，分析表与表之间的关联关系，并构建可视化的知识图谱。用户可以通过查询任意一张表，直观地看到该表在整个数据库架构中的位置，以及与其相关的所有表节点和关系类型。

## 一、项目概述与核心需求

### 1.1 项目背景

在企业级应用开发中，数据库设计通常涉及数十甚至数百张相互关联的数据表。传统的文档方式难以清晰地表达这些复杂的表关系，而知识图谱作为一种直观的可视化工具，能够帮助开发人员快速理解数据库架构，发现潜在的设计问题，促进团队协作。因此，开发一个自动化的 SQL 知识图谱系统具有重要的实用价值。

本项目的核心目标是构建一个从 SQL 脚本到知识图谱的自动化工具，用户只需导入 SQL 脚本文件，系统即可自动解析其中的表结构和关系，并生成可交互的知识图谱可视化界面。这种方式不仅大大减少了人工绘制数据库关系图的工作量，还能确保图谱与实际代码保持同步，避免文档滞后的问题。

### 1.2 核心功能需求

**数据提取层**：系统需要支持批量导入 SQL 脚本文件，能够正确解析常见的 SQL 方言，包括 MySQL、PostgreSQL、SQL Server、Oracle 等主流数据库的语法。提取的信息应包括：表名称、表注释、字段列表、字段类型、字段长度、是否允许为空、默认值设置、主键定义、唯一键定义、外键约束、索引定义等。此外，系统还需要识别并处理视图（VIEW）等数据库对象。

**关系分析层**：系统需要从多个维度分析表之间的关系。首先是显式关系，通过解析外键约束（FOREIGN KEY）来识别表之间的直接引用关系。其次是隐式关系，通过分析字段命名规范（如 user_id、order_id 等常见的命名模式）来推测可能存在的关联关系。同时根据字段类型的相似性来推断潜在的关联。

**知识图谱构建**：基于提取的表结构和关系数据，系统需要构建一个完整的知识图谱数据结构。图谱应包含两类核心节点：表节点和字段节点。图谱应包含多种类型的边：包含关系（表包含字段）、外键关系（字段引用其他表）、类型关系（字段类型关联）、相似关系（字段结构相似）等。

**可视化展示层**：系统需要在 HTML 页面中实现知识图谱的可视化展示。采用力导向图布局算法展示表节点的整体分布，通过节点颜色区分不同类型的表，通过边的粗细和颜色表示关系的强弱和类型。用户点击任意表节点时，应以该表为中心重新布局图谱，高亮显示直接关联的表，淡化显示间接关联的表。

### 1.3 技术选型建议

**后端解析技术**：推荐使用 Python 作为后端开发语言。Python 拥有丰富的 SQL 解析库（如 sqlparse、python-sqlparse），能够处理大部分标准 SQL 语法。正则表达式配合词法分析可以应对特定数据库的方言差异。Python 的数据结构操作灵活，便于构建复杂的关系图谱。对于复杂的 SQL 方言解析，可以考虑使用 ANTLR4 定义语法规则并生成对应的解析器。

**前端可视化技术**：推荐使用 D3.js 实现知识图谱的力导向图布局，D3.js 是目前最成熟的数据可视化库之一，拥有丰富的布局算法和交互支持。如果希望更快地完成开发，可以考虑 ECharts 的 graph 系列图表，或者使用 Cytoscape.js、Sigma.js 等专业的图可视化库。整体页面建议采用 Vue.js 或 React 框架构建，以实现组件化和状态管理。

**数据存储方案**：对于中小规模的数据（表数量在几百张以内），可以直接在前端使用 JSON 数据结构存储图谱信息，通过浏览器本地存储（LocalStorage）实现持久化。对于大规模数据，建议使用 Neo4j 等图数据库存储知识图谱，这样可以直接利用图数据库的查询能力来支持复杂的图分析场景。

## 二、详细功能规格

### 2.1 SQL 脚本解析模块

#### 2.1.1 支持的 SQL 语法结构

系统应能够正确解析以下 SQL 语法结构：CREATE TABLE 语句是最核心的解析对象，需要处理完整的表定义语法，包括表名、表空间、存储参数等；ALTER TABLE 语句用于识别后续对表结构的修改，如添加字段、修改字段属性等；DROP TABLE 语句用于识别被删除的表（在多版本脚本分析场景下有用）；CREATE INDEX 语句用于提取索引定义信息。

解析器应能处理标准的关系型数据库 SQL 语法，包括 MySQL 的 EXTENDED 语法、PostgreSQL 的 WITH OIDS 语法、SQL Server 的 ON [PRIMARY] 语法等。对于不同数据库的特定语法，应能智能识别并提取有效信息。

#### 2.1.2 字段信息提取规范

对于每个字段，系统应提取以下属性信息：

**基础属性**：字段名称（column_name）、字段序号（ordinal_position）、数据类型（data_type）、是否可空（is_nullable）、默认值（column_default）。数据类型需要标准化处理，将数据库特有的类型映射为统一的数据类型体系，如将 MySQL 的 VARCHAR(255) 和 PostgreSQL 的 CHARACTER VARYING(255) 统一映射为字符串类型。

**约束属性**：主键标识（is_primary_key）、唯一键标识（is_unique）、外键引用（foreign_key_reference）、检查约束（check_constraint）、自动递增标识（is_identity）。对于复合主键和复合唯一键，需要记录所有参与构成的字段。

**扩展属性**：字段注释（column_comment）、字符集设置（character_set）、排序规则（collation）、列格式（column_format，仅 MySQL）。这些信息对于理解表的业务含义和设计意图非常重要。

#### 2.1.3 外键关系提取规范

外键是构建知识图谱的核心数据源，解析器应尽可能完整地提取外键信息。对于每个外键约束，需要提取：外键名称（constraint_name）、源表名称（source_table）、源字段列表（source_columns）、目标表名称（target_table）、目标字段列表（target_columns）、更新策略（on_update）、删除策略（on_delete）。

系统还应支持自引用外键的识别（如部门表的 parent_dept_id 引用自身）、多对多关联表的识别（如 order_product 表同时引用 order 表和 product 表），以及级联删除和级联更新的识别。

### 2.2 关系分析引擎

#### 2.2.1 显式关系提取

显式关系是指通过 SQL 语法明确定义的关系，主要包括外键关系、继承关系（在支持继承的数据库如 PostgreSQL 中）。外键关系的提取应按照前文所述的规范进行，并建立完整的关系图谱数据。

除了标准的外键约束，系统还应尝试识别隐含在字段命名中的外键关系。很多数据库设计遵循一定的命名规范，如所有以 "_id" 结尾的字段都是外键引用、所有以 "fk_" 开头的约束名表示外键约束等。系统可以配置这些命名规则，自动推断可能存在的外键关系。

#### 2.2.2 隐式关系推断

隐式关系是指没有通过外键语法明确定义，但通过其他特征可以推断出的关联关系。

**命名模式匹配**：系统可以定义一系列命名模式规则，如 "user_id" 通常引用 user 表、"order_no" 通常引用 order 表的 no 字段、"product_code" 通常引用 product 表等。当两张表的字段满足这些模式时，可以推断它们之间可能存在关联关系。这种推断的准确性较低，应作为"可能关系"而非"确定关系"展示。

**类型相似性分析**：当两张表存在类型完全相同的字段（如都是 UUID 类型、都是特定格式的字符串）且字段名称高度相似时，可以推断它们之间可能存在关联。这种推断同样应标记为低置信度的可能关系。

**数据内容关联**：如果提供了数据库的实际数据样本，系统可以通过分析字段值的重叠程度来推断关联关系。例如，如果 order 表的 user_id 字段的所有值都存在于 user 表的 id 字段中，可以高度确信 user_id 是指向 user 表的外键。

#### 2.2.3 关系强度计算

系统应计算每条关系的强度指标，用于在图谱可视化中调整边的显示方式。关系强度的计算应综合考虑以下因素：是否通过外键明确定义（高权重）、是否符合命名规范（中权重）、是否类型相似（低权重）、数据层面的验证结果（如果有）。最终输出一个 0-100 的关系强度分数。

### 2.3 知识图谱数据结构

#### 2.3.1 节点定义

**表节点（TableNode）**：表节点是知识图谱中最核心的节点类型，每个数据表对应一个表节点。表节点应包含以下属性：唯一标识符（id），通常由表所属的数据库名称和 schema 名称拼接而成，确保在不同数据库间也不冲突；表名称（name），即 SQL 中定义的原始表名；显示名称（displayName），如果表有注释则使用注释作为显示名称，否则使用表名；所属 schema（schema）和数据库（database）信息；表注释（comment），用于描述表的业务用途；字段数量统计；主键字段列表；外键字段列表；索引定义列表；创建时间；数据量统计（如果有）；标签列表，用于分类管理；层级（level），用于表示表的重要性或依赖层级；重要程度（importance），标识表的核心程度。

**字段节点（FieldNode）**：字段节点是表的组成元素，每个字段对应一个字段节点。字段节点应包含以下属性：唯一标识符，通常由表节点 ID 和字段名拼接而成；字段名称和显示名称；所属表节点 ID；数据类型，需要标准化后的统一类型；原始数据类型，保留数据库原生的类型定义；是否可空；是否为主键；是否为外键；默认值；字段注释；最大长度或精度；字段在表中的位置序号。

#### 2.3.2 边定义

**包含关系（CONTAINS）**：表节点包含字段节点，边的属性包括字段在表中的位置序号。这是一种一对多的聚合关系，每个表节点可以有多个包含关系边指向其下的字段节点。

**外键关系（FOREIGN_KEY）**：源字段节点指向目标表节点，边的属性包括关系名称、被引用字段、更新策略、删除策略、置信度、关系强度等。这是知识图谱中最重要的一类边，描述了表与表之间的引用关系。

**相似关系（SIMILAR）**：推断出的相似字段之间的关联，用于展示可能的隐式关系。边的属性包括相似度分数、置信度、推断原因等。

#### 2.3.3 图谱元数据

图谱元数据用于描述整个知识图谱的基本信息，包括：版本号、生成时间、来源文件列表、统计信息（表数量、字段数量、外键数量、推断关系数量等）、数据库类型、解析器版本等。这些信息有助于图谱的管理和版本控制。

### 2.4 可视化展示规范

#### 2.4.1 力导向图布局

图谱应采用力导向布局算法进行初始位置计算。力导向算法的参数配置建议如下：节点之间的排斥力系数设置为 -300，用于避免节点重叠；边的弹簧力系数设置为 0.3，用于保持相连节点的适当距离；中心引力系数设置为 0.1，用于将所有节点向画布中心吸引；阻尼系数设置为 0.85，用于使布局快速收敛。

布局计算完成后，应允许用户拖拽节点调整位置，调整后的位置应保存到用户偏好设置中。点击空白区域应能重置布局到默认的力导向状态。

#### 2.4.2 节点视觉设计

**表节点**：采用圆角矩形作为节点形状，宽度根据表名长度自适应。节点背景色根据表类型区分：核心业务表使用深蓝色系、字典表使用绿色系、关联表使用橙色系、临时表使用灰色系。节点边框颜色表示主表和关联表的状态：当前查询的主表使用金色边框、直接关联的表使用蓝色边框、间接关联的表使用浅灰色边框。

**节点内部布局**：节点内应显示表名称（中文注释优先于英文名称）、字段数量统计、关键字段预览（显示前 3 个重要字段）。当节点被选中时，应在节点下方展开详细信息面板。

**节点状态**：默认状态显示基本信息；悬停状态显示更多统计信息和关系摘要；选中状态显示完整信息和周边关系；高亮状态用于标记搜索结果或筛选结果；禁用状态用于淡化显示无关节点。

#### 2.4.3 边的视觉设计

**外键关系边**：实线线条，线宽根据关系强度在 1-4 像素之间变化。线条颜色使用蓝色系，从浅蓝（弱关系）到深蓝（强关系）。箭头指向被引用的表。鼠标悬停时显示关系详情提示框。

**隐式关系边**：虚线线条，线宽固定为 1 像素。线条颜色使用灰色系。端点使用圆点而非箭头，表示不确定的关联方向。线条透明度降低（0.4），表示这是推断关系。

**包含关系边**：默认不显示，仅在选中表节点时才显示该表的所有字段节点及其包含关系。这种设计可以减少视觉混乱，突出核心关系。

#### 2.4.4 交互功能规范

**基础交互**：鼠标滚轮缩放画布，缩放范围 0.1x - 5x；鼠标左键拖拽画布平移；鼠标左键点击节点选中该节点；鼠标左键双击节点进入该表的详细视图；鼠标右键点击节点弹出上下文菜单（查看详情、展开关联、隐藏节点等）。

**高级交互**：框选功能，按住鼠标左键拖动形成选择框，选中框内的所有节点；多选功能，按住 Ctrl 键点击可以选择多个节点；关系追溯，点击边可以查看该关系的详细信息，包括涉及的字段、约束条件等；路径高亮，输入起始表和结束表后，高亮显示两者之间的所有关联路径。

**搜索和筛选**：全局搜索框，输入表名或字段名可以快速定位节点；类型筛选，可以按表类型、关系类型进行筛选；时间筛选，如果记录了表的创建和修改时间，可以按时间范围筛选；关系数量筛选，可以筛选出关联数量大于或小于指定值的表。

### 2.5 查询功能设计

#### 2.5.1 单表查询

当用户查询某一张表时，系统应执行以下操作：定位并居中显示该表节点；高亮该表的所有直接关联表（距离为 1 的节点）；淡化显示间接关联表（距离大于 1 的节点）和无关节点；展开该表的详细信息面板，显示表的完整字段列表、主键、外键、索引等；显示该表的出度和入度统计，即该表指向其他表和被其他表引用的数量。

#### 2.5.2 关系路径查询

用户可以输入两张表的名称，系统查找并高亮显示它们之间的所有关联路径。如果存在多条路径，应按路径长度排序，优先显示最短路径。每条路径应显示所经过的表节点和关系类型，以及路径的总长度（跳数）。

#### 2.5.3 聚合分析查询

系统应支持对图谱进行聚合分析，生成统计报告。报告内容包括：出度最高的表（被最多表引用的表，可能是核心表）；入度最高的表（引用最多其他表的表，可能是聚合表或服务表）；孤立表（没有任何关联的表，可能是未完成设计或已废弃的表）；循环依赖检测（识别出表之间的循环引用关系）；表群聚类（通过社区检测算法识别出紧密关联的表集群）。

## 三、技术实现指南

### 3.1 SQL 解析实现方案

#### 3.1.1 使用 sqlparse 库解析标准 SQL

Python 的 sqlparse 库是一个非验证型的 SQL 解析器，支持多种 SQL 语句的解析。以下是使用 sqlparse 解析 CREATE TABLE 语句的基本代码框架：

```python
import sqlparse
from sqlparse.sql import Identifier, Function, Parenthesis, Token
from sqlparse.tokens import Keyword, DML, Name

def parse_create_table(sql):
    """解析 CREATE TABLE 语句"""
    statements = sqlparse.parse(sql)
    tables = []

    for statement in statements:
        if statement.get_type() == 'CREATE':
            # 遍历 tokens 查找 TABLE 关键字
            for token in statement.tokens:
                if token.ttype is Keyword and token.value.upper() == 'TABLE':
                    # 获取表定义部分（跟在 TABLE 关键字后面的内容）
                    pass

    return tables

def extract_table_name(token):
    """从 token 中提取表名"""
    if isinstance(token, Identifier):
        return token.get_real_name()
    elif hasattr(token, 'get_parent_name'):
        return token.get_parent_name()
    return None

def extract_columns(table_content):
    """提取字段定义列表"""
    columns = []
    # 解析括号内的字段定义
    pass
    return columns
```

#### 3.1.2 使用正则表达式处理复杂方言

对于 sqlparse 无法处理的特定方言，可以使用正则表达式作为补充手段：

```python
import re

class MySQLParser:
    """MySQL 专用解析器"""

    # CREATE TABLE 语句匹配模式
    CREATE_TABLE_PATTERN = re.compile(
        r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s*\(([\s\S]*?)\)',
        re.IGNORECASE
    )

    # 字段定义匹配模式
    COLUMN_PATTERN = re.compile(
        r'`?(\w+)`?\s+([\w()]+(?:\s+[\w()]+)*)'  # 字段名 + 类型
        r'(?:\s+(PRIMARY\s+KEY|UNIQUE|KEY|NOT\s+NULL|NULL|AUTO_INCREMENT'
        r'|DEFAULT\s+[\'\"]?[\w\-\.]+[\'\"]?'
        r'|COMMENT\s+[\'\"][^\'\"]+[\'\"]'))*',
        re.IGNORECASE
    )

    # 外键定义匹配模式
    FOREIGN_KEY_PATTERN = re.compile(
        r'CONSTRAINT\s+`?(\w+)`?\s+FOREIGN\s+KEY\s*\(`?(\w+)`?\)\s*'
        r'REFERENCES\s+`?(\w+)`?\s*\(`?(\w+)`?\)',
        re.IGNORECASE
    )

    def parse(self, sql_content):
        """解析 SQL 文件内容"""
        tables = []
        matches = self.CREATE_TABLE_PATTERN.findall(sql_content)

        for table_name, table_body in matches:
            table_info = {
                'name': table_name,
                'fields': self.extract_fields(table_body),
                'foreign_keys': self.extract_foreign_keys(table_body),
                'indexes': self.extract_indexes(table_body)
            }
            tables.append(table_info)

        return tables

    def extract_fields(self, table_body):
        """提取字段定义"""
        fields = []
        for match in self.COLUMN_PATTERN.finditer(table_body):
            field_name = match.group(1)
            field_type = match.group(2)
            constraints = match.group(3) if match.lastindex >= 3 else ''

            fields.append({
                'name': field_name,
                'type': field_type,
                'is_primary': 'PRIMARY KEY' in constraints.upper(),
                'is_nullable': 'NOT NULL' not in constraints.upper(),
                'auto_increment': 'AUTO_INCREMENT' in constraints.upper()
            })

        return fields

    def extract_foreign_keys(self, table_body):
        """提取外键定义"""
        foreign_keys = []
        for match in self.FOREIGN_KEY_PATTERN.finditer(table_body):
            foreign_keys.append({
                'constraint_name': match.group(1),
                'source_column': match.group(2),
                'target_table': match.group(3),
                'target_column': match.group(4)
            })

        return foreign_keys
```

#### 3.1.3 字段类型标准化

不同数据库的数据类型需要标准化为统一的数据类型体系，以便于后续的分析和可视化：

```python
class TypeNormalizer:
    """数据类型标准化器"""

    TYPE_MAPPING = {
        # 字符串类型
        'varchar': 'string', 'char': 'string', 'text': 'string',
        'nvarchar': 'string', 'nchar': 'string', 'ntext': 'string',
        'character varying': 'string', 'character': 'string',

        # 数值类型
        'int': 'integer', 'integer': 'integer', 'bigint': 'integer',
        'smallint': 'integer', 'tinyint': 'integer', 'mediumint': 'integer',
        'numeric': 'decimal', 'decimal': 'decimal', 'float': 'float',
        'double': 'float', 'real': 'float', 'money': 'decimal',

        # 日期时间类型
        'datetime': 'datetime', 'timestamp': 'datetime', 'date': 'date',
        'time': 'time', 'year': 'integer',

        # 二进制类型
        'binary': 'binary', 'varbinary': 'binary', 'blob': 'binary',
        'tinyblob': 'binary', 'mediumblob': 'binary', 'longblob': 'binary',

        # 布尔类型
        'boolean': 'boolean', 'bool': 'boolean', 'bit': 'boolean',

        # JSON/XML 类型
        'json': 'json', 'xml': 'xml', 'jsonb': 'json',

        # UUID 类型
        'uuid': 'uuid',
    }

    def normalize(self, db_type, db_vendor='mysql'):
        """标准化数据类型"""
        base_type = db_type.lower().strip()

        # 移除长度、精度等参数
        base_type = re.sub(r'\([\d,\s]+\)', '', base_type)
        base_type = base_type.strip()

        # 查找映射
        for pattern, normalized in self.TYPE_MAPPING.items():
            if pattern in base_type:
                return normalized

        return 'unknown'
```

### 3.2 关系分析实现方案

#### 3.2.1 显式关系提取

显式关系直接从 SQL 的外键约束中提取，是最可靠的关联数据来源：

```python
class RelationAnalyzer:
    """关系分析器"""

    def __init__(self):
        self.tables = {}
        self.relations = []

    def add_table(self, table_info):
        """添加表信息"""
        self.tables[table_info['name']] = table_info

    def extract_relations(self):
        """提取所有显式关系"""
        for table_name, table_info in self.tables.items():
            for fk in table_info.get('foreign_keys', []):
                relation = {
                    'source_table': table_name,
                    'source_column': fk['source_column'],
                    'target_table': fk['target_table'],
                    'target_column': fk['target_column'],
                    'constraint_name': fk.get('constraint_name', ''),
                    'on_update': fk.get('on_update', 'NO ACTION'),
                    'on_delete': fk.get('on_delete', 'NO ACTION'),
                    'relation_type': 'explicit',
                    'confidence': 1.0,
                    'strength': 100
                }
                self.relations.append(relation)

        return self.relations

    def infer_implicit_relations(self):
        """推断隐式关系"""
        naming_patterns = [
            # (模式, 推断的目标表名)
            (r'(\w+)_id$', lambda m: m.group(1)),
            (r'(\w+)_code$', lambda m: m.group(1)),
            (r'fk_(\w+)_(\w+)', lambda m: m.group(1)),
        ]

        for table_name, table_info in self.tables.items():
            for field in table_info.get('fields', []):
                field_name = field['name'].lower()

                # 跳过已经是外键的字段
                if field.get('is_foreign_key'):
                    continue

                # 尝试匹配命名模式
                for pattern, extractor in naming_patterns:
                    match = re.match(pattern, field_name)
                    if match:
                        target_table = extractor(match)
                        if target_table in self.tables:
                            # 检查目标表是否有对应的主键字段
                            target_table_info = self.tables[target_table]
                            # 如果推断关系不存在且目标表存在，则添加
                            if not self._relation_exists(table_name, field_name, target_table):
                                self.relations.append({
                                    'source_table': table_name,
                                    'source_column': field_name,
                                    'target_table': target_table,
                                    'target_column': 'id',
                                    'relation_type': 'implicit',
                                    'confidence': 0.6,
                                    'strength': 50,
                                    'reason': f'命名模式匹配: {pattern}'
                                })

    def _relation_exists(self, source_table, source_column, target_table):
        """检查关系是否已存在"""
        for rel in self.relations:
            if (rel['source_table'] == source_table and
                rel['source_column'] == source_column and
                rel['target_table'] == target_table):
                return True
        return False
```

#### 3.2.2 关系强度计算

关系强度综合考虑多个因素进行计算：

```python
def calculate_relation_strength(relation, tables):
    """计算关系强度"""
    strength = 0

    # 基础分：如果是通过外键明确定义的
    if relation['relation_type'] == 'explicit':
        strength += 50

    # 命名规范匹配
    if 'reason' in relation and '命名模式' in relation['reason']:
        strength += 20

    # 类型匹配
    source_field = None
    target_field = None

    source_table = tables.get(relation['source_table'])
    if source_table:
        for field in source_table.get('fields', []):
            if field['name'] == relation['source_column']:
                source_field = field
                break

    target_table = tables.get(relation['target_table'])
    if target_table:
        for field in target_table.get('fields', []):
            if field['name'] == relation['target_column']:
                target_field = field
                break

    if source_field and target_field:
        # 类型完全匹配
        if source_field['type'] == target_field['type']:
            strength += 15

        # 长度完全匹配
        if (source_field.get('length') and
            target_field.get('length') and
            source_field['length'] == target_field['length']):
            strength += 10

        # 名称相似度
        similarity = calculate_string_similarity(
            source_field['name'], target_field['name'])
        if similarity > 0.7:
            strength += 5

    # 约束动作加成
    if relation.get('on_delete') in ['CASCADE', 'SET NULL']:
        strength += 5

    return min(100, max(0, strength))
```

### 3.3 前端可视化实现方案

#### 3.3.1 D3.js 力导向图基础实现

D3.js 是最常用的数据可视化库，其 force 模块提供了强大的力导向图布局功能：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SQL 知识图谱</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        #graph-container {
            width: 100vw;
            height: 100vh;
            background: #1a1a2e;
        }
        .node {
            cursor: pointer;
        }
        .node rect {
            transition: all 0.3s ease;
        }
        .link {
            stroke-opacity: 0.6;
            transition: all 0.3s ease;
        }
        .link.explicit {
            stroke: #4a9eff;
            stroke-dasharray: none;
        }
        .link.implicit {
            stroke: #888;
            stroke-dasharray: 5,5;
            stroke-opacity: 0.4;
        }
        .tooltip {
            position: absolute;
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 10px;
            border-radius: 5px;
            font-size: 12px;
            pointer-events: none;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <div id="graph-container"></div>
    <div id="tooltip" class="tooltip" style="display: none;"></div>

    <script>
        // 配置参数
        const config = {
            width: window.innerWidth,
            height: window.innerHeight,
            nodeWidth: 150,
            nodeHeight: 60,
            colors: {
                core: '#2d5a9e',      // 核心业务表
                dictionary: '#2e8b57', // 字典表
                junction: '#e67e22',   // 关联表
                temp: '#7f8c8d',      // 临时表
                selected: '#ffd700',  // 选中状态
                direct: '#4169e1',    // 直接关联
                indirect: '#d3d3d3'   // 间接关联
            }
        };

        // 初始化 SVG
        const svg = d3.select('#graph-container')
            .append('svg')
            .attr('width', config.width)
            .attr('height', config.height);

        // 添加缩放行为
        const g = svg.append('g');
        const zoom = d3.zoom()
            .scaleExtent([0.1, 5])
            .on('zoom', (event) => {
                g.attr('transform', event.transform);
            });
        svg.call(zoom);

        // 创建力导向模拟
        let simulation = d3.forceSimulation()
            .force('link', d3.forceLink().id(d => d.id).distance(200))
            .force('charge', d3.forceManyBody().strength(-500))
            .force('center', d3.forceCenter(config.width / 2, config.height / 2))
            .force('collision', d3.forceCollide().radius(100));

        let nodes = [];
        let links = [];

        // 渲染图谱
        function renderGraph(data) {
            nodes = data.nodes;
            links = data.links;

            // 更新力模拟
            simulation.nodes(nodes);
            simulation.force('link').links(links);
            simulation.alpha(1).restart();

            // 绘制边
            const link = g.append('g')
                .attr('class', 'links')
                .selectAll('line')
                .data(links)
                .join('line')
                .attr('class', d => `link ${d.relationType}`)
                .attr('stroke-width', d => d.strength / 30 + 1)
                .attr('marker-end', d => 'url(#arrowhead)');

            // 绘制节点
            const node = g.append('g')
                .attr('class', 'nodes')
                .selectAll('g')
                .data(nodes)
                .join('g')
                .attr('class', 'node')
                .call(d3.drag()
                    .on('start', dragstarted)
                    .on('drag', dragged)
                    .on('end', dragended))
                .on('click', handleNodeClick)
                .on('mouseover', handleNodeHover)
                .on('mouseout', handleNodeOut);

            // 节点形状
            node.append('rect')
                .attr('width', config.nodeWidth)
                .attr('height', config.nodeHeight)
                .attr('x', -config.nodeWidth / 2)
                .attr('y', -config.nodeHeight / 2)
                .attr('rx', 10)
                .attr('fill', d => getNodeColor(d))
                .attr('stroke', d => d.stroke || '#fff')
                .attr('stroke-width', 2);

            // 节点文字
            node.append('text')
                .attr('text-anchor', 'middle')
                .attr('dy', -5)
                .attr('fill', 'white')
                .attr('font-size', '12px')
                .text(d => truncateText(d.displayName || d.name, 15));

            // 节点统计
            node.append('text')
                .attr('text-anchor', 'middle')
                .attr('dy', 15)
                .attr('fill', 'rgba(255,255,255,0.7)')
                .attr('font-size', '10px')
                .text(d => `${d.fieldCount || 0} 字段 | ${d.relationCount || 0} 关联`);

            // 定义箭头标记
            svg.append('defs').append('marker')
                .attr('id', 'arrowhead')
                .attr('viewBox', '-0 -5 10 10')
                .attr('refX', 20)
                .attr('refY', 0)
                .attr('orient', 'auto')
                .attr('markerWidth', 6)
                .attr('markerHeight', 6)
                .append('path')
                .attr('d', 'M 0,-5 L 10,0 L 0,5')
                .attr('fill', '#4a9eff');

            // 力模拟更新
            simulation.on('tick', () => {
                link
                    .attr('x1', d => d.source.x)
                    .attr('y1', d => d.source.y)
                    .attr('x2', d => d.target.x)
                    .attr('y2', d => d.target.y);

                node.attr('transform', d => `translate(${d.x},${d.y})`);
            });
        }

        function getNodeColor(node) {
            const typeColors = {
                'core': config.colors.core,
                'dictionary': config.colors.dictionary,
                'junction': config.colors.junction,
                'temp': config.colors.temp
            };
            return typeColors[node.tableType] || config.colors.core;
        }

        function handleNodeClick(event, d) {
            event.stopPropagation();
            selectNode(d);
        }

        function selectNode(selectedNode) {
            // 计算到选中节点的距离
            const distances = calculateDistances(selectedNode);

            // 更新节点样式
            d3.selectAll('.node rect')
                .attr('stroke', d => {
                    if (d.id === selectedNode.id) return config.colors.selected;
                    if (distances[d.id] === 1) return config.colors.direct;
                    return config.colors.indirect;
                })
                .attr('stroke-width', d => d.id === selectedNode.id ? 3 : 1)
                .attr('opacity', d => {
                    if (d.id === selectedNode.id || !distances[d.id]) return 1;
                    if (distances[d.id] <= 2) return 1;
                    return 0.3;
                });

            // 更新边样式
            d3.selectAll('.link')
                .attr('stroke-opacity', d => {
                    if (d.source.id === selectedNode.id || d.target.id === selectedNode.id)
                        return 1;
                    return 0.1;
                })
                .attr('stroke-width', d => {
                    if (d.source.id === selectedNode.id || d.target.id === selectedNode.id)
                        return d.strength / 30 + 2;
                    return d.strength / 30 + 1;
                });

            // 显示详情面板
            showDetailPanel(selectedNode);
        }

        function calculateDistances(centerNode) {
            const distances = {};
            const queue = [centerNode.id];
            distances[centerNode.id] = 0;

            while (queue.length > 0) {
                const current = queue.shift();
                const currentDist = distances[current];

                links.forEach(link => {
                    let neighbor = null;
                    if (link.source.id === current) neighbor = link.target.id;
                    if (link.target.id === current) neighbor = link.source.id;

                    if (neighbor && distances[neighbor] === undefined) {
                        distances[neighbor] = currentDist + 1;
                        queue.push(neighbor);
                    }
                });
            }

            return distances;
        }

        function showDetailPanel(node) {
            const panel = document.getElementById('detail-panel') || createDetailPanel();
            panel.innerHTML = `
                <h3>${node.displayName || node.name}</h3>
                <p><strong>表名：</strong>${node.name}</p>
                <p><strong>类型：</strong>${node.tableType || '未知'}</p>
                <p><strong>注释：</strong>${node.comment || '无'}</p>
                <p><strong>字段数：</strong>${node.fieldCount || 0}</p>
                <p><strong>关联数：</strong>${node.relationCount || 0}</p>
                <h4>字段列表</h4>
                <ul>${(node.fields || []).map(f =>
                    `<li>${f.name} (${f.type})${f.isPrimaryKey ? ' [PK]' : ''}${f.isForeignKey ? ' [FK]' : ''}</li>`
                ).join('')}</ul>
            `;
            panel.style.display = 'block';
        }

        // 拖拽函数
        function dragstarted(event, d) {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
        }

        function dragged(event, d) {
            d.fx = event.x;
            d.fy = event.y;
        }

        function dragged(event, d) {
            d.fx = event.x;
            d.fy = event.y;
        }

        function dragended(event, d) {
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
        }

        function truncateText(text, maxLength) {
            return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
        }
    </script>
</body>
</html>
```

#### 3.3.2 搜索和筛选功能实现

```javascript
class GraphSearch {
    constructor(graphInstance) {
        this.graph = graphInstance;
        this.searchInput = document.getElementById('search-input');
        this.initSearch();
    }

    initSearch() {
        this.searchInput.addEventListener('input', (e) => {
            this.handleSearch(e.target.value);
        });
    }

    handleSearch(query) {
        if (!query || query.trim() === '') {
            this.clearHighlight();
            return;
        }

        query = query.toLowerCase();
        const matchedNodes = [];

        this.graph.nodes.forEach(node => {
            const nameMatch = (node.name || '').toLowerCase().includes(query);
            const displayMatch = (node.displayName || '').toLowerCase().includes(query);
            const commentMatch = (node.comment || '').toLowerCase().includes(query);

            if (nameMatch || displayMatch || commentMatch) {
                matchedNodes.push(node);
            }
        });

        this.highlightMatches(matchedNodes);
    }

    highlightMatches(matchedNodes) {
        const matchedIds = new Set(matchedNodes.map(n => n.id));

        // 高亮匹配的节点
        d3.selectAll('.node rect')
            .attr('opacity', d => matchedIds.has(d.id) ? 1 : 0.2)
            .attr('stroke', d => matchedIds.has(d.id) ? '#ffd700' : '#fff');

        // 淡化非匹配的边
        d3.selectAll('.link')
            .attr('stroke-opacity', d => {
                if (matchedIds.has(d.source.id) || matchedIds.has(d.target.id))
                    return 1;
                return 0.1;
            });
    }

    clearHighlight() {
        d3.selectAll('.node rect')
            .attr('opacity', 1)
            .attr('stroke', '#fff');

        d3.selectAll('.link')
            .attr('stroke-opacity', 0.6);
    }
}
```

### 3.4 数据存储方案

#### 3.4.1 本地存储方案

对于简单的应用场景，可以使用浏览器本地存储：

```javascript
class LocalStorageManager {
    constructor(storageKey = 'sql-knowledge-graph') {
        this.storageKey = storageKey;
    }

    saveGraph(graphData) {
        try {
            const serialized = JSON.stringify(graphData);
            localStorage.setItem(this.storageKey, serialized);
            return true;
        } catch (error) {
            console.error('保存图谱失败:', error);
            return false;
        }
    }

    loadGraph() {
        try {
            const serialized = localStorage.getItem(this.storageKey);
            if (!serialized) return null;
            return JSON.parse(serialized);
        } catch (error) {
            console.error('加载图谱失败:', error);
            return null;
        }
    }

    clearGraph() {
        localStorage.removeItem(this.storageKey);
    }

    exportToFile(graphData, filename = 'knowledge-graph.json') {
        const blob = new Blob([JSON.stringify(graphData, null, 2)],
            { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
    }
}
```

#### 3.4.2 Neo4j 图数据库方案

对于大规模数据和复杂查询，推荐使用 Neo4j：

```cypher
-- 创建表节点
LOAD CSV WITH HEADERS FROM 'file:///tables.csv' AS row
CREATE (t:Table {
    id: row.table_id,
    name: row.table_name,
    displayName: row.display_name,
    comment: row.comment,
    schema: row.schema,
    database: row.database,
    tableType: row.table_type,
    fieldCount: toInteger(row.field_count),
    createdAt: row.created_at
});

-- 创建字段节点
LOAD CSV WITH HEADERS FROM 'file:///fields.csv' AS row
CREATE (f:Field {
    id: row.field_id,
    name: row.field_name,
    displayName: row.display_name,
    dataType: row.data_type,
    isPrimaryKey: row.is_primary_key = 'true',
    isForeignKey: row.is_foreign_key = 'true',
    isNullable: row.is_nullable = 'true'
});

-- 创建包含关系
MATCH (t:Table {id: row.table_id}), (f:Field {id: row.field_id})
CREATE (t)-[r:CONTAINS {
    position: toInteger(row.position)
}]->(f);

-- 创建外键关系
LOAD CSV WITH HEADERS FROM 'file:///foreign_keys.csv' AS row
MATCH (s:Table {id: row.source_table}), (t:Table {id: row.target_table})
CREATE (s)-[r:REFERENCES {
    constraintName: row.constraint_name,
    sourceColumn: row.source_column,
    targetColumn: row.target_column,
    onUpdate: row.on_update,
    onDelete: row.on_delete,
    confidence: toFloat(row.confidence),
    strength: toInteger(row.strength)
}]->(t);

-- 查询指定表的所有关联（两跳之内）
MATCH path = (t:Table {name: 'user'})-[*1..2]-(related)
RETURN path;

-- 查找核心表（出度最高的表）
MATCH (t:Table)-[r:REFERENCES]->()
RETURN t.name, count(r) as outDegree
ORDER BY outDegree DESC
LIMIT 10;

-- 查找孤立表
MATCH (t:Table)
WHERE NOT (t)-[:REFERENCES]->() AND NOT ()-[:REFERENCES]->(t)
RETURN t;

-- 查找循环依赖
MATCH path = (t:Table)-[:REFERENCES*]->(t)
RETURN path;
```

## 四、项目文件结构

```
sql-knowledge-graph/
├── backend/
│   ├── __init__.py
│   ├── main.py                      # FastAPI 主入口
│   ├── config.py                    # 配置文件
│   ├── parser/
│   │   ├── __init__.py
│   │   ├── base_parser.py           # 解析器基类
│   │   ├── mysql_parser.py          # MySQL 解析器
│   │   ├── postgresql_parser.py      # PostgreSQL 解析器
│   │   ├── sqlserver_parser.py       # SQL Server 解析器
│   │   └── oracle_parser.py         # Oracle 解析器
│   ├── analyzer/
│   │   ├── __init__.py
│   │   ├── relation_analyzer.py      # 关系分析器
│   │   ├── schema_analyzer.py        # 结构分析器
│   │   └── naming_patterns.py       # 命名模式库
│   ├── graph/
│   │   ├── __init__.py
│   │   ├── graph_builder.py          # 图谱构建器
│   │   ├── graph_query.py           # 图谱查询
│   │   └── graph_export.py          # 图谱导出
│   ├── models/
│   │   ├── __init__.py
│   │   ├── table_node.py            # 表节点模型
│   │   ├── field_node.py            # 字段节点模型
│   │   └── relation_edge.py         # 关系边模型
│   └── api/
│       ├── __init__.py
│       ├── routes.py                # API 路由
│       └── schemas.py               # 请求响应模型
├── frontend/
│   ├── index.html                   # 主页面
│   ├── css/
│   │   ├── styles.css               # 主样式文件
│   │   └── graph.css               # 图谱样式
│   ├── js/
│   │   ├── app.js                  # 主应用逻辑
│   │   ├── graph-renderer.js       # 图谱渲染器
│   │   ├── graph-interaction.js    # 交互处理
│   │   ├── search.js               # 搜索功能
│   │   ├── panel.js                # 详情面板
│   │   └── api-client.js           # API 调用封装
│   └── assets/
│       └── icons/                   # 图标资源
├── data/
│   └── sample/                     # 示例 SQL 文件
├── tests/
│   ├── __init__.py
│   ├── test_parsers.py            # 解析器测试
│   ├── test_analyzers.py          # 分析器测试
│   └── test_graph.py              # 图谱测试
├── requirements.txt               # Python 依赖
├── package.json                   # Node.js 依赖
├── pyproject.toml                # 项目配置
└── README.md                     # 项目说明
```

## 五、开发优先级建议

### 第一阶段（MVP）

优先实现的核心功能包括：标准 SQL 文件的导入和解析、基础的表结构和外键关系提取、简单的力导向图可视化、基本的节点点击查询功能。这个阶段的目标是验证技术方案的可行性，建立基础的数据流和交互模式。

具体实现步骤：首先实现一个基础的 SQL 解析器，能够处理简单的 CREATE TABLE 语句；然后实现外键关系的提取；接着使用 D3.js 实现一个基本的力导向图；最后实现节点的点击查询和关系高亮功能。

### 第二阶段（增强功能）

在 MVP 基础上增加以下功能：多种数据库方言的支持，包括 MySQL、PostgreSQL、SQL Server 等主流数据库的语法兼容；隐式关系的推断分析，通过命名模式匹配和类型相似性分析来发现潜在关系；节点搜索和筛选功能，支持按表名、字段名、类型等条件进行搜索；关系路径查询和展示，能够查找任意两张表之间的关联路径；用户界面优化，包括节点拖拽位置保存、缩放层级记忆等交互增强。

### 第三阶段（高级特性）

实现的高级特性包括：Neo4j 图数据库集成，将图谱数据存储到专业的图数据库中，支持更大规模的数据和更复杂的图查询；聚合分析和报表功能，自动生成数据库架构分析报告，包括核心表识别、孤立表检测、循环依赖警告等；版本对比功能，支持上传多个版本的 SQL 脚本，自动识别新增、删除和修改的表结构；协作和分享功能，支持图谱的导出（PNG、SVG、JSON 等格式）和团队成员间的图谱分享。

## 六、示例 SQL 脚本

以下是一个用于测试的示例 SQL 脚本：

```sql
-- 用户管理模块
CREATE TABLE `user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `email` VARCHAR(100) NOT NULL COMMENT '邮箱',
    `password_hash` VARCHAR(255) NOT NULL COMMENT '密码哈希',
    `phone` VARCHAR(20) COMMENT '手机号',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态:0禁用1启用',
    `dept_id` BIGINT COMMENT '部门ID',
    `role_id` BIGINT COMMENT '角色ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_email` (`email`),
    KEY `idx_dept_id` (`dept_id`),
    KEY `idx_role_id` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE `department` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '部门ID',
    `parent_id` BIGINT COMMENT '父部门ID',
    `name` VARCHAR(100) NOT NULL COMMENT '部门名称',
    `code` VARCHAR(50) NOT NULL COMMENT '部门编码',
    `level` INT NOT NULL DEFAULT 1 COMMENT '层级',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门表';

CREATE TABLE `role` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '角色ID',
    `name` VARCHAR(50) NOT NULL COMMENT '角色名称',
    `code` VARCHAR(50) NOT NULL COMMENT '角色编码',
    `description` VARCHAR(255) COMMENT '描述',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

-- 添加外键约束
ALTER TABLE `user` ADD CONSTRAINT `fk_user_dept`
    FOREIGN KEY (`dept_id`) REFERENCES `department` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `user` ADD CONSTRAINT `fk_user_role`
    FOREIGN KEY (`role_id`) REFERENCES `role` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `department` ADD CONSTRAINT `fk_dept_parent`
    FOREIGN KEY (`parent_id`) REFERENCES `department` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- 订单模块
CREATE TABLE `order` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '订单ID',
    `order_no` VARCHAR(50) NOT NULL COMMENT '订单号',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `total_amount` DECIMAL(10,2) NOT NULL COMMENT '总金额',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '订单状态',
    `payment_method` VARCHAR(20) COMMENT '支付方式',
    `shipping_address` TEXT COMMENT '收货地址',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_no` (`order_no`),
    KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

CREATE TABLE `order_item` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '订单项ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `product_id` BIGINT NOT NULL COMMENT '商品ID',
    `quantity` INT NOT NULL COMMENT '数量',
    `unit_price` DECIMAL(10,2) NOT NULL COMMENT '单价',
    `subtotal` DECIMAL(10,2) NOT NULL COMMENT '小计',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_order_id` (`order_id`),
    KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单项表';

CREATE TABLE `product` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '商品ID',
    `name` VARCHAR(200) NOT NULL COMMENT '商品名称',
    `code` VARCHAR(50) NOT NULL COMMENT '商品编码',
    `category_id` BIGINT COMMENT '分类ID',
    `price` DECIMAL(10,2) NOT NULL COMMENT '价格',
    `stock` INT NOT NULL DEFAULT 0 COMMENT '库存',
    `description` TEXT COMMENT '商品描述',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`),
    KEY `idx_category_id` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品表';

-- 添加订单相关外键
ALTER TABLE `order` ADD CONSTRAINT `fk_order_user`
    FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `order_item` ADD CONSTRAINT `fk_item_order`
    FOREIGN KEY (`order_id`) REFERENCES `order` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `order_item` ADD CONSTRAINT `fk_item_product`
    FOREIGN KEY (`product_id`) REFERENCES `product` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;
```

以上示例展示了一个典型的电商系统数据库设计，包括用户管理（用户、部门、角色）和订单管理（订单、订单项、商品）两大模块，模块内部通过外键形成了完整的关联关系。使用本项目开发的知识图谱系统，可以清晰地展示这些表之间的关联结构，帮助开发人员快速理解系统架构。

---

**文档版本**：1.0
**生成时间**：2024-03-19
**适用场景**：数据库设计分析、架构文档生成、团队协作沟通
