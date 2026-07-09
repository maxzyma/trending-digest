---
shard: all
reviewed: 2026-07-07
---

# Test Review: 聚合门户（单分片 all）

## 视角 A — 覆盖完整性

- SC-01~25 全部有 ≥1 TP 且 ≥1 TC，covers 并集 = SC 全集，无缺口、无悬挂引用。
- 每 Rule 三类（正常/边界/错误）均有 TC。
- form 硬下限：api 14 ≥ 契约条目；ui 11 ≥ 页面数（1）。均通过。

## 视角 B — 用例质量

- 每条 TC 断言可观测（HTTP 状态码 / 渲染文本 / 构建退出码 / 日志关键词），无跨层实现细节残留（Design 自审轮已清理 SC-19/24/25）。
- 301 用例走 fixture 断言（旧 URL → 期望 301 目标 + 裸 / 反例 + 无匹配反例），符合 contracts fixture 契约。
- 上游不可用（TC-API-07）用 mock 502 注入，可自动化。
- error 类构建失败用例（TC-API-03/UI-05/09）用注入非法配置断言非零退出/告警，可自动化。

## idempotent 0 格

已在 test-cases.md 说明依据：纯静态 + 无写操作，幂等不适用；GET 反代/301 天然幂等。合理留空，非遗漏。

## Extension TC 复核

- 无 impact_map（全新站，无既有前端被波及）→ 无 EXT TC，合理。

## Pending Human Confirmation

- 无。测试点均可从 behaviors AC + contracts fixture 直接派生，无需 Human 补充测试信息。

（跨仓 task 005/006/007/008 的执行环境/凭据属 implement/verify 阶段前置，非测试设计缺口。）
