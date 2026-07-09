---
slug: editorial-design-unification
status: ready
priority: P1
type: functional
feature_type: functional
related_features: [aggregation-portal]
granularity: feature
created: 2026-07-09
updated: 2026-07-10
retriage_reason: baseline-pivot
prior_g1: superseded
---

## ⚠ 重新 Triage（2026-07-10，前次交付放弃后回退）

**前次交付（token-copy 方案）已放弃**，本条目回退 `ready → collected` 重新 triage。原 G1（2026-07-09）作废（`prior_g1: superseded`），须在放大后的雄心上重过 G1。

**为什么推翻**：原立意假设 gtd 姊妹站是对齐目标。实证 gtd 样式停在 2026-05-10 v2 快照，而 theuntold 主站经宽屏设计系统（2026-05-15）+ 站点编辑重设计（2026-06-17 上线）两轮重构 → **gtd 已过时**，三站若统一到 gtd 等于统一到过时基线。

**新雄心（Human 定，需重过 G1）**：把 trending 集群（门户 + claude-blog + **github-trending**）当**一等审美**，按主站"完整编辑重设计流程"（高保真原型锚点 → 三方 DoD 审 → 跨仓铺开）对齐 theuntold **当前**设计语言，而非机械抄 token。

**体量变化（G1 须在此基础重评 ROI）**：
- 三站全改（含 gtd，原以为已达标，实为过时）→ 跨 2 仓 + 已上线站。
- 主站 EditorialCard 是围绕其批判内容模型（判词/被审对象）设计，**字段 trending 用不上**——可迁移的是设计语言层（fluid clamp 字阶 / 容器解耦 / 全站左对齐 / 卡片等高 / 报纸质感 / tokens），需适配 trending 内容形态（数据摘要 / 译读长文 / 分析报告表格）。

**可复用输入（前次交付分支保留，勿重造）**：`.sdlc/worktrees/editorial-design-unification` 分支上的 portal-home + claude-blog 原型（theuntold token + light 默认 + dark 切换）、editorial-design-system behaviors、gtd-stale 实证、fluid-clamp/text-wrap 教训（主站宽屏设计系统 decisions）。

**待 G1 重评的关键问**：跨两仓做一等定制重设计（含 gtd 重做 + 136 天历史回归）值不值得现在做（P1）？还是拆分（先门户/claude-blog，gtd 单列后续）？

---

## Spec 交叉验证（triage）

- **相关 Feature**：aggregation-portal（单值 → related_features）
- **关键 Spec 证据**：
  - `specs/features/aggregation-portal/_index.md` 边界声明「拥有：本仓 Jekyll 站点骨架、门户首页、小源子站渲染」——门户/子站 UI 归本 Feature，本条目演化其 UI token 层。
  - `specs/features/aggregation-portal/ui/prototype.html` + `ui/views/pc-portal-home.md`：现原型用自造 token（`--bg/--surface/--pulse` 深色单模式），非 theuntold 共享契约——即本条目要改的现状。
  - `contracts.md`「视觉对齐 github-trending 卡片网格」——原意图是"对齐"，实际两套观感，本条目落实真正统一（对齐目标锁定为 theuntold 共享 editorial token，非 minima）。
- **判定**：功能增强（UI 视觉层演化，Spec 已含 UI 但 token 层需重定）——feature_type=functional，演化 aggregation-portal。
- **粒度**：Feature（Story>1，跨 2 仓，影响 >5 文件，github-trending 脱 minima 属结构性 UI 变更）。
- **github-trending 归属说明**：github-trending 内容归独立仓（aggregation-portal 边界"消费不拥有"），但本次对其**样式层**套统一 token 属跨仓实现细节，纳入本 Feature 的"三站统一"目标，不新增 Feature（1:1 铁律：related_features=[aggregation-portal] 单值）。

## 信源清单

<!-- sources-manifest:begin -->
### triage @ 2026-07-09
- specs：`features/aggregation-portal/_index.md`（边界）、`ui/prototype.html` + `ui/views/pc-portal-home.md`（现状 token）、`contracts.md`（视觉对齐原意）
- 复用源码：`projects/external/theuntold/src/layouts/BaseLayout.astro`（:root token SSoT）
- theuntold SDLC：`wide-screen-design-system` + `site-editorial-redesign` 交付 decisions/scope
<!-- sources-manifest:end -->

