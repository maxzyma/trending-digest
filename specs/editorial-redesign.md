# 三站编辑重设计（待做）

> 状态：已定方案、未开工。对齐目标是 theuntold 主站**当前**设计语言，不是抄 token、也不是对齐 github-trending 的旧快照。

## 问题

`trending.theuntold.ai` 下三站观感互不一致，且都落后于 theuntold 主站当前设计语言：

- `/`（门户）与 `/claude-blog/`：自造深色调色板（`--bg #0e1116` / `--pulse`），仅 dark
- `/github-trending/`：停在 2026-05-10 的旧样式快照（末次样式 commit `e4a7fb5`）
- theuntold 主站已经过两轮重构：宽屏设计系统（`bee4d65`/`dfdfaba`，2026-05-15）+ 站点编辑重设计（`e397398`，2026-06-17）

"单一入口像一个站、且属主站设计家族"的定位因此立不住。根因是门户原型自造 token，github-trending 未跟进主站重构。

## 目标

三站按主站当前设计语言做一等编辑重设计（light 纸感默认 + dark 可切，WCAG AA 不退化）：

- `/` 门户首页（本仓）
- `/claude-blog/` 索引与长文页（本仓）
- `/github-trending/` 大站（github-trending-digest 仓，从旧快照升级）

## 照搬 vs 改造的边界

- **照搬不重造**：token 值、字体分工、设计系统教训 —— 这些是底料。
- **按 trending 内容模型改造**：组件级结构，尤其主站的 EditorialCard（它围绕判词/被审对象字段设计，trending 没有这套内容模型）。

即：借设计语言与底料，不搬内容专属组件。

## 复用信源

- **token SSoT**：theuntold 主站 layout 的 `:root` 块（light `#faf8f3` 纸底 + 琥珀 `#8b5e0c`；dark `#0b0c0f` + 琥珀 `#e8a820`），12+ 变量：`--bg-default/surface/elevated/hover`、`--border(-mid/-bright)`、`--fg-emphasis/default/muted/subtle`、`--accent-primary/dim/glow/line/info`、`--signal-*`、`--finding-*`。theuntold 侧已声明与本站共享 token 名。
- **字体分工**：body = Source Serif 4；标题 Noto Serif SC；mono JetBrains Mono（Google Fonts link 与主站同一份）。
- **可迁移的 pattern**：fluid clamp 字阶、容器与文本解耦、全站左对齐 chrome、卡片等高底对齐 + hover 去位移、报纸质感（noise / rule line）、a11y focus-visible。
- **前次放弃交付的原型**：分支 `D-002-editorial-design-unification`（`cb2aea8`）上有门户与 claude-blog 的 theuntold-token 原型、editorial 行为规格和 fluid-clamp / text-wrap 教训。方案虽已推翻，这些产物可作输入，不必重造。

## 范围

- 本仓：门户首页 + claude-blog（index + 长文页）
- 跨仓：github-trending-digest 的 layouts 重做 + 136 天历史页（daily/weekly/monthly）回归
- 共享设计系统抽为可复用 CSS 单一来源（本仓 include；跨仓按各自约定同步）
- 纯视觉 + IA + 组件层：不改业务逻辑、数据、路由、Worker
- 两仓 Pages 重建，需协调上线时序

## 风险

- 改动直接可见于生产，跨两仓需原子上线协调
- github-trending 升级 = 136 天历史页全量回归
- 三种内容形态（门户卡片 / 译读长文 / 分析报告表格）各需版式，周期显著长于单纯换 token
- 哪些 pattern 可迁移、哪些要改造需要逐个判断，判断成本本身不小

## 工作项

按依赖顺序，前四项是骨架（门户 → github-trending → claude-blog 三站视觉连贯即骨架成立）。

**US-01 设计语言锚点 ⭐**
提炼主站设计语言中适用于 trending 的部分，产出高保真门户原型作锚点。
- 高保真门户原型（静态自包含），体现选定的字阶/卡片/chrome/tokens/质感，经 ≥2 独立视角评审
- 明确记录：哪些 pattern 迁移、哪些因内容模型不同而改造

**US-02 共享设计系统 CSS 单一来源 ⭐**
tokens（light+dark）+ 字阶 clamp + 卡片/chrome patterns + a11y 抽成一份可复用 CSS（`_includes/` 或 `assets/css/`），含 fluid clamp 字阶、容器/文本解耦、focus-visible；token 值对齐 theuntold 当前。

**US-03 门户首页重设计 ⭐**
hero 字阶 fluid clamp、副标题 measure 控换行；信源卡 editorial 语言（等高 / hover 去位移）；light 默认可切 dark；WCAG AA 不退化；**保留 data-testid**（`scripts/verify-build.sh` 依赖）。

**US-04 claude-blog 索引 + 长文页重设计 ⭐**
index + post layout 用共享设计系统；长文版式（列宽/字号/行距/中英对照）对齐设计家族；light/dark 一致；标题 fluid clamp。

**US-05 github-trending 升级（跨仓）**
`_layouts/{home,daily,weekly,default}` 升级到当前设计系统；分析报告表格与榜单排版在新设计下可读；light/dark 一致。

**US-06 跨站一致性 + light/dark 机制统一**
三站同 token / 字阶 / 卡片语言；切换机制一致（`prefers-color-scheme` + 手动 toggle，存储 key 差异记为已知项）。

**US-07 历史回归 + WCAG AA 不退化**
github-trending 历史页抽样（各类型 ≥2）渲染正常无错位；permalink / GoatCounter / 内链不受影响；全站文字与 accent 组合不低于 WCAG AA。
