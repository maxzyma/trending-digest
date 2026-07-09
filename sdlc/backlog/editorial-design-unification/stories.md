# Stories: 三站统一 editorial 设计系统

## User Path（AI 推断 — 未验证）

> 无既有 storylines/ 可复用（本项目未 adopt），以下为从 stories 反推的用户活动序列。

**Backbone**（读者浏览聚合站的活动序列）：
`进入 trending.theuntold.ai/（门户首页）` → `浏览信源导航卡 + 最新流` → `点进某源`（`/github-trending/` 或 `/claude-blog/`）→ `阅读内容页` → `切换深/浅色`（可选）→ `跨源来回跳转`

**⭐ Walking Skeleton**（端到端 MVP 必经路径 = 一致性最关键处）：
`门户首页(套 token)` → `点进 /github-trending/(套 token)` → `点进 /claude-blog/(套 token)` — 三站视觉连贯即骨架成立。

**分支路径**：light/dark 切换（跨站保持一致基调）；直接从外链/书签落到某内容页（该页也须自洽 token）。

---

## US-01 共享 token 抽取（Walking Skeleton ⭐）

作为门户维护者，我要把 theuntold 的共享 `:root` editorial token（light+dark，含字体 link）抽成本仓可复用的 CSS include，以便三处 layout 单一来源引用、不再各写各的调色板。

**AC**：
- 本仓有一份共享 CSS（如 `_includes/editorial-tokens.html` 或 `assets/css/editorial.css`）含 theuntold 的 12+ `:root` 变量（light 默认 + dark）+ 字体 link（Source Serif 4 / Noto Serif SC / JetBrains Mono）。
- token 名/值与 theuntold `BaseLayout.astro` `:root` 一致（照搬，不重造）。

## US-02 门户首页套 token（⭐）

作为读者，我进 `/` 看到的门户首页用 editorial token（纸感默认 + 琥珀 accent + Source Serif 正文），卡片网格是 editorial 语言，以便与 theuntold 品牌一致。

**AC**：portal-home 引用共享 token；Hero/信源卡/最新流套 token；light 默认可切 dark；WCAG AA 不退化；保留 data-testid。

## US-03 claude-blog 子站套 token（⭐）

作为读者，我进 `/claude-blog/`（索引 + 文章页）看到与门户一致的 editorial 排版（长文阅读版式），以便阅读体验连贯。

**AC**：claude-blog index + post layout 引用共享 token；长文阅读版式（正文列宽/字号/行距对齐 theuntold editorial）；light/dark 一致。

## US-04 github-trending 替换 minima → token（⭐，跨仓）

作为读者，我进 `/github-trending/` 看到与门户/子站一致的 editorial 观感（而非 minima 浅色），以便"单一入口像一个站"。

**AC**：github-trending `_layouts/{home,daily,weekly,default}` 脱离 minima、套共享 token；分析报告表格/榜单排版在 editorial token 下可读；light/dark 一致。

## US-05 历史回归 + 切换机制

作为维护者，我要 github-trending 136 天历史页（daily/weekly/monthly）在换样式后无回归，且 light/dark 切换机制三站统一，以便旧内容不坏、切换体验一致。

**AC**：抽样历史页（各类型 ≥2）渲染正常无错位；light/dark 切换（如 prefers-color-scheme + 可选手动 toggle）三站行为一致；github-trending 现有链接/permalink/GoatCounter 不受样式变更影响。
