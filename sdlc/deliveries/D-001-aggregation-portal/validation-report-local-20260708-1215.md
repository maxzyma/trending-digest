---
delivery: D-001-aggregation-portal
env: local
report_timestamp: "2026-07-08T12:15:00+0800"
stage: 1
loop_count: 0
loop_history: []
flaky: []
summary:
  automated_repeatable: "39/39"   # worker vitest 22 + build-verify 17
  sc_covered_local: 24            # 27 SC 中本地可断言 24
  sc_deferred_live: 3             # SC-02/03 + SC-15 GoatCounter live 部分
  cross_feature_regression: "N/A（aggregation-portal 为唯一 feature）"
---

# Validation Report — D-001 聚合门户（env=local）

## Summary（≤3 行）

- 自动可重复测试：**39/39 通过**（theuntold Worker vitest 22/22 + trending-diggest verify-build.sh 17/17）。
- 27 SC 中 **24 本地断言通过**；3 项（SC-02 DNS、SC-03 域名 live 渲染、SC-15 GoatCounter 运行时上报）需 CF live 环境，defer 到 cutover（contracts「需 Cloudflare live 验证的测试层」）。
- 跨 Feature 回归：**N/A** —— aggregation-portal 是本项目唯一 feature，无其他 feature 可回归。

## 执行台账

| 线 | 执行 | 结果 | 证据 provenance（可重复自动化） |
|----|------|------|------|
| 单元/逻辑（Worker） | ✅ | 22/22 | theuntold `tests/unit/trending-proxy/{router,handler}.test.ts`（`pnpm vitest run`） |
| 构建/结构（Jekyll） | ✅ | 17/17 | trending-diggest `scripts/verify-build.sh`（docker jekyll build + HTML 断言 + validate 红用例） |
| baseurl 前缀（github-trending） | ✅ | 90 处前缀 | `_config.yml baseurl=/github-trending` docker 构建断言 |
| 部署可行性（Worker） | ✅ | dry-run OK | `wrangler deploy --dry-run`（3.16 KiB, bindings 解析） |
| 跨 Feature 回归 | N/A | — | 唯一 feature，无回归对象 |
| UI（Playwright live） | N/A | — | Step 3.7 用户决策跳过（门户无交互，结构断言已覆盖）；live 渲染 defer 到 cutover |

## 主追溯矩阵（SC → TC → 实现/证据位置 → 运行结果）

| SC | TC | 实现/证据位置 | 结果 |
|----|-----|--------------|------|
| SC-01 | TC-API-FUNC-001 | trending-diggest `_config.yml`+`.github/workflows/pages.yml`; verify-build.sh | PASS |
| SC-02 | TC-API-BND-001 | `CNAME`（文件存在=trending.theuntold.ai）；DNS live 行为 | DEFERRED-live（cutover agent-browser） |
| SC-03 | TC-API/UI（域名 live） | 渲染链路 | DEFERRED-live（cutover agent-browser） |
| SC-04 | TC-UI-FUNC-001 | `_layouts/portal-home.html`; verify-build.sh | PASS |
| SC-05 | TC-UI-FUNC-002 | `_data/sources.yml`+portal-home; verify-build.sh | PASS |
| SC-06 | TC-UI-BND-001 | portal-home（proxied 卡仅链接）; verify-build.sh | PASS |
| SC-07 | TC-UI-FUNC-003 | portal-home 最新流块; verify-build.sh | PASS |
| SC-08 | TC-UI-FUNC-004 | portal-home ALG-03 Liquid; verify-build.sh（倒序+≤N） | PASS |
| SC-09 | TC-UI-BND-002 | portal-home（仅 site.claude_blog）; verify-build.sh | PASS |
| SC-10 | TC-UI-BND-003 | portal-home 空集分支; verify-build.sh（空 collection 构建） | PASS |
| SC-11 | TC-UI-FUNC-005 | `claude-blog/index.html`+collection; verify-build.sh | PASS |
| SC-12 | TC-API-FUNC-006 | collection permalink /claude-blog/:path/; verify-build.sh（28 post 前缀内链） | PASS |
| SC-13 | TC-API-BND-004 | 同仓直出（route-scoped Worker 不介入）; verify-build.sh + router.test（passthrough） | PASS |
| SC-14 | TC-API-FUNC-002 | theuntold `edge/trending-proxy` handler.test（proxy-gh + origin 映射） | PASS |
| SC-15 | TC-API-FUNC-003/007 | github-trending `baseurl=/github-trending`（构建 90 前缀）；GoatCounter 运行时上报 | PASS(build) / DEFERRED-live(GoatCounter) |
| SC-16 | TC-API-BND-002 | 运行时反代（无拷贝）; verify-build.sh（产物无 gh 内容） | PASS |
| SC-17 | TC-API-FUNC-004 | router/handler.test（301 + query 保留） | PASS |
| SC-18 | TC-API-FUNC-005 | router.test（daily/weekly/monthly/assets + .html + weekly 变体锚定正则） | PASS |
| SC-19 | TC-API-BND-003 | router.test（/ → passthrough，非 301） | PASS |
| SC-20 | TC-API-ERR-001 | `scripts/validate-site.rb`; verify-build.sh（缺 title 非零退出） | PASS |
| SC-21 | TC-UI-ERR-001 | validate-site.rb SourceCard 校验; verify-build.sh | PASS |
| SC-22 | TC-UI-ERR-002 | portal-home where_exp + validate-site.rb WARN; verify-build.sh | PASS |
| SC-23 | TC-API-ERR-003 | validate-site.rb collection permalink 前缀; verify-build.sh | PASS |
| SC-24 | TC-API-ERR-002 | handler.test（上游 5xx/网络失败 → X-Proxy-Error 非 200） | PASS |
| SC-25 | TC-API-ERR-004 | router.test（未匹配 → passthrough，不误 301，锚定防越界） | PASS |
| SC-26 | TC-API-BND-005 | router/handler.test（无尾斜杠 301） | PASS |
| SC-27 | TC-API-ERR-005 | handler.test（上游 404 透传，非 5xx） | PASS |

