---
schema_version: 1
slug: aggregation-portal
status: ready
priority: P1
feature_type: new-feature
related_features: []
created_at: "2026-06-29"
updated_at: "2026-07-07"
assigned_to: null
notified_at: null
delivery_ref: null
parent: null
intake_skipped: false
artifacts:
  stories:
    path: stories.md
    role: 用户故事（6 条，迁自 theuntold G1 passed）
  discussions: []
---

# 聚合门户（trending.theuntold.ai 单入口聚多源）

> 本条目原为 bootstrap 预留占位 `frontend-migration-from-theuntold`，已改名 `aggregation-portal` 并完全迁入 theuntold 的同名工作（归属裁定：交付主体在本仓）。占位原前提已纠正：
> - ❌ 原写「trending.theuntold.io 当前由 theuntold 仓维护」——实际 trending 子域是 **github-trending-digest** 的 Jekyll 站；theuntold 是另一个 Astro 主站（theuntold.ai）。
> - ❌ 原范围「迁入 theuntold Astro 前端」——实际定论是**本仓自建 Jekyll 聚合门户**（不搬 Astro）。
>
> 归属讨论已定论（2026-06-29），阻塞解除，intake 补齐。本条目自包含（含下方 §归属迁移与 G1 历史）。
> 方案信源：`notes/02-调研/trending-diggest/aggregation-portal-proposal.md`。theuntold 侧已 discard（仅留 Archive 指针）。

## Intake 覆盖账本（五问留痕）

| 五问 | 状态 | 覆盖来源 |
|------|------|---------|
| 用户 | covered | 想浏览多源译读/深读内容的中文技术读者 + 站点运营者（迁移输入 §3） |
| 场景 | covered | claude-blog 单源不足撑独立站、github-trending 体量大需独立、各源独立仓维护、想单一入口聚合（方案 §2） |
| 任务 | covered | 用 trending.theuntold.ai 单一入口、按路径聚合多源（方案 §4，路 A：CF Worker 边缘反代） |
| 成功判据 | covered | 读者访问 trending.theuntold.ai 落门户首页，并能从导航卡到达 github-trending（/github-trending/）+ claude-blog（/claude-blog/）两源（均返 200）；各源独立部署、无 submodule、无跨仓拷贝 |
| 边界 | covered | 不做跨仓实时聚合（首页最新流仅同仓小源）；已否决子域分站/submodule 嵌套/iframe/合并单仓（方案 §5/§7） |

---

## 问题陈述

**现状**：想对外展示多源译读/深读内容，但 claude-blog 单源内容不足以撑独立站；各源由独立仓在不同项目维护；GitHub Pages「一域一仓」硬约束无法单域多仓路径聚合。
**问题**：内容要么碎片化分散在多个地址，要么被迫合并单仓违背「独立维护」诉求。
**受影响用户**：读 GitHub Trending 深度分析 + Claude Blog 中文译读的技术读者；想统一对外展示的运营者。

---

## 期望成果

用单一入口域 `trending.theuntold.ai` 对外像一个站，背后各源仍由独立仓/独立项目/独立部署维护互不耦合：
- 小源（claude-blog 等）= 本仓（trending-diggest）同仓分目录 Jekyll 渲染（`/claude-blog/`）
- 大站（github-trending）= 独立仓经 CF Worker 反代挂入（`/github-trending/`）

**可观测成功信号**：读者访问 `trending.theuntold.ai/` 见门户首页，导航卡可达两源内容（均 200）；github-trending 旧 URL 301 不断链。

---

## 影响分析

**业务影响**：中 — 对外统一入口展示多源译读/深读，拓展受众；本仓职责从纯数据源 → 数据 + 展示宿主。
**技术风险**：中 — 本仓从零搭 Jekyll 骨架（当前纯 markdown 仓）；CF Worker path-rewrite + 旧 URL 重定向；跨 3 处协同。
**粗粒度估算**：Feature（6 Story：US-00 骨架 + US-01 首页 + US-02 最新流 + US-03 小源子站 + US-04 大站反代 + US-05 旧 URL 重定向）。

### 跨仓依赖（implement 触及兄弟仓，均 coworkspace submodule；Define 必读）

