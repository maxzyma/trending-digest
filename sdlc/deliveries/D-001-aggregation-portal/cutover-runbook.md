# D-001 聚合门户：生产 cutover runbook（TASK-008）

> 生产域 `trending.theuntold.ai` 从「直连 github-trending-digest Pages」切到「trending-diggest 门户 + CF Worker 反代 github-trending」。
> **原子顺序 MUST**：先让新 origin + Worker 就绪并验证，最后切域，防 `/github-trending/*` 断服（US-04 / tasks.md TASK-008）。
> 本操作属 **post-G5 部署**（代码 merge 到各仓 main 后执行），非 implement 期——implement 期只验证可部署性（`wrangler deploy --dry-run` 通过）。

## 现状（cutover 前）

| 项 | 当前 |
|----|------|
| `trending.theuntold.ai` DNS | CF 橙云 proxied，A → GitHub Pages IP（185.199.108.153 等） |
| 该域 Pages 源 | `maxzyma/github-trending-digest`（自定义域绑此仓），baseurl="" |
| CF Worker | 无 |
| runbook 依据 | theuntold `docs/runbook.md §6`（zone id `35fede9fc88e9a64f6c9c54ea44c6dac`，SSL Full，橙云+A 记录） |

## 目标（cutover 后）

| 项 | 目标 |
|----|------|
| `trending.theuntold.ai` 自定义域 | 绑 `maxzyma/trending-diggest`（门户 Pages） |
| `/`、`/claude-blog/*` | trending-diggest Pages 直出（baseurl=""） |
| `/github-trending/*` | CF Worker `trending-proxy` 反代 → `maxzyma.github.io/github-trending-digest/*`（Option B 前缀映射） |
| 旧内容子路径 `/daily|/weekly|/monthly|/assets/*` | Worker 301 → `/github-trending/...` |
| github-trending-digest | baseurl=`/github-trending`，自定义域已移除（走 `maxzyma.github.io/github-trending-digest/` 项目页作 Worker origin） |

## 前置（各仓 main 已含本交付）

- [ ] trending-diggest main: TASK-001~004（Pages 从 main 构建部署成功，`maxzyma.github.io/trending-diggest/` 可访问）
- [ ] github-trending-digest main: TASK-006 baseurl=/github-trending（Pages 重建）
- [ ] theuntold main: TASK-005/007 Worker 代码
- [ ] CF 认证就绪：`wrangler login`（OAuth）或 `CLOUDFLARE_API_TOKEN`

## 原子步骤（严格按序，防断服）

1. **github-trending-digest 移除自定义域**：仓 Settings → Pages → Custom domain 清空（或删 CNAME 文件）。此后其 Pages 服务于 `maxzyma.github.io/github-trending-digest/`（项目页，物理路径含 `/github-trending-digest/` 前缀，与 baseurl=/github-trending 的链接经 Worker 映射自洽）。
   - ⚠️ 此步会使旧 `trending.theuntold.ai`（仍指此仓）暂时不可用——故须与步骤 4 快速衔接，或先做步骤 2/3 让新链路就绪。
2. **部署 Worker**：`cd theuntold && pnpm run edge-proxy:deploy`（`wrangler deploy -c edge/trending-proxy/wrangler.jsonc`）。routes 绑 `trending.theuntold.ai/github-trending*` + legacy。
3. **preview 验证 Worker origin**（切域前，用 workers.dev 或临时路由）：确认 `/github-trending/` 反代到 `maxzyma.github.io/github-trending-digest/` 返回 200 且资源前缀正确；`/daily/2026-03-30-analysis.html` → 301。
4. **切自定义域到 trending-diggest**：仓 Settings → Pages → Custom domain = `trending.theuntold.ai`（GitHub 自动写 CNAME + 签证书）。CNAME 文件已在仓内。
5. **CF DNS 复核**（runbook §6.2）：`trending.theuntold.ai` A → GitHub Pages IP（185.199.108/109/110/111.153 四条），🟠 橙云，SSL/TLS = Full。zone id `35fede9...`。CF API 调用须 `env -u http_proxy -u https_proxy curl --noproxy '*'`（§6.5，防代理污染 Authorization）。
6. **live 验证（MUST 用 agent-browser，非 curl/WebFetch——§6.4 假阴性）**：
   - `/` → 门户首页（Hero+信源网格+最新流）200
   - `/claude-blog/` → 子站索引 200，CSS 不错位
   - `/github-trending/` → github-trending 网格首页 200，资源 `/github-trending/` 前缀
   - `/daily/2026-03-30-analysis.html` → 301 → `/github-trending/daily/2026-03-30-analysis.html`
   - `/github-trending/<不存在页>` → 透传上游 404（非 Worker 5xx）

## 回滚

- 切域回滚：自定义域重新绑回 github-trending-digest + 恢复其 CNAME + baseurl 回 ""（github-trending main revert TASK-006）。
- Worker 回滚：`wrangler rollback -c edge/trending-proxy/wrangler.jsonc` 或删除 routes。
- DNS A 记录不变（两者同为 GitHub Pages IP），回滚核心 = 自定义域归属 + baseurl。

## 已验证（implement 期，非 live）

- Worker `wrangler deploy --dry-run`：通过（3.16 KiB，bindings 解析）。
- Worker 单测 21/21 green（ALG-01/02 全 SC）。
- trending-diggest Jekyll 本地 docker 构建：门户 + claude-blog 子站全渲染。
- github-trending baseurl=/github-trending 本地构建：链接/资源前缀正确（90 处 /github-trending/ 前缀）。
- live CF 层（Worker route 绑定、origin Host、递归防护、agent-browser 核验）：**须 cutover 时在 CF 环境执行**（contracts.md「需 Cloudflare live 环境验证的测试层」）。
