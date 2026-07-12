# Trending Diggest

为中文技术读者归档公开技术资源（当前：Claude 官方博客）的中文双语译读，并通过 Jekyll 提供带索引的公开阅读站。本仓承接**公开内容产物与展示契约**；抓取、译读、调度、凭据和运行状态归仓外处理引擎与私有 coworkspace。

## 仓库职责边界

- **本仓存**：`sources/<source>/posts/`（中文双语译读）、`index.md`（索引）、可公开的 `manifest.json`（来源与产物 lineage）、Jekyll 布局与站点验证脚本。
- **条件保留**：`raw/` 仅在来源授权和 archive policy 明确允许时公开；默认原始快照留在仓外。
- **兼容状态**：`sources/claude-blog/state/processed.json` 仅供旧 Claude Blog 生产脚本过渡使用，不是新流水线的长期增量真相；迁移完成后由 coworkspace 私有 runtime state 取代。
- **不在本仓**：抓取/翻译实现、模型 prompt、自动化脚本、凭据、cron、重试/死信/游标、钉钉目录与通知路由。
- **展示职责**：本仓直接拥有门户和同仓小源的 Jekyll 页面；跨仓来源可通过既有聚合路由接入。

## 生产者契约

- 通用处理引擎输出 canonical package；本仓的 archive adapter 负责 front matter、目录、索引、manifest 和构建校验。
- 钉钉等远端目标必须从同一 canonical package 独立渲染，禁止回读本仓 Markdown 作为发布源。
- 写入前必须支持 dry-run；写入后必须校验文章、索引和 manifest 一致性。
- archive adapter 不得隐式 commit/push；版本控制操作由显式编排步骤负责。

## 技术栈

无运行时服务、无数据库；产物即 markdown + JSON 文件，按 `年/月` 组织。

## SDLC

本项目已接入 AI-SDLC。规格入口 `sdlc/specs/`，需求队列 `sdlc/backlog/`，交付记录 `sdlc/deliveries/`。
