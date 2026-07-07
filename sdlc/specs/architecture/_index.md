# 架构

Trending Diggest：一条内容流水线的产出存储 + 索引（抓取 → 译读 → 归档 → 索引 → 增量去重）。

| 文件 | 内容 |
|------|------|
| [business.md](business.md) | 角色、跨功能业务约束、端到端流程 ASCII 图 |
| [system.md](system.md) | 技术栈、系统结构、模块、数据架构、外部依赖 |

## 架构决策记录（ADR）

<!-- 全局架构决策；Feature 级决策在 deliveries/D-xxx/design.md 中 -->

| ADR | 决策摘要 | 状态 | 日期 |
|-----|---------|------|------|
| ADR-001 | 本仓只承接产出物（markdown/JSON），自动化脚本与凭据归私有 coworkspace 仓 | active | 2026-06-29 |
| ADR-002 | 前端展示（trending.theuntold.io）不归本仓，归 theuntold 仓独立 SDLC 管理 | active | 2026-06-29 |
| ADR-003 | 多源架构：source 为可扩展维度，claude-blog 为首个实现 | active | 2026-06-29 |
