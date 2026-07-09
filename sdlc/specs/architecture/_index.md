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
| ADR-001 | 本仓承接产出物（markdown/JSON）；抓取/译读脚本与凭据仍归私有 coworkspace 仓 | active | 2026-06-29 |
| ADR-002 | ~~前端展示不归本仓~~ | **superseded by ADR-004** | 2026-06-29 |
| ADR-003 | 多源架构：source 为可扩展维度，claude-blog 为首个实现 | active | 2026-06-29 |
| ADR-004 | 本仓升级为**聚合入口宿主**：自建 Jekyll 站渲染门户首页 + 同仓小源子站；对外域 `trending.theuntold.ai`（推翻 ADR-002）。详见 aggregation-portal Feature | active | 2026-07-07 |
| ADR-005 | 单域多仓路径聚合经 **CF Worker 边缘反代**（github-trending 大站运行时挂入），不用 submodule、不跨仓拷贝；Worker 代码归 theuntold 仓 | active | 2026-07-07 |
