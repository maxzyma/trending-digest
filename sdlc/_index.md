---
bootstrap_status: completed
sdlc_version: "v2"
spec_maturity: "L2"
updated: "2026-06-29"
---

# Trending Diggest — 项目仪表盘

<!-- 项目级文档：由 /sdlc:setup 创建，/sdlc:progress 读取并更新 -->

## Backlog 活跃项

> 详见 `backlog/_index.md`

| slug | 标题 | 优先级 | 状态 |
|------|------|--------|------|
| claude-blog-ingestion | Claude 博客增量抓取 + 幂等去重 | P1 | collected |
| bilingual-digest-format | 中文双语译读 markdown 格式契约 | P1 | collected |
| archive-index-maintenance | 归档目录结构 + index.md 索引维护 | P2 | collected |
| aggregation-portal | 聚合门户（trending.theuntold.ai 单入口聚多源；迁自 theuntold G1 passed，6 stories） | P1 | triaged |

## G0 Review — Bootstrap 基线（Greenfield）

- **日期**：2026-06-29
- **结论**：passed（Human 确认）
- **基线**：specs/ 全局层骨架齐全（brief / architecture business+system / nfr-baseline / concepts / references；ui/ 待聚合门户 Define 阶段新增）；Backlog 4 条（3 条数据流水线 collected；aggregation-portal triaged/P1——归属已定论迁入本仓，含 6 stories + theuntold G1 历史）
- **Q&A 留痕**：
  - Q1 本仓 specs 定位 = 产物对外契约（实现脚本在 coworkspace，本仓不含实现验证）→ Human 认可。
  - Q2 前端迁移条目挂起为 collected + intake_skipped（阻塞待 theuntold 讨论结论）→ Human 认可。
- **风险记录**：① 能力条目实现在 coworkspace，跨仓对齐验证方式；② 前端迁移结论会改变本仓职责边界、可能反向影响 architecture 基线。

## 快速导航

| 目标 | 路径 |
|------|------|
| 产品规格索引 | `specs/_index.md` |
| 产品定义 | `specs/brief.md` |
| 系统架构 | `specs/architecture/_index.md` |
| Delivery 索引 | `deliveries/_index.md` |
| Backlog | `backlog/_index.md` |
