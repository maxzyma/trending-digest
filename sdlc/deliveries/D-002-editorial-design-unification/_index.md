---
delivery: D-002
features_affected: ["aggregation-portal"]
feature_type: functional
branch: "D-002-editorial-design-unification"
created: 2026-07-09
updated: 2026-07-09
lifecycle: in_progress

phases:
  define: in_progress
  design: pending
  implement: pending
  verify: pending
  deliver: pending

gates:
  g1:
    status: passed
    decided_at: 2026-07-09
    review_doc: stories.md
    spec_commit: "de40037"
  g2:
    status: pending
  g3:
    status: pending
  g4:
    status: pending
  g5:
    status: pending

blockers: []
---

# D-002 三站统一 editorial 设计系统（editorial-design-unification）

聚合门户 D-001 上线后视觉割裂（门户/子站自造深色 vs github-trending minima 浅色）。本交付把三站统一到 **theuntold 已建立的共享 editorial design-token 系统**（light 纸感默认 + dark 可切，WCAG-AA），复用而非重造。

Backlog 来源：`sdlc/backlog/editorial-design-unification/`（G1 passed 2026-07-09）。演化 aggregation-portal 的 UI token 层 + 跨仓套 github-trending 样式。

## 下一步（新会话续作指针 — Define 阶段 in_progress）

**当前状态**：Define G1 passed；已产 `_index.md` + `scope.md`。**未产**：behaviors/、UI 子流程（prototype）、G2。

**待办顺序**：
1. **UI 子流程（design-first，优先，用户要先看效果）**：
   - 提取 theuntold `:root` editorial token → 抽成本仓共享 CSS（如 `_includes/editorial-tokens.html` 或 `assets/css/editorial.css`）。
   - **token 精确信源（照搬不重造）**：`projects/external/theuntold/src/layouts/BaseLayout.astro` `:root` 块——
     - light（默认，纸感）：`--bg-default:#faf8f3` `--bg-surface:#f3efe2` `--bg-elevated:#ebe5d3` `--bg-hover:#e3dcc6`；`--border:#d8d2c2` `--border-mid:#c5bea8` `--border-bright:#8a8472`；`--fg-emphasis:#1a1a1a`(16:1) `--fg-default:#363737`(9.5:1) `--fg-muted:#5b5852` `--fg-subtle:#766e65`(4.55:1 AA)；`--accent-primary:#8b5e0c`(dark amber) `--accent-info:#1e7a8a`；`--signal-success:#2d7a47` `--signal-danger:#b8362a` `--signal-warning:#8a6810`。
     - dark（可切）：`--bg-default:#0b0c0f` `--bg-surface:#111318` `--bg-elevated:#181922` `--bg-hover:#1e202b`；`--fg-emphasis:#dde0f0` `--fg-default:#b8bace` `--fg-muted:#8a8da6` `--fg-subtle:#767994`；`--accent-primary:#e8a820`(signature amber) `--accent-info:#45c4d8`。
     - 字体：body=Source Serif 4（trending 站专用，theuntold 已定）；标题=Noto Serif SC；mono=JetBrains Mono。Google Fonts link 见 BaseLayout.astro:57。
     - dark 切换选择器 + `--font-*` 变量：**新会话须重读 BaseLayout.astro 确认**（本 handoff 未记全 dark 块的包裹选择器/media query 机制）。
   - **重做 portal-home 原型**（`sdlc/specs/features/aggregation-portal/ui/prototype.html` 更新为 theuntold token 基线）→ 渲染给 Human 人眼审（用户明确要先看基调对不对）。
   - 确认后再铺 claude-blog + github-trending 原型。
2. **behaviors/**：5 story（US-01~05，见 backlog stories.md）展开 Gherkin——跨站 token 一致 / light-dark 切换 / github-trending 136 天历史无回归 / WCAG AA 不退化 / data-testid 保留。
3. **G2** Spec 完整性 Hard Gate。

**关键决策（已定，勿重议）**：① 对齐目标=theuntold 共享 editorial token（非 minima）；② light 纸感默认 + dark 可切；③ github-trending 一并改（脱 minima，136 天历史回归验证）；④ 纯视觉层，不改业务/数据/路由/Worker。

**复用经验交付（theuntold sdlc/deliveries/）**：`wide-screen-design-system`（容器分层/fluid clamp typography/a11y focus-visible/卡片 hover 去位移）+ `site-editorial-redesign`（EditorialCard 组件/tokens SSoT/媒体报纸编辑语言）。

**上游 D-001 已交付上线**：`trending.theuntold.ai` 三站已 live（门户/claude-blog/github-trending 反代），本交付只换视觉。follow-up backlog：`claude-blog-frontmatter-quoting`（P2，跨仓流水线根因）。
