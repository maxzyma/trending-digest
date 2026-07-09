---
delivery: D-002
features_affected: ["aggregation-portal"]
feature_type: functional
branch: "D-002-editorial-design-unification"
created: 2026-07-09
updated: 2026-07-09
lifecycle: in_progress

phases:
  define: in_progress
  design: pending
  implement: pending
  verify: pending
  deliver: pending

gates:
  g1:
    status: passed
    decided_at: 2026-07-09
    review_doc: stories.md
    spec_commit: "de40037"
  g2:
    status: pending
  g3:
    status: pending
  g4:
    status: pending
  g5:
    status: pending

blockers: []
---

# D-002 三站统一 editorial 设计系统（editorial-design-unification）

聚合门户 D-001 上线后视觉割裂（门户/子站自造深色 vs github-trending minima 浅色）。本交付把三站统一到 **theuntold 已建立的共享 editorial design-token 系统**（light 纸感默认 + dark 可切，WCAG-AA），复用而非重造。

Backlog 来源：`sdlc/backlog/editorial-design-unification/`（G1 passed 2026-07-09）。演化 aggregation-portal 的 UI token 层 + 跨仓套 github-trending 样式。
