# 系统架构

### 技术栈

| 层级 | 技术选型 | 版本 |
|------|---------|------|
| 前端 | 无（展示归 theuntold 仓） | — |
| 后端 | 无运行时服务（批处理脚本在 coworkspace 仓） | — |
| 数据库 | 无（产物即文件） | — |
| 缓存 | 无 | — |
| 消息队列 | 无 | — |
| 基础设施 | 公开 git 仓库（存储 markdown / JSON 产物） | — |

### 核心设计原则

<!-- 约束所有 Feature 设计的顶层原则，前置于细节之前 -->

1. 本仓是产出存储边界：只存 markdown 归档 + 原文链接 + state，自动化脚本与凭据归 coworkspace 私有仓
2. 增量幂等：以 `state/processed.json` 的 URL 集合为去重真相，重复运行不产生重复产物
3. 文件即数据：按 `年/月` 分层组织，无运行时服务、无数据库
4. 公开合规边界：公开仓只纳入公开可访问内容

### 系统结构图

```
[coworkspace cron] → [抓取/译读脚本(coworkspace 私有仓)]
                              │ 写产物
                              ▼
        ┌───────── 本仓 publications/trending-diggest ─────────┐
        │  raw/{year}/{month}/*.html      (原文 HTML 归档)      │
        │  posts/{year}/{month}/*.md      (中文双语译读)        │ → [theuntold 站点]
        │  index.md                       (索引表)              │ → [钉钉文档]
        │  state/processed.json           (增量去重)            │
        └────────────────────────────────────────────────────┘
```

### 内部逻辑模块

<!-- 产物侧的逻辑分区（实现脚本在 coworkspace） -->

| 模块 | 对应 Feature | 核心职责 | 关键组件 |
|------|-------------|---------|---------|
| 抓取/去重 | claude-blog-ingestion | 拉源站列表、按 state 去重、存 raw HTML | `state/processed.json`, `raw/` |
| 译读归档 | bilingual-digest-format | 原文 → 中文双语译读 markdown | `posts/{year}/{month}/` |
| 索引维护 | archive-index-maintenance | 维护 index.md 索引表 | `index.md` |

### 对外服务门面

无对外服务门面（产物经下游仓直接读取文件消费）。

### 服务路由上下文

| 项 | 值 | 来源 |
|----|-----|------|
| service_prefix | `无` | 无运行时服务 |
| 完整 URL 模式 | — | — |
| 验证信源 | — | — |

### 鉴权与数据隔离

无鉴权链路（公开仓、公开内容、无运行时服务）。

### 前端应用

| 应用 | 受众 | 覆盖 Feature | 规模 |
|------|------|-------------|------|
| 无（展示归 theuntold 仓） | — | — | — |

### 前端模块组织

无（前端归 theuntold 仓）。

### 组件库依赖

无。

### 异步事件与定时任务

**消息队列**：无。

**定时任务**：增量抓取由 coworkspace OpenClaw cron 触发（调度与脚本不在本仓，见 ADR-001）。

### 数据架构

| 数据库/存储 | 用途 | 访问模块 |
|------------|------|---------|
| `posts/{year}/{month}/*.md` | 中文双语译读归档 | 译读归档、索引维护 |
| `raw/{year}/{month}/*.html` | 原文 HTML 归档 | 抓取/去重 |
| `state/processed.json` | 已处理 URL 去重账本 | 抓取/去重 |
| `index.md` | 全量索引表 | 索引维护 |

**缓存**：无。

### 外部依赖

| 服务 | 用途 | 接入方式 |
|------|------|---------|
| Claude 官方博客（claude.com/blog） | 抓取源 | HTTP 抓取（脚本在 coworkspace） |
