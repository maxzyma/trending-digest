# Trending Diggest

为中文技术读者自动抓取公开技术资源（当前：Claude 官方博客）、生成中文双语译读、归档为带索引可检索的 markdown 库。本仓只承接**产出物**；抓取/译读/调度脚本与凭据归私有 coworkspace 仓。

## 仓库职责边界

- **本仓存**：`sources/<source>/` 下的 `raw/`（原文 HTML）、`posts/`（中文双语译读）、`index.md`（索引）、`state/processed.json`（增量去重）
- **不在本仓**：自动化脚本/凭据（→ coworkspace）、前端展示站点（→ `projects/external/theuntold`，trending.theuntold.io；其迁入本仓的方案讨论中）

## 技术栈

无运行时服务、无数据库；产物即 markdown + JSON 文件，按 `年/月` 组织。

## SDLC

本项目已接入 AI-SDLC。规格入口 `sdlc/specs/`，需求队列 `sdlc/backlog/`，交付记录 `sdlc/deliveries/`。
