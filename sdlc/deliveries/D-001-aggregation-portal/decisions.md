# D-001 聚合门户：技术决策

## Summary

**方案要点**：本仓自建 Jekyll 站作聚合入口宿主（门户首页 + 同仓小源子站），github-trending 大站经 CF Worker 边缘反代运行时挂入 `/github-trending/`，旧 URL 301 兜底。
**架构影响**：本仓从纯 markdown 归档仓 → 聚合入口宿主（推翻全局 ADR-002）；引入 CF Worker 路由层（代码归 theuntold 仓）。
**关键权衡**：选 Worker 边缘反代（各源独立仓/独立部署、运行时聚合）而非 submodule 合并单仓（违背独立维护 + 拖 github-trending ~200 repos submodule）。

---

## ADR-001：单域多仓聚合走 CF Worker 边缘反代（路 A）

**背景**：GitHub Pages 一域一仓硬约束——单自定义域只能绑一个仓 Pages，无法单域多仓路径聚合。
**决策**：CF Worker 绑 `trending.theuntold.ai`，按路径反代：`/`+`/claude-blog/*` → 本仓 Pages；`/github-trending/*` → github-trending 独立仓 Pages。
**理由**：各源独立仓/独立部署/独立维护全保留；运行时反代、无 submodule、无跨仓拷贝。
**代价**：引入 Worker 层（一次性配置）；每个挂载站须设 baseurl。
**状态**：Accepted

**被否定的方案**

| 方案 | 否定原因 |
|------|---------|
| submodule 合并单仓 | github-trending `pages.yml` submodules:false，改 recursive 拖下其 ~200 repos submodule；违背"独立维护" |
| 各源子域分站 | 多个地址、不满足"单一入口像一个站" |
| iframe 嵌入 | SEO/体验差，permalink 不干净 |

---

## ADR-002：小源同仓子目录 vs 大站独立仓（两类两机制）

**背景**：claude-blog 单源内容不足撑独立站；github-trending 体量大（136 天历史 + 固定 permalink + GoatCounter）。
**决策**：小源（claude-blog 等）= 本仓同仓 Jekyll 渲染，**机制锁定为 Jekyll collection**（`output: true` + `permalink: /claude-blog/:path/`，前缀确定、不留 implement 自由度）；大站（github-trending）= 独立仓经 Worker 挂入。
**理由**：体量差异决定机制——小源聚在一起分目录，大站保独立部署。
**代价**：两套渲染路径（同仓直出 vs 边缘反代）需分别验证。
**状态**：Accepted

**被否定的方案**

| 方案 | 否定原因 |
|------|---------|
| claude-blog 也做独立仓经 Worker 挂入 | 单源内容不足撑独立站，且徒增一条反代路径、运维成本 |
| 全部源都塞进本仓单构建 | github-trending 体量大 + 独立维护诉求，合并违背 ADR-001 独立性 |

---

## ADR-003：裸 `/` 归门户、旧首页根不 301（自审发现的语义冲突裁决）

**背景**：迁移前 `trending.theuntold.ai/` 是 github-trending 首页；迁移后 `/` 须是门户首页。同一 `/` 不可能既当门户又 301 到旧首页。
**决策**：`/` 返回门户首页（200，SC-19 权威）；301 仅覆盖内容子路径（`/daily|/weekly|/monthly|/assets`，从 github-trending `_config.yml` 枚举——无自定义 permalink，Jekyll 默认）。github-trending 旧首页内容位于 `/github-trending/`，门户首页显著提供其导航卡。
**理由**：技术上唯一自洽解；门户卡保证旧首页内容仍可达。
**代价**：直接 bookmark 裸 `/` 的访客落门户而非 github-trending 首页（可接受，一跳可达）。
**状态**：Accepted

**被否定的方案**

| 方案 | 否定原因 |
|------|---------|
| 裸 `/` 301 到 `/github-trending/` | 与 SC-19「/`=门户」直接冲突，门户将无法在根路径呈现 |
| 不做任何 301（旧链接直接断） | 违背 US-05 permalink 不断链目标、损 SEO |

---

## ADR-004：baseurl 铁律 + 构建 fail-loud

**背景**：路径挂载的站若 baseurl 未设为挂载路径，CSS/内链相对路径错位（INV-01）。
**决策**：每个经路径挂载的站 Jekyll `baseurl` = 挂载路径（本仓小源子站 / github-trending=`/github-trending`）；构建失败即非零退出、阻断部署、不产残缺站（继承 github-trending build-fail-loud 经验）。**baseurl 校验载体锁定为 Pages workflow 内一个预部署 CI step**（构建后断言产物内资源引用带正确前缀，失败则 job 非零退出、不发布）——不依赖 Jekyll plugin，避免主题耦合（对应 SC-23 可观测断言 TC-API-13）。
**理由**：错位与残缺产物是本类聚合最常见故障模式，前置到构建期捕获；CI step 载体与 Pages workflow 天然一体、无额外依赖。
**代价**：baseurl 配置需按挂载路径逐站维护；CI step 需随新增子站扩展校验路径。
**状态**：Accepted

**被否定的方案**

| 方案 | 否定原因 |
|------|---------|
| baseurl 校验用 Jekyll plugin | 与主题/插件生态耦合，github-trending 用 minima，跨站不一致 |
| fail-soft 部署（残缺也上线） | 违背 build-fail-loud（残缺站静默上线是本类站已知教训） |

---

## 方案权衡

源独立性（各源独立仓/部署，运行时聚合）> 合并单仓的构建简单性；入口一致性（单域路径聚合像一个站）> 子域分站隔离；首页新鲜度受限（最新流仅同仓小源，Worker 运行时拿不到跨仓构建期数据）为可接受代价。

<!-- Delivery：D-001-aggregation-portal | G3 审查于：2026-07-07 -->
<!-- 相关文件：../../specs/features/aggregation-portal/contracts.md | tasks.md -->

## 信源清单

<!-- sources-manifest:begin -->
### D-001 @ 2026-07-07

- specs：`features/aggregation-portal/behaviors/*.gherkin`（SC-01~25）、`contracts.md`（路由/301 fixture）、`entities.md`（SourceCard/DigestEntry/RedirectRule）、`_index.md`（INV-01/02/04 + 架构约束）
- specs：`architecture/_index.md#ADR`（ADR-002 superseded、新增 ADR-004/005）
- 参考：`backlog/aggregation-portal/`（stories US-00~05）、方案信源 `notes/02-调研/trending-diggest/aggregation-portal-proposal.md`（路 A / §5 首页 / 裸 / 冲突）
- code：`publications/github-trending-digest/_config.yml`（permalink 枚举依据：无自定义 permalink、Jekyll 默认）、`_layouts/home.html`（观感对齐依据）
<!-- sources-manifest:end -->
