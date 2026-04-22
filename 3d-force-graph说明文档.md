# 电解铝 3D 知识图谱说明（3d-force-graph）

## 1. 改造目标

将电解铝板块从 2D 力导图升级为 3D 视图，利用 Z 轴缓解拥挤，提升数据流向观察效率。

## 2. 当前稳定版本（已验证）

以下组合已在当前项目环境验证可用，请固定使用：

- `three@0.126.1`
- `3d-force-graph@1.70.0`

加载策略：

- 优先本地静态：`frontend/vendor/three.min.js`、`frontend/vendor/3d-force-graph.min.js`
- 失败后回退 `jsdelivr` 同版本 CDN

## 3. 页面与文件

- 3D 页面入口：`frontend/index.html`
- 3D 逻辑：`frontend/js/app-3d.js`
- 样式：`frontend/css/styles.css`
- 本地依赖目录：`frontend/vendor/`

> 其他板块（`ao.html`、`rd.html`、`pur.html`）仍使用原 2D 页面。

## 4. 渲染与交互

- 背景色：`#111`
- 初始化方式：`ForceGraph3D()(graphWrap)`（官方推荐调用）
- 支持操作：旋转、缩放、平移、节点拖拽
- 节点交互：
  - 悬停显示 tooltip（表名、层级、关联数）
  - 点击节点相机飞行聚焦
- 功能交互：
  - 层级筛选（ODS / DIM / DWD / ADS）
  - 搜索框回车定位
  - 自动旋转开关
  - 刷新按钮重新拉取 `/api/graph`

## 5. 数据接口约定

- 请求：`GET /api/graph?sector=PRD_AL`
- 节点字段：`id`, `name`, `layer`(可缺省), `relationCount/relation_count`
- 边字段：`source`, `target`, `relationType`
- `layer` 缺省时按表名前缀推断：`ods_`/`dim_`/`dm_`/`dwd_`/`dws_`/`ads_`

## 6. 前端最小 Smoke Test

每次升级依赖或调整 3D 脚本后，至少执行一次以下验证：

1. 启动服务并打开 `frontend/index.html`
2. 强刷页面（`Ctrl+F5`）
3. 检查顶部统计是否满足：`节点数 > 0` 且 `边数 > 0`
4. 鼠标左键拖拽场景，确认图可旋转
5. 滚轮缩放，确认镜头远近变化正常
6. 搜索任一已知表名并回车，确认可定位到对应节点

判定标准：

- 通过：能看到 3D 节点和连线，且可旋转/缩放
- 失败：黑屏、节点数为 0、或无法旋转/缩放
