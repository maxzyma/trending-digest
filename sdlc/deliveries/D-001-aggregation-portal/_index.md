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
  design: done
  implement: done
  verify: pending
  deliver: pending

implementation:
  unit_tests: { total: 22, passed: 22, failed: 0 }
  coverage: "worker ALG-01/02 全 SC; jekyll 经 docker 真实构建 + 结构断言"
  files_changed: 18
  behaviors_covered: [SC-01, SC-02, SC-03, SC-04, SC-05, SC-06, SC-07, SC-08, SC-09, SC-10, SC-11, SC-12, SC-13, SC-14, SC-15, SC-16, SC-17, SC-18, SC-19, SC-20, SC-21, SC-22, SC-23, SC-24, SC-25, SC-26, SC-27]
  code_review:
    antipatterns: "10/10"
    dimensions: "8/8"
    traps: "5/5"
    critical: 0
    report_path: code-review-report.md
  notes: "跨 3 仓（trending-diggest 001~004 / github-trending-digest 006 / theuntold 005/007）。SC-02/03 + 部分 SC-14/15/24 的 live CF 层验证 defer 到 cutover（contracts live-CF 层）。TASK-008 live cutover = post-G5 部署。"

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
    status: passed
    decided_at: 2026-07-07
    review_doc: decisions.md
  g4:
    status: pending
    review_doc: validation-report-local-20260708-1215.md
  g5:
    status: pending

verification:
  cross_feature_regression:
    features_checked: 0
    cases_run: 0
    failed: 0
    note: "aggregation-portal 为项目唯一 feature，无跨 feature 回归对象（N/A）"
  traceability:
    behaviors_total: 27
    behaviors_covered: 24
    deferred_live: 3
    extension_tc_total: 0
    extension_tc_run: 0
    excess_code: false
  loop_count: 0
  loop_history: []
  flaky: []
  stages:
    - stage: 1
      env: local
      api_pass_rate: "39/39"
      ui_pass_rate: "N/A"
      released: false
      release_reason: null
      cross_feature_pass: "N/A"
      na_reasons:
        api: null
        ui: "门户无交互；结构性 TC-UI 已由 verify-build.sh 断言；live 渲染 defer cutover（Step 3.7 用户跳过）"
        cross_feature: "唯一 feature，无回归对象"
      report_paths:
        api: "theuntold tests/unit/trending-proxy + trending-diggest scripts/verify-build.sh"
        ui: null
        cross_feature: null
  live_deferred:
    - "SC-02 CNAME/DNS 域名解析（cutover 时 agent-browser 验，runbook §6）"
    - "SC-03 域名 live 渲染链路连通"
    - "SC-15 GoatCounter 运行时上报 path 前缀（build 侧 baseurl 前缀已验）"

blockers:
  - description: "跨仓交付物地基未验证：TASK-005/007（theuntold Worker 反代+301）、TASK-006（github-trending baseurl）、TASK-008（CF DNS 切换）落兄弟仓，需两仓当前态 + Worker/CF 部署凭据 + runbook §6；implement 前须跨仓协调。原子上线顺序（防 DNS 先切断服）见 tasks.md TASK-008。"
    category: external-dependency
    since: 2026-07-07
    skill: design
    source_exhaustion:
      - "tasks.md: TASK-005/006/007/008 已记跨仓依赖 + 地基未验证 + 原子上线顺序 + Gate（read）"
      - "decisions.md ADR-001: Worker 代码归 theuntold 仓（read）"
    refutation:
      attempted: false
      note: "非结论型阻塞——单仓 task（001~004）可先开工；此为已知 implement 前跨仓协调项，非 AI 判定不可行，无需驳斥"
---

# D-001 聚合门户（aggregation-portal）

单一入口 `trending.theuntold.ai` 聚多源：本仓（trending-diggest）自建 Jekyll 门户 + 小源子站，github-trending 经 CF Worker 反代挂入。交付物分布 3 仓（本仓 US-00~03 / theuntold Worker US-04~05 / github-trending baseurl）。

Backlog 来源：`sdlc/backlog/aggregation-portal/`（G1 passed 2026-07-07，theuntold 侧 G1 作输入）。

### G3 Review — 技术方案（2026-07-07，passed）

- **结论**：passed（Human 批准 → 进 Implement）。
- **方案**：CF Worker 边缘反代 + 本仓 Jekyll 门户/小源 collection；ADR-001~004（全 Accepted）；ALG-01 路由/ALG-02 301/ALG-03 最新流；tasks 8 个（本仓 4 + 跨仓 4，DAG 无环）；测试设计单分片 27 SC。
- **审查深度（三家两族）**：① 同族 dc design-review 多轮收敛 pass；② 全产物对抗审查 6 条真 finding（SC-03/20 漏 covers、DNS 断服、硬下限计数、ALG-01 3xx、GoatCounter、跨仓 blocker）；③ **codex 跨家族审查** 1 P0（TASK-005↔008 循环依赖，自审修复时引入）+ 9 条 Cloudflare 盲点（Worker 递归/502、无尾斜杠、prefix 越界、CF 橙云 DNS 断言、404 误当故障、query 丢失、live-CF 测试层），全部修复确认。
- **Q&A 留痕**：
  - **Q**: 技术方案可行、可进 Implement 吗？ **A**: 通过。两家族均审、共修 10+ 真问题、DAG 无环、内部自洽。
  - **Q**: 是否继续加审（gemini/再 codex）？ **A**: 两家族已覆盖、边际收益递减，不再加审。