# trending 三站编辑重设计（对齐 theuntold 主站当前设计语言）

## 背景 / 问题

聚合门户上线后发现视觉割裂：`trending.theuntold.ai` 下 `/`（门户）+ `/claude-blog/`（子站）用**自造深色调色板**（`--bg #0e1116`/`--pulse`，仅 dark），`/github-trending/` 用其**过时 v2 快照**（2026-05-10）——同一域名观感不一，且**都落后于 theuntold 主站当前设计语言**（主站经宽屏设计系统 + 站点编辑重设计两轮重构）。"单一入口像一个站、且属主站设计家族"的定位立不住。

**根因**：门户原型自造 token；github-trending 停在旧 v2 未跟进主站两轮重构。

## 目标

trending 三站按 **theuntold 主站当前设计语言**做一等编辑重设计（light 纸感默认 + dark 可切，WCAG-AA），属同一设计家族：
- `/` 门户首页（trending-diggest）
- `/claude-blog/` 子站（trending-diggest）
- `/github-trending/` 大站（github-trending-digest，从 v2 升级到当前设计语言）

## 复用信源（theuntold）

> **照搬 vs 改造边界**（消歧，dc G1 提出）：token 值 / 字体分工 / decisions 教训 = **照搬不重造**（设计系统底料）；组件级结构（尤其 EditorialCard）= **按 trending 内容模型改造、不逐字复用**（主站 EditorialCard 绕判词/被审对象字段建，trending 无此模型）。即"借设计语言与底料，不搬内容专属组件"。

- **token SSoT**：`projects/external/theuntold/src/layouts/BaseLayout.astro` `:root` 块（light `#faf8f3` 纸底 + 琥珀 `#8b5e0c`；dark `#0b0c0f` + 琥珀 `#e8a820`）——12+ CSS 变量：`--bg-default/surface/elevated/hover`、`--border(-mid/-bright)`、`--fg-emphasis/default/muted/subtle`（附对比度）、`--accent-primary/dim/glow/line/info`、`--signal-*`、`--finding-*`。
- **字体分工**（theuntold 已定）：trending 站 body = Source Serif 4；标题 Noto Serif SC；mono JetBrains Mono。Google Fonts link 见 BaseLayout.astro:57。
- **设计经验**：theuntold SDLC 交付 `wide-screen-design-system`（容器分层 / fluid clamp typography / a11y focus-visible / 卡片 hover 去位移 / SVG noise）+ `site-editorial-redesign`（EditorialCard 组件 + tokens SSoT + 媒体报纸编辑语言）的 decisions/scope（见 theuntold `sdlc/deliveries/` 对应目录）。
- **共享契约声明**：theuntold wide-screen-design-system scope「与姐妹站 trending.theuntold.ai 共享 token 名保持一致」+ decisions「共享 token 契约 12 个 :root 变量」。

## 范围（重设计雄心，2026-07-10 重 triage）

对齐目标 = **theuntold 主站当前设计语言**（宽屏设计系统 + 站点编辑重设计两轮成果），非 gtd 过时 v2 快照、非机械抄 token。做法按主站编辑重设计流程：**高保真原型锚点 → 三方 DoD 审 → 跨仓铺开**。

- **可迁移设计语言层**（适配 trending 内容形态）：fluid clamp 字阶 / 容器与文本解耦 / 全站左对齐 chrome / 卡片等高底对齐 + hover 去位移 / 报纸质感（noise/rule line）/ a11y focus-visible / tokens（light 纸感默认 + dark）。**不照搬主站 EditorialCard**（其判词/被审对象字段 trending 用不上），只借设计系统骨架。
- **三站全改（Human 定：一次性）**：
  - trending-diggest 本仓：门户首页 + claude-blog（index + 长文页）。
  - github-trending-digest 跨仓：从旧 v2 升级到当前设计语言（layouts 重做）+ **136 天历史页（daily/weekly/monthly）回归**。
- **共享设计系统单一来源**：tokens + 字阶 clamp + 卡片/chrome patterns 抽为可复用 CSS（本仓 include；跨仓按各自约定同步）。
- 跨仓上线（两仓 Pages 重建）；Worker 反代不变。

## 已知风险（供重 G1）

