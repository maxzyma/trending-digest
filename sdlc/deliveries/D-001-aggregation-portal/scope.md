## Summary

单一入口 `trending.theuntold.ai` 聚合多源技术译读/深读：本仓自建 Jekyll 门户首页 + 小源同仓子站（`/claude-blog/`），github-trending 大站经 CF Worker 边缘反代挂入（`/github-trending/`）+ 旧 URL 301 兜底。各源独立仓、独立维护、独立部署，运行时反代聚合、无 submodule、无跨仓拷贝。

## 目标与范围

- **目标**：把分散在多仓的技术内容源，用单一入口域对外像一个站呈现，降低读者发现成本；本仓从纯 markdown 归档仓升级为聚合入口宿主。受益方：中文技术读者 + 站点运营者。
- **In Scope**：
  - US-00 本仓 Jekyll 站点骨架 + GitHub Pages 部署 + CNAME（`trending.theuntold.ai`）
  - US-01 门户首页（Hero + 信源导航网格 + 最新流占位区块）
  - US-02 首页最新内容流（仅同仓小源倒序）
  - US-03 小源同仓分目录子站（`/claude-blog/`，baseurl 正确）
  - US-04 github-trending 经 CF Worker 反代（Worker 代码落 theuntold 仓；github-trending 仓设 `baseurl=/github-trending`）
  - US-05 旧 URL 301 重定向兜底（Worker，permalink 模式从 github-trending `_config.yml` 枚举）
- **Out of Scope**（来源 stories.md「不在范围」+ 方案 §5/§7）：
  - 跨仓实时聚合首页最新流（github-trending 明细不进首页流，仅导航卡）
  - 自建/改造 github-trending 或 claude-blog 的内容生产流水线（仅聚合与路由）
  - 新增 claude-blog 之外的小源内容（本次只接既有源 + 预留目录机制）
  - Worker 部署 / CF 配置的具体实施细节（Design 阶段决定）
  - "未来新增源零改 Worker" 架构意图（Design 决策，非本批 AC）

## 关键约束

- **GitHub Pages 一域一仓**：一个自定义域只能绑一个仓 site → 纯 Pages 无法单域多仓路径聚合，故引入 Worker（方案 §3）。
- **submodule 路不通**：github-trending 的 `pages.yml` 为 `submodules: false`，改 recursive 会拖下其 ~200 repos submodule（方案 §3）。
- **首页跨仓边界**：本仓构建期拿不到 github-trending 内容（Worker 是运行时反代）→ 首页最新流只能聚同仓小源（方案 §5）。
- **公开合规**：公开仓只纳入公开可访问内容（继承 nfr-baseline 合规段）。
- **子站 baseurl 铁律**：每个经路径挂载的站 Jekyll `baseurl` 须设为对应路径，否则 CSS/内链相对路径错位。

## 跨 Feature / 跨仓影响声明

- 本仓（trending-diggest）：新增 Jekyll 骨架 + 门户首页 + `/claude-blog/` 子站渲染（US-00~03）。与既有数据流水线 3 条 backlog 正交（它们产 markdown，本 Feature 消费/渲染）。
- theuntold 仓：新增 CF Worker 反代 + 301 规则代码（US-04~05）；trending.theuntold.ai DNS/CNAME 归属（runbook §6）。
- github-trending-digest 仓：`_config.yml` 设 `baseurl=/github-trending`（US-04 AC-2）。
- → 交付物分布 3 仓，G5 release-plan 须分仓列（详见 backlog 条目跨仓依赖表）。
