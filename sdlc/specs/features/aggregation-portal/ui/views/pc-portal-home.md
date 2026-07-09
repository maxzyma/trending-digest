# View: 门户首页（pc-portal-home）

路由：`/`（本仓 Pages 直出，非 Worker 反代）。覆盖 US-01 / US-02。视觉对齐 github-trending 卡片网格（同字体族 + 深浅色 + editorial 风）。

## 区块结构（三区，方案 §5）

| 区块 | 内容 | 数据来源 | covers |
|------|------|---------|--------|
| Hero | 品牌 + 一句定位（多源技术资讯译读/深读聚合） | 静态（`_config.yml` title/description） | SC-04 |
| 信源导航网格 | 每源一卡：title + summary + 入口链接 | `SourceCard`（首页数据文件，见 entities.md） | SC-04, SC-05 |
| 最新内容流 | 同仓小源最新若干条 digest 倒序 | `DigestEntry`（同仓 `site.pages` 构建期聚合） | SC-07(占位), SC-08~10 |

## 字段映射（SourceCard → 卡片）

| 卡片元素 | SourceCard 字段 | 约束 |
|---------|----------------|------|
| 卡标题 | title | NOT NULL |
| 卡简介 | summary | NOT NULL |
| 入口链接 href | entry_url | 同仓源 `/claude-blog/`；反代源 `/github-trending/` |
| 反代标记 | kind | proxied 卡不含明细（INV-02 / SC-06） |

首批卡：GitHub Trending（kind=proxied，→ `/github-trending/`）+ Claude Blog（kind=same-repo，→ `/claude-blog/`）。

## 字段映射（DigestEntry → 最新流条目）

| 元素 | DigestEntry 字段 | 说明 |
|------|-----------------|------|
| 条目标题 | title | — |
| 时间 | published_at | 倒序键 |
| 链接 | url | 同仓子站内链 |
| 源标 | source_key | 仅 same-repo 源（SC-09 排除 github-trending） |

## 边界与状态

- 最新流空集 → 区块优雅留空/隐藏，不报错（SC-10）。
- 首页构建期不拉取 github-trending 内容（INV-02 / SC-06）。
- 无 fetch（纯静态构建期渲染）；数据来自 Jekyll 构建期 `site.pages` + 首页数据文件。

## 原型

`../prototype.html`（baseline，静态自包含，对齐 github-trending 观感；implement 阶段转为 Jekyll `_layouts/portal-home.html` + 数据文件）。
