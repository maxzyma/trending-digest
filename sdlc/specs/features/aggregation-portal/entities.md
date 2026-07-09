# 实体: 聚合门户

> 本 Feature 无数据库；"实体" = 静态站配置对象 + 内容条目 + 重定向规则。持久化形式 = Jekyll 配置/数据文件 + markdown。owner 均为本仓（github-trending 内容归其独立仓，本 Feature 不拥有）。

## SourceCard（信源导航卡配置）

首页导航网格每源一张卡。owner：本仓（门户配置）。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| key | string | NOT NULL, UNIQUE | 源标识（如 `github-trending` / `claude-blog`） |
| title | string | NOT NULL | 卡片显示名 |
| summary | string | NOT NULL | 一句简介 |
| entry_url | string | NOT NULL | 入口路径（如 `/github-trending/` / `/claude-blog/`） |
| kind | enum(`same-repo`,`proxied`) | NOT NULL | 同仓直出 / Worker 反代 |

- **INV-02 关联**：`proxied` 卡（github-trending）仅存链接，不含明细数据。
- 首批：至少含 `github-trending`（proxied）+ `claude-blog`（same-repo）两卡（SC-05）。

## DigestEntry（同仓小源 digest 条目，最新流用）

owner：本仓（claude-blog 等同仓源）。复用既有归档产物，不新建存储。

| 字段 | 类型 | 来源 | 说明 |
|------|------|------|------|
| source_key | string | 同仓源目录 | 归属源 |
| title | string | post front matter / index | 标题 |
| published_at | date | post 元数据 | 最新流倒序键（SC-08） |
| url | string | 归档路径 | 子站内链接 |

- **INV-02**：最新流只聚 same-repo 源的 DigestEntry，不含 github-trending（SC-09）。
- 空集时区块优雅留空（SC-10）。

## RedirectRule（旧 URL 301 规则，US-05）

owner：theuntold 仓（Worker 代码），本 Feature 定义契约结构。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| pattern | string | NOT NULL, 显式前缀/模式（非 catch-all） | 旧 URL 匹配模式 |
| target | string | NOT NULL | 301 目标（`/github-trending/...`） |
| status | int | = 301 | 固定 |

- **INV-04**：规则集不得命中门户根 `/`（SC-19）。
- pattern 集从 github-trending `_config.yml` permalink 枚举（SC-18，Design/Implement 落地）。

## 跨 Feature / 跨仓归属

- SourceCard / DigestEntry：本仓 owner。
- github-trending 站内容：独立仓 owner，本 Feature 仅经 Worker 反代引用，不拥有、不拷贝（SC-16）。
- RedirectRule 运行时载体：theuntold 仓 Worker。
