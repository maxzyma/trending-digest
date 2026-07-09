# 聚合门户：任务计划

## 任务 DAG

```
TASK-001 (本仓 Jekyll 骨架)
   ├── TASK-002 (门户首页) ── TASK-003 (最新流区块)
   └── TASK-004 (claude-blog 子站 collection)

TASK-006 (github-trending baseurl) ─ [Gate: 跨仓协调+凭据] ─ TASK-005 (Worker 反代, preview 验证) ── TASK-007 (301 规则)
                                                                        │
TASK-005 + TASK-006 均 live 验证通过 ────────────────────────────────────┴── TASK-008 (DNS 切换, 最后, 防断服)
```
> 无环：006→005→007 线性；008 依赖 005+006（且 001 提供 CNAME 文件），005 不回依赖 008（解 codex P0 循环）。

> **原子上线顺序（防断服）**：TASK-008（DNS 切换）**最后**执行——须待 TASK-006（大站 baseurl 生效）+ TASK-005（Worker `/github-trending/*` 反代 live）验证通过后才切 DNS，否则 DNS 先指本仓而 Worker 未就绪 → `/github-trending/*` 404 断服（违反 US-04）。
> 跨仓 task（005/006/007/008）落 theuntold / github-trending 仓，非本 worktree；地基验证=未验证（需对应仓当前态 + Worker/CF 部署凭据），已登记 blockers[]，G3 后 implement 前须跨仓协调确认。

---

## 任务列表

### TASK-001: scaffold-jekyll-site（本仓 Jekyll 骨架）

- **层级**：INFRA
- **变更点**：本仓新增 `_config.yml`（title/baseurl/theme）+ GitHub Pages workflow（`submodules: false`）+ `CNAME`=trending.theuntold.ai
- **落点依据**：规格来源 behaviors/site-skeleton.gherkin#SC-01/02 + contracts.md#构建/部署契约 / 代码落点 本仓根 `_config.yml`、`.github/workflows/pages.yml`、`CNAME`（新建） / 定位方式 ✅ 已确认（G4 清零）：参照 github-trending-digest `_config.yml`+`pages.yml` 落地，本仓根已建 `_config.yml`/`.github/workflows/pages.yml`(submodules:false)/`CNAME`；docker jekyll 构建 exit 0 + verify-build.sh SC-01/20 PASS 实证
- **covers**：SC-01（构建成功无 submodule）+ SC-20（配置错误 fail-loud 非零退出）
- **验证**：TC-API-01（Pages 构建成功、无 submodule 拉取）+ TC-API-03（配置错误 → 非零退出、无产物发布）
- **影响范围回归**：无（本仓首个 Jekyll 化）
- **依赖**：无
- **地基验证**：已验证（github-trending-digest 同栈跑通，_layouts/home.html + pages.yml 可参照）
- **复杂度信号**：文件数=3，跨层=否，决策可逆=是，外部澄清=否

### TASK-002: build-portal-homepage（门户首页）

- **层级**：UI
- **变更点**：新增 `_layouts/portal-home.html`（Hero + 信源导航网格 + 最新流占位）+ 信源卡数据文件（`_data/sources.yml`，SourceCard 集）+ 首页 `index.md`
- **落点依据**：规格来源 behaviors/portal-homepage.gherkin#SC-04~07/21 + ui/prototype.html（视觉契约，implement 照它建）+ entities.md#SourceCard / 代码落点 `_layouts/portal-home.html`、`_data/sources.yml`、`index.md`（新建） / 定位方式 ✅ 已确认（G4 清零）：已照 `ui/prototype.html` 建 `_layouts/portal-home.html`（data-testid 保真）+ `_data/sources.yml` + `index.md`；verify-build.sh SC-04~07/21 PASS 实证结构契合
- **验证**：TC-UI（首页含 Hero+网格+流占位；两卡 href=/github-trending//claude-blog/；HTML 不含 github-trending 明细）
- **影响范围回归**：无
- **依赖**：TASK-001
- **地基验证**：已验证（prototype.html 已产、对齐 github-trending 观感）
- **复杂度信号**：文件数=3，跨层=否，决策可逆=是，外部澄清=否

### TASK-003: latest-stream-aggregation（首页最新流）

