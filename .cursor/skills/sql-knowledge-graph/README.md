# Cursor Skill：sql-knowledge-graph

本目录为 **SQL 知识图谱** 的 Agent Skill。若仓库根下**尚未**包含 `backend/`、`frontend/` 等实现，请先按 **`运行与搭建命令手册.md`** 从团队参考实现目录复制代码后再运行；若已配套完整工程，则 Skill 与 `开发说明文档.md` 等交叉对照使用即可。

## 文件说明

| 文件 | 作用 |
|------|------|
| `SKILL.md` | **主 Skill**：触发描述、跨仓库规范、落地顺序 |
| `reference.md` | JSON 字段、可选模块、本仓库源文件索引 |
| `examples.md` | 最小 SQL 与响应结构示例 |
| `运行与搭建命令手册.md` | **仅有 Skill 文档时**：从参考实现复制前后端与数据、venv、启动与浏览器验证的逐步命令（Windows PowerShell） |
| `README.md` | 本说明 |

## 安装到 Cursor

- **本仓库协作**：路径已在 `.cursor/skills/sql-knowledge-graph/`，团队成员克隆后即可被 Cursor 按项目 Skill 加载（具体以 Cursor 版本对项目 skills 的扫描规则为准）。
- **个人全局复用**：可将整个 `sql-knowledge-graph` 文件夹复制到用户目录下的 Cursor skills 位置（勿放入 `~/.cursor/skills-cursor/`，该目录为 Cursor 内置保留）。

## 维护建议

修改解析规则或 API 契约时，请同步更新 `SKILL.md` / `reference.md` / `examples.md`，并与根目录 `开发说明文档.md`、`README.md` 保持一致。
