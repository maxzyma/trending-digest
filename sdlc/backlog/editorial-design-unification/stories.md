# Stories: trending 三站编辑重设计

> 2026-07-10 重 triage：由"抄 theuntold token"升级为"按主站当前设计语言做一等编辑重设计"（前次 token-copy 交付已放弃）。对齐目标 = theuntold 主站当前设计语言（宽屏设计系统 + 站点编辑重设计两轮成果），非 gtd 过时 v2 快照。

## User Path（AI 推断 — 未验证）

> 无既有 storylines/ 可复用（本项目未 adopt），以下为从 stories 反推的用户活动序列。

**Backbone**（读者浏览聚合站的活动序列）：
`进入 trending.theuntold.ai/（门户首页）` → `浏览信源导航卡 + 最新流` → `点进某源`（`/github-trending/` 或 `/claude-blog/`）→ `阅读内容页` → `切换深/浅色`（可选）→ `跨源来回跳转`；感知三站与 theuntold 主站属同一设计家族。

**⭐ Walking Skeleton**（端到端 MVP 必经路径 = 一致性最关键处）：
`门户首页(重设计)` → `点进 /github-trending/(升级到当前设计语言)` → `点进 /claude-blog/(重设计)` — 三站视觉连贯且属主站设计家族即骨架成立。

**分支路径**：light/dark 切换（跨站保持一致基调）；直接从外链/书签落到某内容页（该页也须自洽设计系统）。

---

## US-01 设计语言锚点（Walking Skeleton ⭐）

作为门户维护者，我要提炼 theuntold 主站当前设计语言里适用于 trending 的部分，并产出高保真门户原型作为设计锚点（经三方 DoD 审），以便后续各页有一致的设计基准、不再各画各的。

**AC**：
- 产出高保真门户原型（静态自包含），体现选定设计语言（字阶/卡片/chrome/tokens/质感），经 ≥2 独立视角 DoD 审。
- 明确记录：主站哪些 pattern 迁移、哪些因 trending 内容模型不同而改造（不照搬 EditorialCard 的判词字段）。

## US-02 共享设计系统 CSS 单一来源（⭐）

作为维护者，我要把 tokens（light+dark）+ 字阶 clamp + 卡片/chrome patterns + a11y 抽成可复用 CSS 单一来源，以便三处 layout 引用、不再各写调色板与版式。

**AC**：本仓一份共享设计系统 CSS（`_includes/` 或 `assets/css/`）；含 fluid clamp 字阶（避免固定字号断点跳跃）、容器/文本解耦、focus-visible；token 值对齐 theuntold 当前。

## US-03 门户首页编辑重设计（⭐）

作为读者，我进 `/` 看到按当前设计语言重做的门户（hero 版式 + editorial 卡片网格），与主站属同一家族。

**AC**：hero 字阶 fluid clamp、副标题 measure 控换行；信源卡 editorial 语言（等高/hover 去位移）；light 默认可切 dark；WCAG AA 不退化；保留 data-testid。

## US-04 claude-blog 索引 + 长文页重设计（⭐）

作为读者，我进 `/claude-blog/`（索引 + 文章页）看到与门户/主站一致的长文阅读版式。

**AC**：index + post layout 用共享设计系统；长文版式（列宽/字号/行距/中英对照）对齐设计家族；light/dark 一致；标题 fluid clamp。

## US-05 github-trending 升级到当前设计语言（跨仓）

作为读者，我进 `/github-trending/` 看到与门户/子站一致的当前设计语言（而非其过时 v2 快照）。

**AC**：github-trending `_layouts/{home,daily,weekly,default}` 从 v2 升级到当前设计系统；分析报告表格/榜单排版在新设计下可读；light/dark 一致。

## US-06 跨站一致性 + light/dark 机制统一

作为读者，我跨三站浏览时基调/字阶/卡片语言一致，light/dark 切换行为统一。

**AC**：三站同 token/字阶/卡片语言；切换机制一致（prefers-color-scheme + 手动 toggle，存储 key 差异记为已知项）；3 秒识别同一设计家族。

## US-07 历史回归 + WCAG AA 不退化

作为维护者，我要 github-trending 136 天历史页（daily/weekly/monthly）换设计后无回归，且全站 WCAG AA 不退化。

**AC**：抽样历史页（各类型 ≥2）渲染正常无错位；permalink/GoatCounter/内链不受影响；全站文字/accent 组合不低于 WCAG AA。
