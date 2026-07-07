---
delivery: D-001
features_affected: ["aggregation-portal"]
feature_type: functional
branch: "D-001-aggregation-portal"
created: 2026-07-07
updated: 2026-07-07
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
    decided_at: 2026-07-07
    review_doc: stories.md
    spec_commit: "1394277"
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

# D-001 聚合门户（aggregation-portal）

单一入口 `trending.theuntold.ai` 聚多源：本仓（trending-diggest）自建 Jekyll 门户 + 小源子站，github-trending 经 CF Worker 反代挂入。交付物分布 3 仓（本仓 US-00~03 / theuntold Worker US-04~05 / github-trending baseurl）。

Backlog 来源：`sdlc/backlog/aggregation-portal/`（G1 passed 2026-07-07，theuntold 侧 G1 作输入）。