| 依赖 | 落点仓 | 对应 Story |
|------|--------|-----------|
| 本仓 Jekyll 骨架/首页/小源 | **trending-diggest（本仓）** | US-00 / US-01 / US-02 / US-03 |
| CF Worker 反代 + 301 重定向代码 | **theuntold 仓**（拥有 trending.theuntold.ai DNS + 部署经验，已定） | US-04 / US-05 |
| github-trending Jekyll `baseurl=/github-trending` | **github-trending-digest 仓** | US-04 AC-2 |
| DNS/CNAME 配置 | **theuntold/docs/runbook.md §6** | US-00 AC-2 |

→ specs 在本仓描述行为契约；代码交付物分布三仓。G5 release-plan 须**分仓列出**，不得把跨仓代码改动当单仓处理。

---

## 关键决策

| 项 | 裁决 |
|---|---|
| github-trending 让出根路径 | 接受迁移，Worker 加旧路径 301 兜底（US-05），保旧 permalink 不断链 |
| Worker 代码位置 | theuntold 本仓（DNS + 部署经验所在） |
| 优先级 | P1（theuntold G1 时 Human 上调） |

---

## 归属迁移与 G1 历史（迁自 theuntold，自包含）

本条目工作在 theuntold 仓走过 collect→triage→refine→**G1 passed**，因归属裁定（聚合门户交付主体在本仓、theuntold 是平级叶子产物仓）整体迁入本仓。完整历史在 theuntold git history（条目 `trending-aggregation-portal`，已 discard 归档）；关键记录复制如下，使本条目自包含。

### theuntold 侧 G1 Review — 2026-06-29（passed，作输入）

**dc:qualify**（profile sdlc-backlog / checkpoint stories-review，type gate）：三轮收敛 R1 needs-revision → R2 pass → **R3 pass，零 finding**。

- **Q 值不值得做/批准进 Define？** A: passed。方案 self-contained、约束清晰、与既有 Feature 零重叠；唯一阻塞决策（github-trending URL 迁移）已拍板；自审两处实质缺口（漏 US-00 站点骨架、跨仓 merge 目标分裂）已闭合/留痕。
- **Q 优先级？** A: **P1**（Human 上调，AI 原推荐 P2）。
- **Q 跨仓归属张力？** A: 后续重定论为「交付迁至本仓 trending-diggest」（见本条目顶部）；代码交付物分布三仓，G5 release-plan 分仓列。

**遗留追踪（交下游，不阻 G1）**：成功判据用户可观测信号已补但 G4 验证设计需落实；GoatCounter 量化 AC 已给但 Implement 细化。

> 注：上述 G1 在 theuntold 仓 SDLC 通过。本仓为独立 SDLC，theuntold G1 作**输入**（非绑定）；本仓 G1 由 Human 在本仓复核确认。

---

## G1 Review — 本仓复核（2026-07-07，passed）

- **结论**：passed（Human 批准 → ready）。
- **dc:qualify**（profile sdlc-backlog / checkpoint stories-review，type gate）：round 1 **pass，零 finding**（problem-statement / dod-checklist / impact-analysis 三维全 pass）。
- **Q&A 留痕**：
  - **Q**: 批准进入 Delivery（Define）吗？ **A**: 批准 → ready。条目自包含、dc 零 finding、theuntold G1 作输入；唯一实质变化是本仓职责扩张，已在风险中明示。
  - **Q**: 认可本仓职责从「纯数据仓」扩张为「数据 + Jekyll 展示宿主」吗？ **A**: 认可。聚合门户交付主体已裁定在本仓，Jekyll 骨架（US-00）是必要前提；architecture 基线届时随交付更新。
- **遗留追踪（交下游，不阻 G1）**：G4 验证设计需落实（成功判据用户可观测信号已给）；GoatCounter 量化 AC 待 Implement 细化；跨 3 仓交付物 → G5 release-plan 分仓列。

## DoD 检查清单

- [x] 有清晰目标 + 业务价值 + 优先级
- [x] 有影响分析（跨仓依赖已识别）
- [x] 无 Feature 冲突（与本仓 claude-blog-ingestion / bilingual-digest-format / archive-index-maintenance 不重叠——它们是数据流水线，本条目是展示/路由层）
- [x] G1（本仓 SDLC）：passed（2026-07-07 Human 复核，见上 G1 Review 段；theuntold 侧 G1 作输入）

<!-- 关联 Feature ID（进入 Define 后分配）：待分配 -->