- **层级**：UI
- **变更点**：`_layouts/portal-home.html` 第三区块用 Jekyll `site.pages` 聚合同仓小源 digest，按 ALG-03 倒序取 N 条；空集优雅留空
- **落点依据**：规格来源 behaviors/latest-stream.gherkin#SC-08~10/22 + algorithms.md#ALG-03 + entities.md#DigestEntry / 代码落点 `_layouts/portal-home.html`（最新流 Liquid 段）+ `_config.yml`（条数 N 配置） / 定位方式 从 ALG-03 逻辑 → Liquid where/sort/limit 实现，落 portal-home layout
- **验证**：TC-UI（倒序、仅同仓源、不含 github-trending、空集不报错）
- **影响范围回归**：TASK-002 首页渲染
- **依赖**：TASK-002
- **地基验证**：已验证（同仓 claude-blog posts 存在，site.pages 可枚举）
- **复杂度信号**：文件数=1，跨层=否，决策可逆=是，外部澄清=否

### TASK-004: claude-blog-subsite-baseurl（小源子站）

- **层级**：INFRA
- **变更点**：`_config.yml` 定义 Jekyll collection `claude_blog`（`output: true` + `permalink: /claude-blog/:path/`），使 `sources/claude-blog/posts/` 渲染到 `/claude-blog/` 前缀下，资源/内链前缀正确（INV-01）
- **落点依据**：规格来源 behaviors/small-source-subsite.gherkin#SC-11~13/23 + _index.md#INV-01 + decisions.md#ADR-002（小源同仓子目录机制已锁 collection 方案，非悬挂）/ 代码落点 `_config.yml`（collections.claude_blog 段）+ 页面 layout / 定位方式 从 ADR-002 锁定的 collection 机制 → Jekyll collections 配置落 `_config.yml`（deterministic，不留 implement 自由度）
- **验证**：TC-UI（/claude-blog/ CSS 200、内链可达、Worker 不介入同仓路径）
- **影响范围回归**：TASK-001 站点构建
- **依赖**：TASK-001
- **地基验证**：已验证（claude-blog markdown 归档已在本仓）
- **复杂度信号**：文件数=2，跨层=否，决策可逆=是，外部澄清=是（collection 机制选型）

<!-- ⚑ Gate: 跨仓协调 + Worker 部署凭据确认后再动 TASK-005/006/007/008 -->

### TASK-005: cf-worker-reverse-proxy（github-trending 反代）【跨仓：theuntold】

- **层级**：INFRA
- **变更点**：theuntold 仓新增 CF Worker，按 ALG-01 反代 `/github-trending/*` 到 github-trending 独立仓 Pages；上游不可用返回可辨识错误
- **落点依据**：规格来源 behaviors/github-trending-proxy.gherkin#SC-14~16/24 + algorithms.md#ALG-01 / 代码落点 theuntold `edge/trending-proxy/`（src/router.ts + src/index.ts + wrangler.jsonc） / 定位方式 ✅ 已确认（G4 清零）：theuntold 无既有边缘 Worker（src/worker/ 是 Railway 作业 worker，无关），净新建独立 CF Worker 于 `edge/trending-proxy/`；vitest 22/22 + tsc + `wrangler deploy --dry-run` PASS。CF 凭据/live 部署降级 blocker（live-CF，cutover 执行，runbook §6）
- **验证**：TC-UI（/github-trending/ 反代成功）+ TC-API（上游 5xx/网络失败时 Worker 返非 200；上游 404/410 透传）——先在 preview/origin 路由验证，不切生产流量
- **影响范围回归**：theuntold 现有 Worker/路由（若有）
- **依赖**：TASK-006（大站 baseurl 生效后才能验证反代前缀）——**不依赖 TASK-008**（解循环：Worker 先部署+preview 验证，DNS 由 TASK-008 最后切；codex 跨家族审查 P0）
- **地基验证**：未验证：theuntold 仓 Worker 现状 + CF 部署凭据 + trending.theuntold.ai 当前绑定 + **Worker origin host/递归防护**（见 contracts Worker origin 契约）
- **复杂度信号**：文件数=1~2，跨层=否，决策可逆=是（Worker 可回滚），外部澄清=是（跨仓+凭据）

### TASK-006: github-trending-baseurl（大站 baseurl）【跨仓：github-trending-digest】

- **层级**：INFRA
- **变更点**：github-trending-digest 仓 `_config.yml` 设 `baseurl: /github-trending`，使其资源/permalink 带前缀
- **落点依据**：规格来源 behaviors/github-trending-proxy.gherkin#SC-15 + _index.md#INV-01 / 代码落点 github-trending-digest 仓 `_config.yml`（当前 baseurl=""） / 定位方式 已实证该仓 `_config.yml` baseurl 当前为空（读取确认）；改为 /github-trending
- **验证**：TC-API（页面 CSS/JS src 带 /github-trending/ 前缀 200、permalink 前缀、GoatCounter 正常）
- **影响范围回归**：github-trending 现有站全站链接（baseurl 变更影响面大）
- **依赖**：无（可先行）
- **地基验证**：已验证（该仓 _config.yml 已读，baseurl="" 确认）
- **复杂度信号**：文件数=1，跨层=否，决策可逆=是，外部澄清=是（跨仓 + 需与旧 URL 301 协同上线）

