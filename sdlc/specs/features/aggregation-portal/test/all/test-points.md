---
test_id_version: v2
shard: all
derived_from_gherkin: behaviors/*.gherkin (SC-01~25)
note: 单分片——本 feature 为静态站 + CF Worker，非 API 分片场景，6 Rule 合并单 shard
---

# Test Points: 聚合门户（单分片 all）

> form 闭集：`ui`（页面渲染/构建产物）/ `api`（HTTP 状态码/反代/301 fixture）。
> focus 闭集：`functional` / `boundary` / `error` / `idempotent`。

## 总览表

| TP | form | focus | 测试点 | covers (SC) |
|----|------|-------|--------|-------------|
| TP-01 | api | functional | Pages 构建成功产出可访问 HTML，无 submodule 拉取 | SC-01 |
| TP-02 | api | boundary | CNAME=trending.theuntold.ai，域解析指向本仓 Pages | SC-02 |
| TP-03 | ui | functional | 占位/门户首页经 trending.theuntold.ai/ 可访问 | SC-03 |
| TP-04 | api | error | 配置错误 → 构建非零退出、阻断部署、不产残缺站 | SC-20 |
| TP-05 | ui | functional | 首页含 Hero + 信源导航网格两区块 | SC-04 |
| TP-06 | ui | functional | 导航网格 ≥2 卡，含 /github-trending/ 与 /claude-blog/ 入口链接 | SC-05 |
| TP-07 | ui | boundary | 首页 HTML 不含 github-trending 明细（仅导航卡） | SC-06 |
| TP-08 | ui | functional | 最新流占位区块存在 | SC-07 |
| TP-09 | ui | error | SourceCard 缺 NOT NULL 字段 → 构建 fail-loud 指出字段 | SC-21 |
| TP-10 | ui | functional | 最新流倒序列同仓小源 digest，条数=配置 N | SC-08 |
| TP-11 | ui | boundary | 最新流不含 github-trending 明细 | SC-09 |
| TP-12 | ui | boundary | 无同仓 digest → 区块优雅留空/隐藏，不报错 | SC-10 |
| TP-13 | ui | error | digest 缺 published_at → 跳过 + 构建日志告警，其余正常 | SC-22 |
| TP-14 | ui | functional | /claude-blog/ 本仓 Jekyll 渲染，CSS/内链前缀正确 | SC-11 |
| TP-15 | api | functional | /claude-blog/ 页面 CSS 200、内链可达 | SC-12 |
| TP-16 | api | boundary | / 与 /claude-blog/ 同属本仓 Pages 直出，Worker 仅管 /github-trending/* | SC-13 |
| TP-17 | api | error | 子站 baseurl 未设 → CSS/内链 404，构建/校验非零退出捕获 | SC-23 |
| TP-18 | api | functional | /github-trending/* 经 Worker 反代到独立仓 Pages | SC-14 |
| TP-19 | api | functional | github-trending baseurl=/github-trending：CSS/JS/permalink/GoatCounter 前缀正确 | SC-15 |
| TP-20 | api | boundary | 门户侧零跨仓拷贝（运行时边缘反代） | SC-16 |
| TP-21 | api | error | 上游仓 Pages 不可用 → Worker 返非 200 可辨识错误，不污染 / 与同仓 | SC-24 |
| TP-22 | api | functional | 旧内容子路径 → 301 到 /github-trending/ 对应新地址 | SC-17 |
| TP-23 | api | functional | 枚举模式（daily/weekly/monthly/assets）全 301 覆盖；裸 / 不在集合 | SC-18 |
| TP-24 | api | boundary | 显式模式列表非 catch-all；门户根 / 返 200 不被命中 | SC-19 |
| TP-25 | api | error | 未匹配旧路径不误 catch-all 301；返 404 或 200，不返 5xx | SC-25 |
| TP-26 | api | boundary | 无尾斜杠 /github-trending → 301 到 /github-trending/ | SC-26 |
| TP-27 | api | boundary | 上游真实 404/410 透传（不转 Worker 5xx，保 SEO 诊断） | SC-27 |
| TP-28 | api | functional | baseurl 迁移完整性：canonical/sitemap/feed/OG URL 均迁到 /github-trending/ 前缀（或显式缺失） | SC-15 |

## 覆盖率自检

- SC 全集：SC-01~27（27）；TP covers 并集：SC-01~27 ✓ 无缺口、无悬挂
- form 分布：ui 11 / api 17
- focus 分布：functional 13 / boundary 9 / error 6
- **需 CF live 验证层**（不可本地静态覆盖，G4 在 CF 环境执行）：Worker Route 绑定 / cache bypass·purge / origin Host·SNI·递归防护 / subrequest 行为 —— 见 contracts「需 Cloudflare live 环境验证的测试层」
