---
test_id_version: v2
shard: all
---

# Test Cases: 聚合门户（单分片 all）

## 主表

| TC | form | focus | 用例 | covers (SC) |
|----|------|-------|------|-------------|
| TC-API-01 | api | functional | 触发 Pages 构建 → 断言构建成功、产物 HTML 存在、构建日志无 submodule 拉取 | SC-01 |
| TC-API-02 | api | boundary | 断言 CNAME 文件内容=trending.theuntold.ai；DNS 解析指向本仓 Pages | SC-02 |
| TC-API-03 | api | error | 注入 _config.yml 缺失必填项 → 断言构建非零退出、无产物发布 | SC-20 |
| TC-API-04 | api | functional | GET /github-trending/ → 断言反代返回 github-trending 仓页面（200） | SC-14 |
| TC-API-05 | api | functional | GET /github-trending/ 页面 → 断言 CSS/JS src 前缀 /github-trending/ 200、permalink 前缀、GoatCounter script 可达且 **site-code 与迁移前一致**（baseurl 变更不改统计站点 ID）、上报 path 含 /github-trending/ | SC-15 |
| TC-API-06 | api | boundary | 断言门户仓无 github-trending 内容拷贝（构建产物中无其明细文件） | SC-16 |
| TC-API-07 | api | error | mock 上游 Pages 502 → GET /github-trending/ 断言 Worker 返回非 200 可辨识错误；同时 GET / 返 200 门户 | SC-24 |
| TC-API-08 | api | functional | fixture：GET /daily/2026-03-30-analysis → 断言 301 Location=/github-trending/daily/2026-03-30-analysis | SC-17 |
| TC-API-09 | api | functional | fixture 组：daily/weekly/monthly/assets 各样例 → 全断言 301 到对应 /github-trending/ 前缀 | SC-18 |
| TC-API-10 | api | boundary | GET / → 断言 200 门户首页、非 301（不被重定向命中） | SC-19 |
| TC-API-11 | api | boundary | GET /claude-blog/ 与 GET / → 断言均本仓 Pages 直出 200；Worker 不改写非 /github-trending/ 路径 | SC-13 |
| TC-API-12 | api | functional | GET /claude-blog/ 资源 → 断言 CSS 200、内链目标可达 | SC-12 |
| TC-API-13 | api | error | fixture：baseurl 未设的子站页 → 断言 CSS/内链 404；构建/校验步骤非零退出 | SC-23 |
| TC-API-14 | api | error | fixture：不匹配任何模式的旧路径 → 断言不返 301、返 404 或 200、不返 5xx | SC-25 |
| TC-UI-01 | ui | functional | 渲染 trending.theuntold.ai/ → 断言页面含 Hero 区（品牌+定位）+ 信源导航网格区 | SC-04 |
| TC-UI-02 | ui | functional | 首页导航网格 → 断言 ≥2 卡，github-trending 卡 href=/github-trending/，claude-blog 卡 href=/claude-blog/ | SC-05 |
| TC-UI-03 | ui | boundary | 首页 HTML → 断言不含 github-trending 明细条目（仅导航卡） | SC-06 |
| TC-UI-04 | ui | functional | 首页 → 断言存在最新流占位区块 | SC-07 |
| TC-UI-05 | ui | error | 注入 SourceCard 缺 title → 断言构建 fail-loud 指出缺失字段、不产残缺网格 | SC-21 |
| TC-UI-06 | ui | functional | 首页最新流 → 断言按 published_at 倒序、仅同仓源、条数≤配置 N | SC-08 |
| TC-UI-07 | ui | boundary | 首页最新流 → 断言不含 github-trending 明细 | SC-09 |
| TC-UI-08 | ui | boundary | 造空同仓 digest → 断言最新流区块留空/隐藏、首页不报错 | SC-10 |
| TC-UI-09 | ui | error | 注入某 digest 缺 published_at → 断言跳过该条 + 构建日志告警 + 其余倒序正常 | SC-22 |
| TC-UI-10 | ui | functional | 渲染 /claude-blog/ → 断言本仓 Jekyll 渲染、CSS/内链前缀正确不错位 | SC-11 |

## focus × form 矩阵（单张）

| focus \ form | ui | api |
|--------------|-----|-----|
| functional | TC-UI-01/02/04/06/10 | TC-API-01/02/04/05/08/09/12 |
| boundary | TC-UI-03/07/08 | TC-API-06/10/11 |
| error | TC-UI-05/09 | TC-API-03/07/13/14 |
| idempotent | （0 格）见下依据 | （0 格）见下依据 |

**0 格依据**：`idempotent` 行两 form 均 0——本 feature 无写操作/无状态变更（纯静态渲染 + 无副作用反代/301），幂等性不适用；301/反代天然幂等（GET 无副作用），无需独立幂等 TC。合理留空。

## 硬下限校验

- form=api：14 条 ≥ contracts 契约条目数（路由表 6 行 + 301 fixture 6 模式 = 12；14 ≥ 12）✓
- form=ui：11 条 ≥ ui/views 新增页面数（1：pc-portal-home）✓

## Extension TC

- 无 impact_map（本 feature 无既有前端页面被后端改动波及——全新站）→ 无 EXT:api-impact TC。
- missing-view：无（behaviors 唯一 pc- 锚点 pc-portal-home 已有 view spec）。
