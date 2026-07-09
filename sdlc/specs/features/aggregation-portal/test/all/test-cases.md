---
test_id_version: v2
shard: all
---

# Test Cases: 聚合门户（单分片 all）

> TC-ID 规范形 `TC-{FORM}-{FOCUS}-{NNN}`（FORM=UI/API，FOCUS=FUNC/BND/ERR，NNN 3 位）。

## 主表

| TC | form | focus | 用例 | covers (SC) |
|----|------|-------|------|-------------|
| TC-API-FUNC-001 | api | functional | 触发 Pages 构建 → 断言构建成功、产物 HTML 存在、构建日志无 submodule 拉取 | SC-01 |
| TC-API-BND-001 | api | boundary | 断言 CNAME 文件内容=trending.theuntold.ai；访问该域返回本仓 Pages 门户（行为层，非 IP 断言） | SC-02 |
| TC-API-ERR-001 | api | error | 注入 _config.yml 缺失必填项 → 断言构建非零退出、无产物发布 | SC-20 |
| TC-API-FUNC-002 | api | functional | GET /github-trending/ → 断言反代返回 github-trending 仓页面（200） | SC-14 |
| TC-API-FUNC-003 | api | functional | GET /github-trending/ 页面 → 断言 CSS/JS src 前缀 /github-trending/ 200、permalink 前缀、GoatCounter script 可达且 site-code 与迁移前一致、上报 path 含 /github-trending/ | SC-15 |
| TC-API-BND-002 | api | boundary | 断言门户仓无 github-trending 内容拷贝（构建产物中无其明细文件） | SC-16 |
| TC-API-ERR-002 | api | error | mock 上游 Pages 5xx → GET /github-trending/ 断言 Worker 返非 200 可辨识错误；同时 GET / 返 200 门户 | SC-24 |
| TC-API-FUNC-004 | api | functional | fixture：GET /daily/2026-03-30-analysis → 断言 301 Location=/github-trending/daily/2026-03-30-analysis（含 query 保留） | SC-17 |
| TC-API-FUNC-005 | api | functional | fixture 组：daily/weekly/monthly/assets 各样例（锚定正则）→ 全断言 301 到对应 /github-trending/ 前缀 | SC-18 |
| TC-API-BND-003 | api | boundary | GET / → 断言 200 门户首页、非 301（不被重定向命中） | SC-19 |
| TC-API-BND-004 | api | boundary | GET /claude-blog/ 与 GET / → 断言均本仓 Pages 直出 200；Worker 不改写非 /github-trending/ 路径 | SC-13 |
| TC-API-FUNC-006 | api | functional | GET /claude-blog/ 资源 → 断言 CSS 200、内链目标可达 | SC-12 |
| TC-API-ERR-003 | api | error | fixture：baseurl 未设的子站页 → 断言 CSS/内链 404；构建/校验步骤非零退出 | SC-23 |
| TC-API-ERR-004 | api | error | fixture：不匹配任何模式的旧路径 → 断言不返 301、返 404 或 200、不返 5xx | SC-25 |
| TC-API-BND-005 | api | boundary | GET /github-trending（无尾斜杠）→ 断言 301 Location=/github-trending/ | SC-26 |
| TC-API-ERR-005 | api | error | mock 上游真实 404 → GET /github-trending/<不存在页> → 断言 Worker 透传 404（非 5xx 错误页） | SC-27 |
| TC-API-FUNC-007 | api | functional | GET /github-trending/ 页面 → 断言 canonical/sitemap/feed/OG URL 均含 /github-trending/ 前缀（或显式记缺失）；旧根路径外链样例 301 不断链 | SC-15 |
| TC-UI-FUNC-001 | ui | functional | 渲染 trending.theuntold.ai/ → 断言页面含 Hero 区（品牌+定位）+ 信源导航网格区 | SC-04 |
| TC-UI-FUNC-002 | ui | functional | 首页导航网格 → 断言 ≥2 卡，github-trending 卡 href=/github-trending/，claude-blog 卡 href=/claude-blog/ | SC-05 |
| TC-UI-BND-001 | ui | boundary | 首页 HTML → 断言不含 github-trending 明细条目（仅导航卡） | SC-06 |
| TC-UI-FUNC-003 | ui | functional | 首页 → 断言存在最新流占位区块 | SC-07 |
| TC-UI-ERR-001 | ui | error | 注入 SourceCard 缺 NOT NULL 字段（key/title/summary/entry_url/kind 之一）→ 断言构建 fail-loud 指出缺失字段、不产残缺网格 | SC-21 |
| TC-UI-FUNC-004 | ui | functional | 首页最新流 → 断言按 published_at 倒序、仅同仓源、条数≤配置 N | SC-08 |
| TC-UI-BND-002 | ui | boundary | 首页最新流 → 断言不含 github-trending 明细 | SC-09 |
| TC-UI-BND-003 | ui | boundary | 造空同仓 digest → 断言最新流区块留空/隐藏、首页不报错 | SC-10 |
| TC-UI-ERR-002 | ui | error | 注入某 digest 缺 published_at → 断言跳过该条 + 构建日志告警 + 其余倒序正常 | SC-22 |
| TC-UI-FUNC-005 | ui | functional | 渲染 /claude-blog/ → 断言本仓 Jekyll 渲染、CSS/内链前缀正确不错位 | SC-11 |

## focus × form 矩阵（单张）

| focus \ form | ui | api |
|--------------|-----|-----|
| functional | TC-UI-FUNC-001/002/003/004/005 | TC-API-FUNC-001~007 |
| boundary | TC-UI-BND-001/002/003 | TC-API-BND-001~005 |
| error | TC-UI-ERR-001/002 | TC-API-ERR-001~005 |
| idempotent | （0 格）见下依据 | （0 格）见下依据 |

**0 格依据**：`idempotent` 行两 form 均 0——本 feature 无写操作/无状态变更（纯静态渲染 + 无副作用反代/301），幂等性不适用；301/反代 GET 天然幂等，无需独立幂等 TC。合理留空。

## 硬下限校验

| 维度 | 分母（下限） | 声明（主表实数） | 状态 |
|------|------------|----------------|------|
| form=ui | 1 | 10 | pass |
| form=api | 12 | 17 | pass |

- form=ui 分母 = ui/views 新增页面数（1：pc-portal-home）；主表 form=ui TC = 10 ≥ 1 ✓
- form=api 分母 = contracts 契约条目（路由 6 行 + 301 fixture 6 模式 = 12）；主表 form=api TC = 17 ≥ 12 ✓

## 需 CF live 验证层（不可本地静态覆盖，G4 在 CF 环境执行）

以下断言依赖 Cloudflare 运行时环境，本地静态测试无法覆盖，标 "requires live CF validation"，G4 在 CF 环境跑：
- Worker Route 绑定生效（trending.theuntold.ai/* 命中 Worker）
- cache 行为（`cf-cache-status`、purge、bypass）
- origin Host header / SNI / 递归防护（Worker fetch Pages 域非自定义域，无无限子请求）
- 上游 5xx/网络失败 failure-mode smoke（TC-API-ERR-002 的 CF 环境版）

## Extension TC

- 无 impact_map（本 feature 无既有前端页面被后端改动波及——全新站）→ 无 EXT:api-impact TC。
- missing-view：无（behaviors 唯一 pc- 锚点 pc-portal-home 已有 view spec）。
