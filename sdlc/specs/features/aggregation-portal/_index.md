---
schema_version: 1
feature: aggregation-portal
status: active
spec_level: L3
artifacts:
  behavior_spec:
    path: behaviors/_index.md
    role: 行为契约索引（每 Rule 一个 .gherkin）
  contracts:
    path: contracts.md
    role: 路由/重定向契约（URL 路径映射 + 301 fixture）
  entities:
    path: entities.md
    role: 实体（信源卡配置 + digest 条目 + 重定向规则）
---

# Feature: 聚合门户（aggregation-portal）

单一入口 `trending.theuntold.ai` 聚合多源技术译读/深读内容。本仓自建 Jekyll 门户 + 小源同仓子站；github-trending 大站经 CF Worker 边缘反代挂入；旧 URL 301 兜底。

## 边界声明

- **拥有**：本仓 Jekyll 站点骨架、门户首页、小源子站渲染、`trending.theuntold.ai` CNAME。
- **消费（不拥有）**：claude-blog 等源的内容生产（归数据流水线 Feature）；github-trending 站内容（独立仓）；CF Worker 运行时（代码归 theuntold 仓）。
- **不做**：跨仓构建期聚合（首页最新流仅同仓小源）；改造各源内容流水线。

## 不变量

| ID | 不变量 | 保证机制 |
|----|--------|---------|
| INV-01 | 每个经路径挂载的站，其 Jekyll `baseurl` 必须等于挂载路径 | 否则 CSS/内链相对路径错位；US-03/US-04 AC |
| INV-02 | 门户首页构建期只依赖同仓内容 | 首页 HTML 不含 github-trending 明细（US-01 AC-3）；跨仓是运行时反代 |
| INV-03 | 单一自定义域仅绑一个仓 Pages（GitHub Pages 一域一仓） | 多仓路径聚合必经 Worker，不可用 submodule（scope 约束） |
| INV-04 | 旧 URL 301 规则为显式前缀/模式列表，非 catch-all | 门户根 `/` 不被重定向规则命中（US-05 AC-3） |

## Story 映射

| Story | Rule 文件 |
|-------|-----------|
| US-00 站点骨架 | `behaviors/site-skeleton.gherkin` |
| US-01 门户首页 | `behaviors/portal-homepage.gherkin` |
| US-02 最新内容流 | `behaviors/latest-stream.gherkin` |
| US-03 小源子站 | `behaviors/small-source-subsite.gherkin` |
| US-04 大站反代 | `behaviors/github-trending-proxy.gherkin` |
| US-05 旧 URL 重定向 | `behaviors/legacy-redirect.gherkin` |
