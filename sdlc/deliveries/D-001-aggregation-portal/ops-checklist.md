---
delivery: D-001-aggregation-portal
has_ops_actions: true
---

# 运维侧上线清单 — D-001 聚合门户

> 代码带不到、上线需手工执行的动作。只识别 + 指引，不自动执行。完整步骤/时序 → `cutover-runbook.md`。

## DNS / 域名（Cloudflare）

- [ ] github-trending-digest 移除自定义域 `trending.theuntold.ai`（GitHub repo Settings → Pages）— 触发：域归属迁移（cutover step 1）
- [ ] trending-diggest 认领自定义域 `trending.theuntold.ai`（Settings → Pages，CNAME 文件已在仓）— 触发：TASK-008 / cutover step 4
- [ ] CF DNS 复核：`trending.theuntold.ai` A → GitHub Pages IP（108/109/110/111.153）+ 🟠 橙云 + SSL/TLS Full（runbook §6.2）— 触发：TASK-008
- [ ] CF API 操作用 `env -u http_proxy -u https_proxy curl --noproxy '*'`（runbook §6.5 防代理污染 Authorization）

## Worker 部署（Cloudflare）

- [ ] `wrangler login`（OAuth）或配 `CLOUDFLARE_API_TOKEN` — 触发：TASK-005 部署前置（本地未找到 CF token）
- [ ] `cd theuntold && pnpm run edge-proxy:deploy`（`wrangler deploy -c edge/trending-proxy/wrangler.jsonc`）— 触发：TASK-005，须在域释放（step 1）后
- [ ] preview/origin 路由验反代 `/github-trending/` + 旧 URL 301（切生产前）— 触发：cutover step 3

## 跨仓 merge 时序

- [ ] theuntold `D-001-aggregation-portal` → main（Worker 代码）
- [ ] github-trending-digest `D-001-aggregation-portal` → main（baseurl）— 触发：不早于 cutover 窗口，防旧 live 站链接错位（release-plan 风险表）

## live 验收（agent-browser，post-cutover）

- [ ] 按 runbook §6.6 用 agent-browser 验 6 条：`/` 门户 / `/claude-blog/` / `/github-trending/` / 旧 URL 301 / 上游 404 透传 — 触发：SC-02/03/15 live-CF defer 项补验

## 无需运维的部分

本仓（trending-diggest）门户 + claude-blog 子站：merge 到 main 后 GitHub Pages Actions 自动构建部署，无手工运维动作。
