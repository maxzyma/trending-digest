## Summary

把 `trending.theuntold.ai` 三站（门户首页 + claude-blog 子站 + github-trending 大站）统一到 **theuntold 共享 editorial design-token 系统**（light 纸感默认 + dark 可切，复用现成 WCAG-AA token，不重造），消除当前**本仓门户/claude-blog 子站自造深色**（`#0e1116`/蓝 `#58a6ff`）与 theuntold 主站/github-trending 已用 editorial token 之间的视觉割裂。

> **Scope 修正（2026-07-09，本交付内回退，Human 确认）**：原 Summary/In-Scope 假设 github-trending 是 minima 浅色需脱 minima。源码实证推翻——`publications/github-trending-digest` 早于 2026-05-10（commit `e4a7fb5`）已迁至 theuntold editorial token（`--bg-default:#faf8f3` light 默认 / `--accent-primary:#8b5e0c` / `[data-theme=dark]`，逐值同 theuntold）。故 github-trending **降为一致性核验目标**（验证已同 token，无需改代码），实际改造只剩本仓 portal-home + claude-blog 两处。

## 目标与范围

- **目标**：读者跨 `/` ↔ `/github-trending/` ↔ `/claude-blog/` 浏览时观感一致（同一 token/字体/卡片语言，3 秒识别同一站），落实"单一入口像一个站"。受益方：trending.theuntold.ai 深度读者。

- **In Scope**：
  - 抽取 theuntold `:root` editorial token（12+ 变量 light+dark + 字体 link）为本仓可复用 CSS（单一来源）。
  - 门户首页 `_layouts/portal-home.html` 套 token（editorial 卡片网格）。
  - claude-blog 子站（`claude-blog/index.html` + `_layouts/claude-blog-post.html`）套 token（长文阅读版式）。
  - light 默认 + dark 可切机制（本仓 portal + claude-blog 落实，localStorage key `trending-theme`，无存储跟系统偏好），与 github-trending 观感一致。
  - **github-trending 一致性核验**（非改造）：确认其现用 token/字体/light-dark 机制与本仓改后一致；历史页经统一 layout + 外部 `style.css` 渲染自动继承 token，verify 阶段抽查 daily/weekly/monthly 无残留 minima。

- **Out of Scope**（防蔓延）：
  - 不改任何业务逻辑 / 数据 / 路由 / CF Worker 反代 / 301 规则（纯视觉 + 样式层）。
  - 不改内容（不动 markdown 正文、不动数据文件语义）。
  - 不引入第三方 UI 框架 / 构建工具（照搬 theuntold token，纯 CSS + Liquid）。
  - 不改门户信息架构（区块结构 Hero/网格/流不变，只换视觉 token）。
  - 不做新交互功能（评论/搜索等）。

## 关键约束

- **复用不重造**：token 名+值照搬 theuntold `src/layouts/BaseLayout.astro` `:root`（SSoT），不自造调色板（D-001 割裂的根因就是自造）。
- **WCAG AA 不退化**：theuntold token 已 codex 审过对比度（fg-subtle 4.55:1 等），照搬即继承；不得改出低于 AA 的组合。
- **github-trending 一致性底线**：其已在 theuntold token 上（不改代码）；核验其 light-dark 默认/token 值与本仓改后逐项一致；若发现细微不一致（如 localStorage key `gtd-theme` vs `trending-theme` 跨子域独立），记录为已知差异或 follow-up，不在本交付强制统一存储层。
- **保留 data-testid**：门户/子站现有 data-testid 不因换样式丢失（D-001 的 SC/测试仍绿）。
- **原子上线**：两仓样式改动上线不破坏现网（github-trending 样式重建 + 门户重建协调；Worker 不变故 /github-trending/* 路由不受影响）。

## 跨 Feature 影响声明

- 演化 aggregation-portal 的 UI token 层（其 ui/prototype.html + ui/views 视觉契约需更新为 theuntold token 基线）。
- 跨仓 github-trending-digest：**仅核验、不改代码**（已在目标 token 上，见 Scope 修正）。原"纳入改造"降为一致性核验。
- CF Worker（theuntold `edge/trending-proxy`）：**不涉及**（纯反代，与样式无关）。
- 复用信源（只读）：theuntold `src/layouts/BaseLayout.astro`（token SSoT）+ `wide-screen-design-system`/`site-editorial-redesign` 交付经验。
