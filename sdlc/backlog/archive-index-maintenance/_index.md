---
schema_version: 1
slug: archive-index-maintenance
status: collected
priority: P2
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

# 归档目录结构 + index.md 索引维护

## Intake 覆盖账本（五问留痕）

| 五问 | 状态 | 覆盖来源 |
|------|------|---------|
| 用户 | covered | 中文技术读者（检索）；下游站点（消费 index） |
| 场景 | covered | 每次新增 post 后更新 index.md 索引表（business.md 流程） |
| 任务 | covered | 维护 年/月 目录结构 + index 行与文件/state 三方一致（system.md 索引维护模块） |
| 成功判据 | covered | index 每行对应实际 post 文件，无失效链接（concepts CI-002） |
| 边界 | covered | 只索引本仓归档；不含前端展示（brief.md 排除项） |

---

## 问题陈述

**现状**：`index.md` 索引表与 `posts/` 目录结构已存在，但维护规则（排序、字段、与 processed.json/文件的一致性）未规格化。
**问题**：索引与实际文件、去重账本三者一致性靠人工/脚本保证，无形式化契约则易漂移（失效链接、重复行）。
**受影响用户**：检索的读者、消费 index 的下游。

---

## 期望成果

规格化归档目录结构与 index.md 维护规则，保证 index ↔ posts 文件 ↔ processed.json 三方一致。
**可观测的成功信号**：index 无失效链接、无重复行；目录结构按 年/月 稳定。

---

## 影响分析

**业务影响**：中 — 影响可检索性与下游一致性。
**技术风险**：低 — 纯产物结构与一致性约束。
**依赖关系**：依赖 claude-blog-ingestion、bilingual-digest-format。
**粗粒度估算**：Feature。

---

## DoD 检查清单

- [x] 有清晰目标 + 业务价值 + 优先级
- [x] 有影响分析（依赖关系已识别）
- [x] 无 Feature 冲突（与已有 Feature 不重叠）

<!-- 关联 Feature ID（进入 Define 后分配）：待分配 -->
