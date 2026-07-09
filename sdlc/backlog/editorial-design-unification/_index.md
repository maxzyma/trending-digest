---
slug: editorial-design-unification
status: collected
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

# 三站统一 editorial 设计系统（复用 theuntold 共享 token 契约）

## 背景 / 问题

聚合门户上线后发现视觉割裂：`trending.theuntold.ai` 下 `/`（门户）+ `/claude-blog/`（子站）用**自造深色调色板**（`--bg #0e1116`/`--pulse`，仅 dark），`/github-trending/` 用 **minima 浅色**——同一域名三种观感，"单一入口像一个站"的定位立不住。

**根因**：门户原型自造 token，没复用 theuntold 早已为姐妹站 `trending.theuntold.ai` 建立的共享 design-token 契约；github-trending 沿用 minima 从未对齐。

## 目标

三站统一到 **theuntold 共享 editorial design 系统**（light 纸感默认 + dark 可切，经 codex WCAG-AA 审）：
- `/` 门户首页（trending-diggest）
- `/claude-blog/` 子站（trending-diggest）
- `/github-trending/` 大站（github-trending-digest，替换 minima）

## 复用信源（theuntold，MUST 照搬不重造）

- **token SSoT**：`projects/external/theuntold/src/layouts/BaseLayout.astro` `:root` 块（light `#faf8f3` 纸底 + 琥珀 `#8b5e0c`；dark `#0b0c0f` + 琥珀 `#e8a820`）——12+ CSS 变量：`--bg-default/surface/elevated/hover`、`--border(-mid/-bright)`、`--fg-emphasis/default/muted/subtle`（附对比度）、`--accent-primary/dim/glow/line/info`、`--signal-*`、`--finding-*`。
- **字体分工**（theuntold 已定）：trending 站 body = Source Serif 4；标题 Noto Serif SC；mono JetBrains Mono。Google Fonts link 见 BaseLayout.astro:57。
- **设计经验**：theuntold SDLC 交付 `wide-screen-design-system`（容器分层 / fluid clamp typography / a11y focus-visible / 卡片 hover 去位移 / SVG noise）+ `site-editorial-redesign`（EditorialCard 组件 + tokens SSoT + 媒体报纸编辑语言）的 decisions/scope（见 theuntold `sdlc/deliveries/` 对应目录）。
- **共享契约声明**：theuntold wide-screen-design-system scope「与姐妹站 trending.theuntold.ai 共享 token 名保持一致」+ decisions「共享 token 契约 12 个 :root 变量」。

## 范围

- trending-diggest：`_layouts/portal-home.html` + `_layouts/claude-blog-post.html` + `claude-blog/index.html` 换 theuntold `:root` token（抽到共享 CSS include，Jekyll `_includes/` 或 `assets/css/`）；light 默认 + dark 切换。
- github-trending-digest：替换 minima → theuntold token 样式（其 `_layouts/{home,daily,weekly,default}.html`）；**136 天历史页（daily/weekly/monthly）回归验证**。
- 跨仓：两仓改动 + 上线（github-trending Pages 重建；门户 Pages 重建）；Worker 不变。

## 已知风险（供 triage/G1）

- github-trending 脱离 minima = 大改：136 天历史 daily/weekly/monthly 页 + 现有布局全量回归；minima 提供的默认排版要自建替代。
- 跨仓交付（trending-diggest + github-trending-digest 两仓 + 已上线站，改动可见于生产）。
- token 需同时适配三种内容形态（门户卡片网格 / claude-blog 长文 / github-trending 分析报告表格）。

## Intake 覆盖账本

| 五问维度 | 覆盖 | 内容 |
|------|------|------|
| 用户 | covered | trending.theuntold.ai 深度读者（跨 `/`↔`/github-trending/`↔`/claude-blog/` 浏览时观感一致、3 秒识别同一站）|
| 场景 | covered | 单一入口域下在门户/子站/大站间跳转；light/dark 切换 |
| 任务 | covered | 三站套用 theuntold 共享 editorial token（light 默认+dark）+ 一致字体/卡片/排版语言，替换门户自造调色板与 github-trending minima |
| 成功判据 | covered | 三站视觉统一（同 token/字体/卡片语言）；WCAG AA 不退化；github-trending 136 天历史页无回归；light 默认 + dark 可切 |
| 边界 | covered | 纯视觉 + 样式层（不改业务逻辑/数据/路由/Worker 反代）；不改内容；不引第三方 UI 框架（照搬 theuntold token，不重造设计） |

## G1 Review — 值不值得做（2026-07-09，passed）

- **结论**：passed（Human 批准 → 可拉入 Delivery）。
- **值/成本**：值 = 聚合门户"单一入口像一个站"的定位现被三种观感割裂，统一到 theuntold 已建的共享 editorial 系统即修复品牌一致性、复用现成 WCAG-AA 资产（不重造）；成本 = 跨 2 仓 + github-trending 脱 minima + 136 天历史回归。
- **Q&A 留痕**：
  - **Q**: 这个 UI 统一值不值得现在做（P1）？ **A**: 值。门户刚上线即暴露割裂，趁热改成本最低；复用 theuntold token 无设计重造成本。
  - **Q**: github-trending 一并改（大改 + 历史回归风险）还是先只做门户/子站？ **A**: 一并改（Human 选）。否则 `/github-trending/` 仍浅色割裂，"单一入口"不成立；风险由 US-05 历史回归验证 + 原子上线兜底。
  - **Q**: 对齐目标是 minima 浅色还是 theuntold editorial？ **A**: theuntold 共享 editorial token（light 纸感默认+dark）——这是 theuntold 当初就为本域名设计的归属，比 minima 更对。
- **自审**：dc G1 dossier（2 finding + 1 probe：只做门户/子站不足 → 三站全改）；复用信源已 grounding 到 theuntold BaseLayout.astro + 两交付 decisions。
- **粒度**：Feature（演化 aggregation-portal UI 层），5 stories，US-01/02/03/04 为 Walking Skeleton。

## Stories（初拟，triage/refine 细化）

- US-01 抽取 theuntold 共享 token 为本仓可复用 CSS（light+dark，含字体 link）
- US-02 门户首页 portal-home 套 token（卡片网格 editorial 化）
- US-03 claude-blog 子站（index + post layout）套 token（长文阅读版式）
- US-04 github-trending 替换 minima → token 样式（home/daily/weekly/default layout）
- US-05 github-trending 136 天历史页回归验证 + light/dark 切换机制
