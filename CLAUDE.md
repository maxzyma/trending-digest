# Trending Diggest

为中文技术读者归档公开技术资源（当前：Claude 官方博客）的中文双语译读，并通过 Jekyll 提供带索引的公开阅读站。本仓承接**公开内容产物与展示契约**；抓取、译读、调度、凭据和运行状态归仓外处理引擎与私有编排层。

## 仓库职责边界

- **本仓存**：`sources/<source>/posts/`（中文双语译读）、`index.md`（索引）、可公开的 `manifest.json`（来源与产物 lineage）、`taxonomy/`（跨源主题聚类数据，由编排层写入、本仓渲染到 `/taxonomy/`）、Jekyll 布局与站点验证脚本。
- **原文快照**：`raw/`（源站 HTML、字幕等）随归档一并公开保存，与译读产物同目录。它不参与站点渲染，`materialize_collection.py` 不会把它复制进 collection。
- **兼容状态**：`sources/claude-blog/state/processed.json` 仅供旧 Claude Blog 生产脚本过渡使用，不是新流水线的长期增量真相；迁移完成后由编排层的私有 runtime state 取代。
- **不在本仓**：抓取/翻译实现、模型 prompt、自动化脚本、凭据、cron、重试/死信/游标、钉钉目录与通知路由。
- **展示职责**：本仓直接拥有门户和同仓小源的 Jekyll 页面；跨仓来源可通过既有聚合路由接入。

## 生产者契约

- 通用处理引擎输出 canonical package；本仓的 archive adapter 负责 front matter、目录、索引、manifest 和构建校验。
- 钉钉等远端目标必须从同一 canonical package 独立渲染，禁止回读本仓 Markdown 作为发布源。
- 写入前必须支持 dry-run；写入后必须校验文章、索引和 manifest 一致性。
- archive adapter 不得隐式 commit/push；版本控制操作由显式编排步骤负责。

## 技术栈

无运行时服务、无数据库；产物即 markdown + JSON 文件，按 `年/月` 组织。

## 目录结构

| 路径 | 职责 |
|------|------|
| `sources/<source>/` | 内容源：生产者写入的 canonical 归档包 |
| `taxonomy/` | 跨源主题聚类数据（编排层写入），构建期物化成 `/taxonomy/` 页面 |
| `pages/` | 独立入口页（`/claude-blog/`、`/talks/`），各自带显式 `permalink` |
| `index.md`、`_layouts/`、`_data/`、`_config.yml` | Jekyll 站点：门户首页、布局、信源卡、构建配置 |
| `scripts/` | 构建期物化与 fail-loud 校验 |
| `specs/` | 设计与契约 |
| `docs/` | 运维与对外契约 |
| `TODO.md` | 待办 |

**三处同名不可互换**：`sources/claude-blog/` 是内容源，`_claude_blog/` 是构建期物化的 gitignored collection（由 `scripts/prepare-collections.sh` 生成），`pages/claude-blog.html` 是 `/claude-blog/` 的入口页。`talks` 同理。

## 文档结构

单人维护，不走多人协作流程。文档只分三处：

- `specs/` — 设计与契约事实源：[总览](specs/overview.md)、[ADR](specs/decisions.md)、[教训](specs/lessons.md)、[门户契约](specs/portal/README.md)、[待做的三站重设计](specs/editorial-redesign.md)
- `docs/` — 运维与对外契约：[生产者契约](docs/producer-contract.md)、[cutover runbook](docs/cutover-runbook.md)
- `TODO.md` — 待办

改门户结构、路由规则或站点校验脚本前先读 `specs/`。SC-01~27 的定义源在 `specs/portal/behaviors/*.gherkin`，断言实现在 `scripts/verify-build.sh` 与 `scripts/validate-site.rb`，改行为规格时三处同步。