### TASK-007: legacy-301-redirect（旧 URL 301 兜底）【跨仓：theuntold】

- **层级**：INFRA
- **变更点**：theuntold Worker 按 ALG-02 对旧内容子路径返 301；裸 / 不命中；显式模式列表 + fixture 断言
- **落点依据**：规格来源 behaviors/legacy-redirect.gherkin#SC-17~19/25 + algorithms.md#ALG-02 + contracts.md#301 fixture 契约 / 代码落点 theuntold `edge/trending-proxy/src/router.ts`（matchLegacyRedirect ALG-02） / 定位方式 ✅ 已确认（G4 清零）：随 TASK-005 Worker 落地，ALG-02 锚定正则（含 .html + weekly 变体）；vitest router SC-17~19/25 PASS 实证
- **验证**：TC-API（fixture：旧子路径→301 目标；裸 /→门户 200；无匹配→不误 301 不 5xx）
- **影响范围回归**：TASK-005 Worker 路由
- **依赖**：TASK-005
- **地基验证**：未验证：同 TASK-005（theuntold Worker）
- **复杂度信号**：文件数=1，跨层=否，决策可逆=是，外部澄清=是（跨仓）

### TASK-008: dns-cname-config（DNS/CNAME）【跨仓：theuntold/runbook】

- **层级**：INFRA
- **变更点**：按 theuntold `docs/runbook.md §6` 配置 trending.theuntold.ai（CF 橙云 + A 记录指 Pages IP），使域指向本仓 Pages
- **covers**：SC-02（CNAME/DNS 指向本仓 Pages）+ SC-03（渲染链路连通、门户首页可访问）
- **落点依据**：规格来源 behaviors/site-skeleton.gherkin#SC-02/03 + stories US-00 AC-2 / 代码落点 CF DNS 控制台 + 本仓 CNAME + `cutover-runbook.md` / 定位方式 ✅ 已确认（G4 清零）：runbook §6 已读、cutover 原子步骤已成文（cutover-runbook.md）；本仓 CNAME 已建。live DNS 切换降级 blocker（live-CF，post-merge cutover 执行 + agent-browser 验，runbook §6.6）
- **验证**：TC-API-02（trending.theuntold.ai 解析到本仓 Pages）+ TC-UI-01（门户首页经该域可访问）
- **影响范围回归**：trending.theuntold.ai 当前绑定（原 github-trending）
- **⚠️ 原子上线顺序（防断服，MUST）**：DNS 切换（本 task）**必须在 TASK-006（github-trending baseurl 生效）+ TASK-005（Worker 反代 live）之后**执行——否则 DNS 已指本仓但 Worker 未路由 `/github-trending/*` → 该路径 404、大站断服（违反 US-04）。三者协同：TASK-006 上线 → TASK-005 Worker deploy 验证 `/github-trending/*` 通 → 才切 DNS。
- **依赖**：TASK-001（CNAME 文件）+ TASK-005（Worker live）+ TASK-006（大站 baseurl 生效）
- **地基验证**：未验证：CF 账号 + runbook §6 当前有效性 + 域当前绑定状态
- **复杂度信号**：文件数=1，跨层=否，决策可逆=是（DNS 可回切），外部澄清=是（跨仓 + 凭据 + 停机窗口）

---

## 总览

| 指标 | 值 |
|------|-----|
| 任务总数 | 8（本仓 4 / 跨仓 4）|
| Gate 数量 | 1（跨仓协调 + Worker 部署凭据）|
| 关键路径 | TASK-006/008 → [Gate] → TASK-005 → TASK-007 |

<!-- Feature: aggregation-portal | 由 /sdlc:design 生成于 2026-07-07 -->

## 信源清单

<!-- sources-manifest:begin -->
### D-001 @ 2026-07-07

- specs：`features/aggregation-portal/behaviors/*.gherkin`（SC-01~25 逐 task covers）、`algorithms.md`（ALG-01/02/03）、`contracts.md`（路由/301/构建契约）、`entities.md`（SourceCard/DigestEntry）、`ui/prototype.html`（TASK-002 视觉契约）、`_index.md`（INV-01）
- code：`publications/github-trending-digest/_config.yml`（TASK-006 baseurl="" 实证 + TASK-001 同栈参照）、`_layouts/home.html`（TASK-002 参照）
- 参考：theuntold `docs/runbook.md §6`（TASK-008 DNS，未读原文—标⚠️前置确认）
<!-- sources-manifest:end -->
