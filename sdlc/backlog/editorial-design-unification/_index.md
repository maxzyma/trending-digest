---
slug: editorial-design-unification
status: collected
priority: P1
type: functional
created: 2026-07-09
---

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

## Stories（初拟，triage/refine 细化）

- US-01 抽取 theuntold 共享 token 为本仓可复用 CSS（light+dark，含字体 link）
- US-02 门户首页 portal-home 套 token（卡片网格 editorial 化）
- US-03 claude-blog 子站（index + post layout）套 token（长文阅读版式）
- US-04 github-trending 替换 minima → token 样式（home/daily/weekly/default layout）
- US-05 github-trending 136 天历史页回归验证 + light/dark 切换机制
