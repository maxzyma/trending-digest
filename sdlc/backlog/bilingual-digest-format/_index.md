---
schema_version: 1
slug: bilingual-digest-format
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

# 中文双语译读 markdown 格式契约

## Intake 覆盖账本（五问留痕）

| 五问 | 状态 | 覆盖来源 |
|------|------|---------|
| 用户 | covered | 中文技术读者（消费译读）；下游站点/钉钉（解析 markdown） |
| 场景 | covered | 抓取后将原文转为中文双语译读 markdown 归档（business.md 流程） |
| 任务 | covered | 定义 posts/ markdown 的双语结构与元数据契约（system.md 译读归档模块） |
| 成功判据 | covered | 译读 markdown 对下游可解析、双语结构一致（下方期望成果） |
| 边界 | covered | 只译公开内容；译读生成实现归 coworkspace（brief.md 约束） |

---

## 问题陈述

**现状**：`posts/{year}/{month}/*.md` 已存在中文双语译读，但其结构（双语段落、元数据头、原文链接位置）只由实现约定，未在本仓规格化。
**问题**：格式是下游（theuntold 站点、钉钉文档）的解析契约，无规格则变更易破坏下游。
**受影响用户**：中文技术读者、下游消费方。

---

## 期望成果

规格化译读 markdown 的双语结构与元数据契约，作为下游解析的稳定基准。
**可观测的成功信号**：新生成的 post 符合契约；下游能稳定解析标题/分类/原文链接/双语正文。

---

## 影响分析

**业务影响**：高 — 直接决定读者阅读体验与下游可用性。
**技术风险**：中 — 译读生成在 coworkspace，本仓定义产物格式契约。
**依赖关系**：依赖 claude-blog-ingestion（先有抓取才有译读）。
**粗粒度估算**：Feature。

---

## DoD 检查清单

- [x] 有清晰目标 + 业务价值 + 优先级
- [x] 有影响分析（依赖关系已识别）
- [x] 无 Feature 冲突（与已有 Feature 不重叠）

<!-- 关联 Feature ID（进入 Define 后分配）：待分配 -->
