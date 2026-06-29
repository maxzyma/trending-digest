---
schema_version: 1
slug: claude-blog-ingestion
status: collected
priority: P1
feature_type: functional
related_features: []
created_at: "2026-06-29"
updated_at: "2026-06-29"
assigned_to: null
notified_at: null
delivery_ref: null
parent: null
intake_skipped: false
artifacts:
  stories:
    path: stories.md
    role: 用户故事（refine 产出）
  discussions: []
---

# Claude 博客增量抓取 + 幂等去重

## Intake 覆盖账本（五问留痕）

| 五问 | 状态 | 覆盖来源 |
|------|------|---------|
| 用户 | covered | 中文技术读者 + 下游消费方（setup 对话 + brief.md 目标用户） |
| 场景 | covered | 源站更新后定时增量抓取（business.md 端到端流程） |
| 任务 | covered | 抓原文存 raw、按 processed.json 去重（system.md 抓取/去重模块） |
| 成功判据 | covered | 重复运行不新增产物；新文章下次被抓（下方期望成果） |
| 边界 | covered | 仅公开可访问内容；抓取脚本/凭据归 coworkspace（brief.md 约束） |

---

## 问题陈述

**现状**：Claude 官方博客持续更新，靠人工跟读外文成本高、易漏。当前已有产物（`raw/`、`posts/`、`state/processed.json`）由 coworkspace 脚本生成，但抓取去重的行为契约未在本仓规格化。
**问题**：缺少形式化的"已处理 URL 不重复抓取"契约，幂等行为只存在于实现，规格无法作为验收基准。
**受影响用户**：中文技术读者（漏读/重复）、下游消费方（重复索引行）。

---

## 期望成果

规格化 source 抓取 + 增量去重行为：以 `state/processed.json` 为去重真相，新 URL 抓原文存 `raw/{year}/{month}/`，已处理 URL 跳过。
**可观测的成功信号**：重复运行不新增 raw 文件、不新增 processed 条目；新文章发布后下次运行被抓取归档。

---

## 影响分析

**业务影响**：高 — 这是整条流水线的入口与幂等保证。
**技术风险**：中 — 抓取实现在 coworkspace 仓，本仓只定义产物契约，需跨仓对齐。
**依赖关系**：与 bilingual-digest-format、archive-index-maintenance 强相关（同一流水线）。
**粗粒度估算**：Feature。

---

## DoD 检查清单

- [x] 有清晰目标 + 业务价值 + 优先级
- [x] 有影响分析（依赖关系已识别）
- [x] 无 Feature 冲突（与已有 Feature 不重叠）

<!-- 关联 Feature ID（进入 Define 后分配）：待分配 -->
