---
delivery: D-002
features_affected: ["aggregation-portal"]
feature_type: functional
branch: "D-002-editorial-design-unification"
created: 2026-07-09
updated: 2026-07-10
lifecycle: abandoned
abandoned_reason: >-
  Define 期间发现对齐基线判断错误：原 backlog 立意为"抄 theuntold token 到三站"，
  默认 gtd 姊妹站为对齐目标。实证 gtd 样式停在 2026-05-10 v2 快照，而 theuntold 主站
  经 D-005 宽屏设计系统(2026-05-15) + D-018 site-editorial-redesign(2026-06-17 上线)
  两轮重构，gtd 已过时。Human 决定按主站"完整重设计流程"重做 trending 集群审美——
  远超原 G1 立意与 ROI，回 Supply 重过 G1（Path B）。本交付放弃，feature 分支不 merge。
  参考产物(portal/claude-blog 原型 + editorial-design-system behaviors)留在本分支供新 backlog 消费。

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

**当前状态**：Define G1 passed。**已产**：`_index.md` + `scope.md`（已按 scope 修正回退）+ UI 原型 portal-home（`ui/prototype.html`）+ claude-blog 长文页（`ui/prototype-claude-blog-post.html`），均 theuntold token 基线、light 默认、已渲染人眼审、基调确认。**未产**：behaviors/ delta 修正、G2。

**待办顺序**：
1. **behaviors/**：按 backlog stories US-01~05 展开/修正 Gherkin——跨站 token 一致 / light-dark 切换（key `trending-theme`）/ **github-trending 一致性核验（非改造）** / WCAG AA 不退化 / data-testid 保留（含新增 `portal-theme-toggle`）。注意：原"github-trending 136 天脱 minima 回归"story 需按 scope 修正改为一致性核验。
2. **G2** Spec 完整性 Hard Gate。

**token 精确信源（照搬不重造，已核实）**：`projects/external/theuntold/src/layouts/BaseLayout.astro:432-504`（`:root` light + `[data-theme='dark']` dark），已逐值抄入两份原型。github-trending 现用 `publications/github-trending-digest/assets/css/style.css` 与之逐值相同。

**关键决策（已定，勿重议）**：① 对齐目标=theuntold 共享 editorial token（非 minima）；② **light 纸感默认 + dark 可切（Human 2026-07-09 确认）**；③ **github-trending 已在目标 token 上→降为一致性核验、不改代码（Human 2026-07-09 确认 scope 修正）**；④ 纯视觉层，不改业务/数据/路由/Worker；⑤ 实际改造只剩本仓 portal-home + claude-blog 两处。

## Q&A 记录（Define 阶段）

| 时间 | 问 | 答（Human） | AI 推荐 |
|------|-----|------|------|
| 2026-07-09 | 三站默认主题基调？ | light 纸感默认（dark 可切） | ✅ 与推荐一致（跨站观感最连续，theuntold 主站同调） |
| 2026-07-09 | github-trending 已在目标 token 上（非 minima），如何处理 scope？ | 本交付内回退修正 scope（降为一致性核验） | ✅ 与推荐一致（scope 收缩，避免对已达标站做无谓改造 + 136 天回归） |

**复用经验交付（theuntold sdlc/deliveries/）**：`wide-screen-design-system`（容器分层/fluid clamp typography/a11y focus-visible/卡片 hover 去位移）+ `site-editorial-redesign`（EditorialCard 组件/tokens SSoT/媒体报纸编辑语言）。

**上游 D-001 已交付上线**：`trending.theuntold.ai` 三站已 live（门户/claude-blog/github-trending 反代），本交付只换视觉。follow-up backlog：`claude-blog-frontmatter-quoting`（P2，跨仓流水线根因）。
