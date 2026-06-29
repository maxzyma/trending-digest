---
schema_version: 1
slug: frontend-migration-from-theuntold
status: collected
priority: P2
feature_type: new-feature
related_features: []
created_at: "2026-06-29"
updated_at: "2026-06-29"
assigned_to: null
notified_at: null
delivery_ref: null
parent: null
intake_skipped: true
artifacts:
  stories:
    path: stories.md
    role: 用户故事（refine 产出）
  discussions: []
---

# 前端 trending.theuntold.io 迁入本仓

> ⚠️ 阻塞中：迁移方案正在 theuntold 项目讨论，尚未定论。本条目仅登记未来工作，
> 待 theuntold 讨论给出迁移边界（迁哪些、技术栈、与归档产物的耦合方式）后再 triage/refine。
> intake_skipped: true —— 五问尚不齐全（依赖外部讨论结论），暂不可 ready。

## 问题陈述

**现状**：面向用户的展示站点 trending.theuntold.io 当前由 `projects/external/theuntold` 仓维护（独立 Astro 应用 + 自带 SDLC）。本仓只提供归档 markdown 作为数据源。
**问题**：theuntold 项目正在讨论把该前端**迁入本仓**，使数据源与展示同仓。迁移边界与技术形态未定。
**受影响用户**：中文技术读者（最终通过站点消费）。

---

## 期望成果

待 theuntold 讨论定论后明确：迁入范围、技术栈、与 `posts/`/`index.md` 归档产物的耦合关系；届时本仓 specs 新增 `ui/` 并作为一个 Feature 交付。
**可观测的成功信号**：迁移边界在 theuntold 侧达成结论，可转 triage。

---

## 影响分析

**业务影响**：中 — 改变本仓职责边界（从纯数据源 → 数据+展示）。
**技术风险**：高 — 跨仓迁移、技术栈引入、与 theuntold 既有 SDLC 的产物归属切分。
**依赖关系**：**阻塞于 theuntold 项目的迁移讨论结论**（外部）。
**粗粒度估算**：Feature。

---

## DoD 检查清单

- [ ] 有清晰目标 + 业务价值 + 优先级
- [ ] 有影响分析（依赖关系已识别）
- [ ] 无 Feature 冲突（与已有 Feature 不重叠）

<!-- 关联 Feature ID（进入 Define 后分配）：待分配 -->