**覆盖**：27 SC 中 24 本地 PASS（含 SC-15 build 侧）；SC-02/03 + SC-15 GoatCounter live 侧 = DEFERRED-live（3 项，cutover 时 agent-browser 验，runbook §6.6）。

## Extension TC

test-cases.md 无 "## Extension TC" 段 → 无 Extension TC，SKIPPED（不计 FAIL）。

## 反向追溯（超范围实现）

扫本交付改动：无 SC 之外的多余实现。所有产出可追溯到 SC/task。`excess_code: false`。

## Real-world 同类问题前置检查（CLI / 外部依赖路径实测）

| 路径 | 实测信源 | 结果 |
|------|---------|------|
| Jekyll 构建（真实 docker jekyll/builder:4，非 mock） | `verify-build.sh` docker build exit 0 + 产物断言 | 通过 |
| Worker fetch → GitHub Pages origin（真实 fetch 语义） | vitest mock fetch 断言 origin URL/Host 剥离/状态分支 | 逻辑通过；真实 origin 连通 defer cutover |
| `wrangler deploy` 打包 | `wrangler deploy --dry-run` exit 0（3.16 KiB, bindings 解析） | 通过 |
| CF live（Route 绑定 / origin Host / 递归 / DNS / agent-browser） | contracts live-CF 层 | DEFERRED cutover（runbook §6，非 punt：有明确 runbook + 触发时机） |

## Bug 分类 / 回环 / Flaky

无失败 TC。loop_count=0，flaky=[]。

## 本地 UI 决策（Step 3.7）

- **AI 询问时间**：2026-07-08 12:15
- **决策上下文呈现**：UI spec=有（无交互静态站）/ TF=未配置（代码未 merge）/ 本机框架=可 jekyll serve+Playwright / AI 预判=TC-UI 结构断言已由 verify-build.sh 17/17 覆盖，local-ui 边际价值有限
- **用户决策**：跳过
- **决策依据**：门户无交互（纯链接页），结构性 TC-UI 已在构建产物 HTML 上断言通过；真实浏览器渲染/链接可点 defer 到 cutover live 验证
- **替代方案**：verify-build.sh HTML 结构断言（Level 构建产物）+ cutover 时 agent-browser live 验证（runbook §6.6）

## 结论

本地可断言范围内**全通过（39/39 自动可重复 + 24/27 SC）**。跨 Feature 回归 N/A（唯一 feature）。3 项 live-CF SC 有明确 cutover runbook + agent-browser 验证时机，非 mock-only punt。

**阶段语义**：本次为本地构建/逻辑验收（stage 1 本机，非 DF 服务环境——本交付无后端服务）。真正的 live 系统验收（域名可达 + 反代连通 + agent-browser）在 post-G5 cutover 执行。

## 信源清单

- test-cases.md（27 TC 主表，追溯基准）
- behaviors/*.gherkin（SC-01~27）、algorithms.md（ALG-01/02/03）、contracts.md（路由/301/live-CF 层）
- 证据脚本：trending-diggest `scripts/verify-build.sh` + `scripts/validate-site.rb`；theuntold `tests/unit/trending-proxy/*.test.ts`
- cutover-runbook.md（live SC defer 依据）
