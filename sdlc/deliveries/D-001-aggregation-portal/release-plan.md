# Release Plan — D-001 聚合门户

## Summary

单一入口 `trending.theuntold.ai` 聚合多源：trending-diggest 自建 Jekyll 门户 + claude-blog 子站直出；github-trending 经新建 CF Worker 边缘反代挂到 `/github-trending/*`；旧 URL 301 兜底。**交付物分布 3 仓**，合并与 live cutover 分离——merge 后按 cutover-runbook 原子切换生产域。

## 分仓变更清单

| 仓 | 分支 | 变更 | 合并动作 |
|----|------|------|---------|
| **trending-diggest**（本仓） | D-001-aggregation-portal | Jekyll 骨架 + 门户首页 + 最新流 + claude-blog collection + validate/verify 脚本 + CNAME + 8 post front-matter 修复 + SDLC 产物 | PR → main（G5） |
| **github-trending-digest** | D-001-aggregation-portal | `_config.yml` baseurl → `/github-trending` | PR → main（cutover 时序，见风险） |
| **theuntold** | D-001-aggregation-portal | 新建 `edge/trending-proxy/` CF Worker（反代 + 301）+ wrangler + 脚本 + 22 vitest | PR → main |

## 风险与缓解

| 风险 | 等级 | 缓解 |
|------|------|------|
| live cutover 断服（DNS 先切/Worker 未就绪 → `/github-trending/*` 404） | 高 | cutover-runbook 原子顺序（step 1 释放旧域 → 2 部署 Worker → 3 preview 验 → 4 切新域 → 6 agent-browser 验）；DNS A 记录不变，回滚=域归属+baseurl |
| github-trending baseurl merge 早于 cutover → 旧 live 站链接错位 | 中 | github-trending PR 不早于 cutover 窗口 merge；或 merge 后立即走 cutover |
| CF 凭据/wrangler 登录缺失 | 中 | cutover 前 `wrangler login` 或 CF API token（runbook §5.1/§6.5） |
| 3 项 live-CF SC 未 pre-merge 验 | 中 | 平台固有（一域一仓）；cutover §6.6 agent-browser 补验 |
| claude-blog 流水线未来产坏 YAML front matter | 低 | 存量 8 文件已修；跨仓流水线根因 follow-up |

## 回滚方案

- **Worker**：`wrangler rollback -c edge/trending-proxy/wrangler.jsonc` 或删 routes。
- **DNS/域**：自定义域重新绑回 github-trending-digest + 恢复其 CNAME + baseurl 回 ""（github-trending revert baseurl commit）。A 记录（GitHub Pages IP）不变，回滚核心 = 域归属 + baseurl，分钟级。
- **门户本仓**：Pages 从 main 构建，revert 对应 commit 即回退。

## 上线顺序（原子，详见 cutover-runbook.md）

1. 三仓 PR merge 到各自 main（Pages 从 main 部署）→ trending-diggest 门户在 `maxzyma.github.io/trending-diggest/` 可达（域未认领）
2. cutover：① github-trending-digest 释放自定义域 → ② 部署 Worker → ③ preview 验反代/301 → ④ trending-diggest 认领 `trending.theuntold.ai` → ⑤ CF DNS 复核（橙云+A+SSL Full）→ ⑥ agent-browser live 验 6 条
3. 验证通过 → 交付完成

## 灰度

静态站 + 边缘 Worker 无传统灰度；cutover 本身是切换点，preview 验证（step 3）= 灰度替代（切生产前在 preview/origin 路由验反代）。

## G5 审查点

- 3 仓分支代码 review + PR
- cutover 时序确认（谁先 merge、何时切域、CF 凭据就绪）
- live-CF 3 项 defer 接受（G4 已裁量）

## 信源清单

<!-- sources-manifest:begin -->
### D-001 @ 2026-07-09

- deliveries：`validation-report-local-20260708-1215.md`（G4 验证结果 + 追溯 + live-defer）、`cutover-runbook.md`（原子上线时序 + 回滚）、`ops-checklist.md`（运维上线动作）、`decisions.md`（ADR-001~004 + Option B/ALG-02 G3-delta）、`code-review-report.md`（0 critical）
- specs：`features/aggregation-portal/{contracts,algorithms,entities}.md` + `behaviors/*.gherkin`（SC-01~27）+ `_index.md`（INV-01/02/04 + 边界声明）
- code：本仓 `_config.yml`/`_layouts/`/`scripts/`；theuntold `edge/trending-proxy/`；github-trending-digest `_config.yml`
<!-- sources-manifest:end -->

