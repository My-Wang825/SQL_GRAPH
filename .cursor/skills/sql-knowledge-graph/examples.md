# SQL 知识图谱 — 示例

## 1. 最小 ETL SQL（产生 DATA_FLOW）

下列片段中，若解析器将 `INSERT` 目标识别为 `ads_prd_al_example_ufd`，且 `FROM`/`JOIN` 中物理表为 `dwd_prd_al_fact_d`、`dim_prd_al_org_ufd`，则应至少产生两条有向边（方向均为**源 → INSERT 目标**）：

```sql
/* 描述：示例 ADS 日汇总表 */
INSERT INTO sdhq.ads_prd_al_example_ufd
SELECT
    f.biz_date,
    f.amount,
    o.org_name
FROM sdhq.dwd_prd_al_fact_d f
LEFT JOIN sdhq.dim_prd_al_org_ufd o ON f.org_id = o.org_id
WHERE f.biz_date = '${bizdate}';
```

**约定**：子查询别名、派生表不得登记为物理表节点；表名规范化后 `id` 为短名（无 schema）。

## 2. 简化版 API 响应结构（说明用，非真实数据）

```json
{
  "nodes": [
    {
      "id": "dwd_prd_al_fact_d",
      "name": "dwd_prd_al_fact_d",
      "displayName": "事实表示例",
      "comment": "",
      "tableType": "core",
      "relationCount": 1
    },
    {
      "id": "ads_prd_al_example_ufd",
      "name": "ads_prd_al_example_ufd",
      "displayName": "示例 ADS 日汇总表",
      "comment": "示例 ADS 日汇总表",
      "tableType": "junction",
      "relationCount": 2
    }
  ],
  "links": [
    {
      "source": "dwd_prd_al_fact_d",
      "target": "ads_prd_al_example_ufd",
      "relationType": "DATA_FLOW",
      "weight": 1,
      "sources": ["/path/to/script.sql"],
      "isTransitive": false
    }
  ],
  "meta": {
    "version": "1.0",
    "tableCount": 2,
    "relationCount": 1
  }
}
```

实际 `links` 条数取决于 `FROM`/`JOIN` 中识别到的源表个数；同一 `(source, target)` 在多文件重复出现时应合并为一条并增加 `weight`。

## 3. 前端请求示例

```http
GET /api/graph?sector=PRD_AL HTTP/1.1
Host: 127.0.0.1:8000
```

新仓库将 `PRD_AL` 替换为自有板块代码，并保证 `SECTOR_DATA_DIRS` 中已配置对应目录。
