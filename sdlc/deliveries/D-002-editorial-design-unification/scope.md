## Summary

把 `trending.theuntold.ai` 三站（门户首页 + claude-blog 子站 + github-trending 大站）统一到 **theuntold 共享 editorial design-token 系统**（light 纸感默认 + dark 可切，复用现成 WCAG-AA token，不重造），消除当前"门户/子站自造深色 vs github-trending minima 浅色"的视觉割裂。

## 目标与范围

- **目标**：读者跨 `/` ↔ `/github-trending/` ↔ `/claude-blog/` 浏览时观感一致（同一 token/字体/卡片语言，3 秒识别同一站），落实"单一入口像一个站"。受益方：trending.theuntold.ai 深度读者。

- **In Scope**：
  - 抽取 theuntold `:root` editorial token（12+ 变量 light+dark + 字体 link）为本仓可复用 CSS（单一来源）。
  - 门户首页 `_layouts/portal-home.html` 套 token（editorial 卡片网格）。
  - claude-blog 子站（`claude-blog/index.html` + `_layouts/claude-blog-post.html`）套 token（长文阅读版式）。
  - github-trending-digest 替换 minima → theuntold token 样式（`_layouts/{home,daily,weekly,default}`）。
  - light 默认 + dark 可切机制，三站一致。
  - github-trending 136 天历史页（daily/weekly/monthly）回归验证。

- **Out of Scope**（防蔓延）：
  - 不改任何业务逻辑 / 数据 / 路由 / CF Worker 反代 / 301 规则（纯视觉 + 样式层）。
  - 不改内容（不动 markdown 正文、不动数据文件语义）。
  - 不引入第三方 UI 框架 / 构建工具（照搬 theuntold token，纯 CSS + Liquid）。
  - 不改门户信息架构（区块结构 Hero/网格/流不变，只换视觉 token）。
  - 不做新交互功能（评论/搜索等）。

## 关键约束

- **复用不重造**：token 名+值照搬 theuntold `src/layouts/BaseLayout.astro` `:root`（SSoT），不自造调色板（D-001 割裂的根因就是自造）。
- **WCAG AA 不退化**：theuntold token 已 codex 审过对比度（fg-subtle 4.55:1 等），照搬即继承；不得改出低于 AA 的组合。
- **github-trending 回归底线**：136 天历史 daily/weekly/monthly 页脱 minima 后渲染无错位；permalink/GoatCounter/内链不受样式变更影响。
- **保留 data-testid**：门户/子站现有 data-testid 不因换样式丢失（D-001 的 SC/测试仍绿）。
- **原子上线**：两仓样式改动上线不破坏现网（github-trending 样式重建 + 门户重建协调；Worker 不变故 /github-trending/* 路由不受影响）。

## 跨 Feature 影响声明

- 演化 aggregation-portal 的 UI token 层（其 ui/prototype.html + ui/views 视觉契约需更新为 theuntold token 基线）。
- 跨仓：github-trending-digest 样式层（其 `_layouts/`）——非 aggregation-portal 拥有，但纳入"三站统一"目标（backlog G1 裁定）。
- CF Worker（theuntold `edge/trending-proxy`）：**不涉及**（纯反代，与样式无关）。
- 复用信源（只读）：theuntold `src/layouts/BaseLayout.astro`（token SSoT）+ `wide-screen-design-system`/`site-editorial-redesign` 交付经验。