- **不可逆决策**：本仓职责扩张（数据仓→展示宿主，全局 ADR-002 superseded）；trending.theuntold.ai 域从 github-trending 切到本仓（DNS 原子顺序防断服已定）。
- **跨仓风险**：交付物 3 仓，跨仓地基未验证已登 blockers[]（external-dependency），implement 前须协调 + Worker/CF 凭据。

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

<!-- change-ledger:begin -->
## 本交付变更清单

> `9f34744...9f9bd0c` @ 2026-07-07 · 机械派生，手工编辑会被覆盖

**specs 变更**：

| 变更 | 文件 |
|------|------|
| 修改 | [_index.md](../../specs/architecture/_index.md) <!-- sdlc/specs/architecture/_index.md --> |
| 新增 | [_index.md](../../specs/features/aggregation-portal/_index.md) <!-- sdlc/specs/features/aggregation-portal/_index.md --> |
| 新增 | [algorithms.md](../../specs/features/aggregation-portal/algorithms.md) <!-- sdlc/specs/features/aggregation-portal/algorithms.md --> |
| 新增 | [_index.md](../../specs/features/aggregation-portal/behaviors/_index.md) <!-- sdlc/specs/features/aggregation-portal/behaviors/_index.md --> |
| 新增 | [github-trending-proxy.gherkin](../../specs/features/aggregation-portal/behaviors/github-trending-proxy.gherkin) <!-- sdlc/specs/features/aggregation-portal/behaviors/github-trending-proxy.gherkin --> |
| 新增 | [latest-stream.gherkin](../../specs/features/aggregation-portal/behaviors/latest-stream.gherkin) <!-- sdlc/specs/features/aggregation-portal/behaviors/latest-stream.gherkin --> |
| 新增 | [legacy-redirect.gherkin](../../specs/features/aggregation-portal/behaviors/legacy-redirect.gherkin) <!-- sdlc/specs/features/aggregation-portal/behaviors/legacy-redirect.gherkin --> |
| 新增 | [portal-homepage.gherkin](../../specs/features/aggregation-portal/behaviors/portal-homepage.gherkin) <!-- sdlc/specs/features/aggregation-portal/behaviors/portal-homepage.gherkin --> |
| 新增 | [site-skeleton.gherkin](../../specs/features/aggregation-portal/behaviors/site-skeleton.gherkin) <!-- sdlc/specs/features/aggregation-portal/behaviors/site-skeleton.gherkin --> |
| 新增 | [small-source-subsite.gherkin](../../specs/features/aggregation-portal/behaviors/small-source-subsite.gherkin) <!-- sdlc/specs/features/aggregation-portal/behaviors/small-source-subsite.gherkin --> |
| 新增 | [contracts.md](../../specs/features/aggregation-portal/contracts.md) <!-- sdlc/specs/features/aggregation-portal/contracts.md --> |
| 新增 | [entities.md](../../specs/features/aggregation-portal/entities.md) <!-- sdlc/specs/features/aggregation-portal/entities.md --> |
| 新增 | [review-report.md](../../specs/features/aggregation-portal/test/all/review-report.md) <!-- sdlc/specs/features/aggregation-portal/test/all/review-report.md --> |
| 新增 | [test-cases.md](../../specs/features/aggregation-portal/test/all/test-cases.md)（未提交） <!-- sdlc/specs/features/aggregation-portal/test/all/test-cases.md --> |
| 新增 | [test-points.md](../../specs/features/aggregation-portal/test/all/test-points.md) <!-- sdlc/specs/features/aggregation-portal/test/all/test-points.md --> |
| 新增 | [prototype.html](../../specs/features/aggregation-portal/ui/prototype.html) <!-- sdlc/specs/features/aggregation-portal/ui/prototype.html --> |
| 新增 | [scene-registry.md](../../specs/features/aggregation-portal/ui/scene-registry.md) <!-- sdlc/specs/features/aggregation-portal/ui/scene-registry.md --> |
| 新增 | [_index.md](../../specs/features/aggregation-portal/ui/views/_index.md) <!-- sdlc/specs/features/aggregation-portal/ui/views/_index.md --> |
| 新增 | [pc-portal-home.md](../../specs/features/aggregation-portal/ui/views/pc-portal-home.md) <!-- sdlc/specs/features/aggregation-portal/ui/views/pc-portal-home.md --> |

**本 delivery 产物**：

| 变更 | 文件 |
|------|------|
| 新增 | [audit-dossier.json](audit-dossier.json)（未提交） <!-- sdlc/deliveries/D-001-aggregation-portal/audit-dossier.json --> |
| 新增 | [decisions.md](decisions.md) <!-- sdlc/deliveries/D-001-aggregation-portal/decisions.md --> |
| 新增 | [gate-audit-record.json](gate-audit-record.json)（未提交） <!-- sdlc/deliveries/D-001-aggregation-portal/gate-audit-record.json --> |
| 新增 | [scope.md](scope.md) <!-- sdlc/deliveries/D-001-aggregation-portal/scope.md --> |
| 新增 | [tasks.md](tasks.md)（未提交） <!-- sdlc/deliveries/D-001-aggregation-portal/tasks.md --> |

<!-- change-ledger:end -->
