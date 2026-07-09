# Stories: 聚合门户（trending.theuntold.ai 单入口聚多源）

<!-- 迁自 theuntold（G1 passed，2026-06-29）。受众：G1 审核者 + Define 阶段 AI -->

---

## User Path（AI 推断 — 未验证）

> 无既有 `specs/storylines/`，本段为 AI 从 stories 反推的读者活动序列，未经验证。

Backbone（前提骨架 + 读者活动序列）：

0. ⭐ trending-diggest 仓具备 Jekyll 站点骨架 + Pages 部署 + CNAME（聚合入口宿主前提） → US-00
1. ⭐ 访问 `trending.theuntold.ai`，落到聚合门户首页（Hero + 信源导航网格） → US-01
2. ⭐ 点 GitHub Trending 卡，进入其网格首页（经 Worker 反代到独立仓） → US-04
3. 点 Claude Blog 等小源卡，进入同仓分目录子站 → US-03（分支路径，按源）
4. 浏览首页「最新内容流」（仅同仓小源混合时间线） → US-02（分支路径，可选）
5. 用旧 URL 访问 github-trending 历史页，被 301 重定向到新路径 → US-05（兜底路径）

⭐ = Walking Skeleton（端到端最小可用：站点骨架就位 → 单一入口门户 → 大站可达）

---

## Stories

### US-00 trending-diggest 站点骨架（渲染链路前提） [P2]

**作为** 聚合门户的维护者
**我想** trending-diggest 仓从零具备 Jekyll 站点骨架 + GitHub Pages 部署 + CNAME（trending.theuntold.ai）
**以便** 该仓能渲染门户首页与小源子目录，成为聚合入口宿主（当前该仓为纯 markdown 归档仓、无 Jekyll）

#### AC

- AC-1: 仓含 Jekyll 配置（`_config.yml` 至少 title/baseurl）+ Pages workflow（`submodules: false`），push 后 Pages 构建成功产出可访问 HTML
- AC-2: CNAME = `trending.theuntold.ai`（接管根域）；DNS 按 `theuntold/docs/runbook.md §6`（CF 橙云 + A 记录指 Pages IP）
- AC-3: 渲染链路连通——至少一个占位首页可经 `trending.theuntold.ai/` 访问（实际内容由 US-01 充实）

---

### US-01 聚合门户首页 [P2]

**作为** 想浏览多源译读/深读内容的技术读者
**我想** 访问 `trending.theuntold.ai` 时看到一个统一入口首页，含品牌定位 + 各信源导航卡
**以便** 一处发现并进入所有源，不必记多个分散地址

#### AC

- AC-1: 访问根路径 `/` 返回本仓 Pages 渲染的门户首页，含 Hero 区（品牌 + 一句定位）与信源导航网格区两个区块
- AC-2: 导航网格每源一张卡，含简介 + 入口链接；当前批次至少含 GitHub Trending（→ `/github-trending/`）与 Claude Blog（→ `/claude-blog/`）两卡
- AC-3: 首页 HTML 不含 github-trending 的明细条目（仅导航卡），即不依赖另一仓构建期数据
- AC-4: 最新内容流为首页第三区块，归属 US-02（本故事不含其内容逻辑，仅占位区块存在性）

---

### US-02 首页最新内容流（同仓小源） [P3]

**作为** 技术读者
**我想** 在门户首页看到同仓小源的最新若干条 digest 倒序流
**以便** 不点进子站也能瞥见最新更新

#### AC

- AC-1: 门户首页第三区块（US-01 已占位）按时间倒序列同仓源（claude-blog 等）最新若干条 digest
- AC-2: 明确不含 github-trending 的最新明细（构建期拿不到另一仓内容）
- AC-3: 无同仓小源内容时该区块优雅留空/隐藏，不报错

---

### US-03 小源同仓分目录子站 [P2]

**作为** 技术读者
**我想** 点小源卡（如 Claude Blog）进入 `/claude-blog/` 等子目录，看到该源完整内容
**以便** 阅读单源的全部译读/深读文章

#### AC

- AC-1: `/claude-blog/*` 由本仓 Jekyll 渲染（`baseurl` 设为对应路径，CSS/链接不错位）
- AC-2: 子站内导航/资源相对路径在 `/claude-blog/` 前缀下正确解析（页面 CSS 加载 200、内链可点达）
- AC-3: 同仓小源挂载不经 Worker 路由（同仓 Pages 直出）——验证：`/` 与 `/claude-blog/` 同属本仓 Pages，二者均可达且 Worker 仅对 `/github-trending/*` 生效

<!-- "未来新增源零改 Worker"是架构意图，归 Design 决策文档，不作本批 AC -->

---

### US-04 GitHub Trending 大站经 Worker 反代 [P2]

**作为** 技术读者
**我想** 点 GitHub Trending 卡进入 `/github-trending/`，看到它自己的网格首页与历史明细
**以便** 在同一入口域下访问体量大的独立维护站

#### AC

- AC-1: `/github-trending/*` 经 CF Worker 反代到 github-trending-digest 独立仓 Pages（Worker 代码落 theuntold 仓）
- AC-2: 该仓 Jekyll `baseurl` 设为 `/github-trending`，可机械验证：页面 CSS/JS src 以 `/github-trending/` 为前缀（200）、内部 permalink 指向 `/github-trending/...`、GoatCounter 统计脚本正常加载（script src 可达、path 上报含 `/github-trending/` 前缀）
- AC-3: github-trending 仍由其独立仓独立部署维护，门户侧零跨仓拷贝（运行时边缘反代）

---

### US-05 旧 URL 301 重定向兜底 [P2]

**作为** 持有 github-trending 旧链接（书签/外链/搜索引擎索引）的访客
**我想** 访问旧根路径 URL 时被自动重定向到 `/github-trending/` 下的新地址
**以便** 历史 permalink 不断链、SEO 不受损

#### AC

- AC-1: Worker（theuntold 仓）对 github-trending 迁移前的根路径 URL 返回 301 到 `/github-trending/` 下对应新路径
- AC-2: 重定向覆盖关键 permalink 模式——具体模式在 Define 阶段从 github-trending `_config.yml` permalink 配置枚举（至少含 daily 明细页与旧首页根）
- AC-3: 重定向规则为显式前缀/模式列表（非 catch-all），可用一组 fixture 断言：旧路径 URL → 期望 301 目标；且门户自身根路径 `/` 请求不被该规则命中（返回门户首页而非被重定向）

---

## 不在本次 Backlog 条目范围

- 跨仓实时聚合首页最新流（github-trending 明细不进首页流，仅导航卡）
- 自建/改造 github-trending 或 claude-blog 的内容生产流水线（仅做聚合与路由）
- 新增 trending-diggest 之外的小源内容（本次只接 claude-blog 既有源 + 预留目录机制）
- Worker 部署/CF 配置的具体实施细节（Design 阶段决定）
