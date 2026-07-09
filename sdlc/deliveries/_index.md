# Deliveries Index

> Delivery 生命周期账本（manifest）。每次 Delivery 经 G1 追加 Active、G5 merge 后移入 Completed。

## Active

| Delivery | Feature | 类型 | lifecycle | feature_branch | updated |
|---|---|---|---|---|---|
| _（无）_ | | | | | |

## Abandoned

| Delivery | Feature | 类型 | lifecycle | feature_branch | updated | 原因 |
|---|---|---|---|---|---|---|
| D-002-editorial-design-unification | aggregation-portal | functional | abandoned | D-002-editorial-design-unification | 2026-07-10 | 对齐基线判断错误（gtd 已过时 vs theuntold post-D-018）；改按完整重设计流程 → 回 Supply 重过 G1。分支不 merge，产物留作参考输入 |

## Completed

| Delivery | Feature | 类型 | lifecycle | feature_branch | updated |
|---|---|---|---|---|---|
| D-001-aggregation-portal | aggregation-portal | functional | done | D-001-aggregation-portal | 2026-07-09 |