- **跨两仓 + 已上线站**：改动可见于生产；需原子上线协调。
- **gtd 从 v2 升级 = 全量回归**：136 天历史 daily/weekly/monthly + 现有 layouts。
- **一等重设计工作量**：高保真原型 + 三方审 + 三种内容形态（门户卡片 / 长文 / 分析报告表格）各自版式，周期显著长于 token-copy。
- **设计语言适配非照搬**：需判断主站哪些 pattern 迁移、哪些因内容模型不同要改造——判断成本。

## Intake 覆盖账本

| 五问维度 | 覆盖 | 内容 |
|------|------|------|
| 用户 | covered | trending.theuntold.ai 深度读者（跨 `/`↔`/github-trending/`↔`/claude-blog/` 浏览观感一致、3 秒识别同一站、感知与主站同一设计家族）|
| 场景 | covered | 单一入口域下门户/子站/大站间跳转；light/dark 切换 |
| 任务 | covered | 三站按主站当前设计语言做一等编辑重设计（非抄 token）：统一字阶/卡片/chrome/tokens，适配 trending 内容形态 |
| 成功判据 | covered | 三站视觉统一且属主站设计家族；WCAG AA 不退化；gtd 136 天历史无回归；light 默认 + dark 可切；有高保真原型经三方 DoD 审作锚点 |
| 边界 | covered | 纯视觉 + IA + 组件层（不改业务逻辑/数据/路由/Worker）；不改内容；不引第三方 UI 框架 |

## G1 Review — 值不值得做（重审 2026-07-10，passed）

> 前次 G1（2026-07-09）基于"抄 token"小方案通过，已随交付放弃作废（`prior_g1: superseded`）。本条目在"完整重设计"放大体量上**重过 G1**。

- **结论**：passed（Human 2026-07-10 批准 → 拉入 Delivery）。
- **dc:qualify（gate-teeth 前置）**：adversarial audit（L1+L2 falsify）→ dossier `audit-dossier.json`。一致性 finding（旧 token-copy 框架残留）已修；falsify round 的 F1/F2（G1 裁决未留痕 / status 未推进）由本 Q&A + status→ready 消解；validation_probe（"ROI 悬空即过 G1"）由下方 ROI Q&A 正面裁决驳倒。
- **Q&A 留痕**：
  - **Q（scope 边界）**：放大后拆不拆？ **A**：不拆——三站一次性重设计（含 gtd 跨仓 + 136 天回归）。G1 不重开此项。
  - **Q（ROI 主问，falsify probe 正面回应）**：此放大体量（跨两仓 + gtd 全量升级 + 136 天历史回归 + 高保真原型三方审 + 三种内容形态各自版式，周期显著长于 token-copy、生产可见）下，值得 P1 现在投入吗？ **A**：值得，现在做（Human 选 "passed—拉入 Delivery"）。理由：门户刚上线即暴露割裂 + 三站均落后主站设计家族，趁热改品牌一致性成本最低；体量已诚实披露、scope 已收敛，放弃分支的原型/behaviors/教训作复用输入降低返工。
- **可复用输入**（前次交付分支保留）：portal + claude-blog theuntold-token 原型、editorial-design-system behaviors、gtd-stale 实证、fluid-clamp/text-wrap 教训。
- **信源精度（dc F3 minor）**：gtd 末次样式 commit `e4a7fb5 2026-05-10`；theuntold 宽屏设计系统交付 `bee4d65/dfdfaba 2026-05-15`；站点编辑重设计上线 `e397398 2026-06-17`（均 theuntold/gtd 仓 `git log` 可核，非推断）。

## Stories（重设计雄心，refine 细化）

- US-01 提炼 trending 适用设计语言 + 产高保真门户原型作锚点（对齐主站宽屏/编辑设计系统，三方 DoD 审）
- US-02 共享设计系统 CSS 单一来源（tokens light+dark / 字阶 clamp / 卡片·chrome patterns / a11y）
- US-03 门户首页编辑重设计（hero 版式 + editorial 卡片网格，fluid clamp/容器解耦/左对齐）
- US-04 claude-blog 索引 + 长文页重设计（长文阅读版式对齐设计家族）
- US-05 github-trending 从 v2 升级到当前设计语言（layouts 重做）
- US-06 跨站一致性核验 + light/dark 机制三站统一（同 token/字阶/卡片语言）
- US-07 github-trending 136 天历史页回归 + 全站 WCAG AA 不退化
