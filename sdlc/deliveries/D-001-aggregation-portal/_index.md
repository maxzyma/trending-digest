---
delivery: D-001
features_affected: ["aggregation-portal"]
feature_type: functional
branch: "D-001-aggregation-portal"
created: 2026-07-07
updated: 2026-07-07
lifecycle: in_progress

phases:
  define: done
  design: pending
  implement: pending
  verify: pending
  deliver: pending

define_summary:
  behaviors_generated: [SC-01, SC-02, SC-03, SC-04, SC-05, SC-06, SC-07, SC-08, SC-09, SC-10, SC-11, SC-12, SC-13, SC-14, SC-15, SC-16, SC-17, SC-18, SC-19, SC-20, SC-21, SC-22, SC-23, SC-24, SC-25]
  behaviors_count: 25
  has_ui: true

gates:
  g1:
    status: passed
    decided_at: 2026-07-07
    review_doc: stories.md
    spec_commit: "1394277"
  g2:
    status: passed
    decided_at: 2026-07-07
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

### G2 Review — Spec 完整性（2026-07-07，passed）

- **结论**：passed（Human 批准 → 进 Design）。
- **产出**：6 Story → 25 SC（每 Rule 正常/边界/错误三类）+ 路由/301 契约 + 实体（SourceCard/DigestEntry/RedirectRule）+ 首页 UI（views + scene-registry + prototype，对齐 github-trending 观感）。
- **dc:qualify define-review**：多轮收敛 → pass。同族审查经 3 处（legacy-redirect 收敛）→ 全特性对抗审查（4 条真 finding）→ 定点确认，均闭合。
- **自审实绩（Human 三次要求"再审一轮"逼出）**：① 裸 `/` 语义冲突裁决（`/`=门户 200、301 仅内容子路径）② US-05 AC-2 permalink 就地枚举 ③ 补 6 条 @error ④ 去 SC-19/25 跨层与实现细节 ⑤ INV-03 降为架构约束（平台事实非可断言不变量）⑥ SC-20/22 改为可观测 ⑦ SC-08 条数配置化 ⑧ SC-21 字段枚举对齐 entities。
- **Q&A 留痕**：
  - **Q**: Spec 展开完整、可进入 Design 吗？ **A**: 通过。同族审查已穷尽、内部自洽；继续同族轮为回声非新信号（cross-family 升级选项 Human 未取）。
  - **Q**: 两项偏差（prototype-meta warning / 未产 product-tests.md）如何处置？ **A**: 都接受——meta 校验是 yxt 专用机制不适用本 Jekyll 站；AC 已在 25 behaviors 充分编码。
- **偏差登记**：① prototype-meta 校验 warning（yxt 专用，本项目不适用，未伪造元数据）② 未单独产 product-tests.md（step 2.5，AC 已编码进 behaviors）③ AC-2「旧首页根」二义裁决写在 spec 侧（Rule 注释+contracts），stories.md 为上游输入未改。
- **跨仓提示**：交付物 3 仓（本仓 US-00~03 / theuntold Worker US-04~05 / github-trending baseurl），G5 release-plan 须分仓列。
