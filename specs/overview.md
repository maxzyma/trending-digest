# 产品与系统总览

## 定位

为中文技术读者，把分散的公开技术资源（Claude 官方博客、演讲/访谈等）归档为中文双语译读的 markdown 库，并通过 `trending.theuntold.ai` 单一入口提供带索引的公开阅读站。

| 用户 | 痛点 | 期望成果 |
|------|------|---------|
| 中文技术读者 | 外文更新分散、阅读慢、易漏 | 增量及时的中文译读，一处可检索 |
| 下游消费方（站点/钉钉文档） | 需要结构化可引用的内容源 | 稳定的 markdown 归档 + index |

## 职责边界

**本仓拥有**

- `sources/<source>/posts/` 中文双语译读产物、`manifest.json`（来源与产物 lineage）
- Jekyll 门户与同仓小源子站（claude-blog、talks）、站点校验脚本
- `trending.theuntold.ai` 的自定义域与门户首页

**本仓不含**

- 抓取、翻译、调度实现与凭据 —— 归私有编排层
- 重试/死信/游标等运行状态、钉钉目录与通知路由
- github-trending 站内容（独立仓，经 CF Worker 反代挂入 `/github-trending/`）
- CF Worker 运行时代码（归 theuntold 仓，路由算法契约见 [portal/algorithms.md](portal/algorithms.md)）

**原文快照**：`raw/`（源站 HTML、YouTube 字幕等）随归档一并公开保存。它不参与站点渲染，也没有仓外消费方——归档 metadata 不记录它，增量去重与跨源聚类都不读它。

## 技术栈

无运行时服务、无数据库。产物即 markdown + JSON 文件，按 `年/月` 组织，经 GitHub Pages 构建发布；跨仓聚合在 CF Worker 边缘完成。

## 内容模型

```
Source ──1:N──→ Post ──1:1──→ RawDocument
   │                │
   │                └──1:1──→ IndexEntry
   └──1:1──→ ProcessedState（URL 去重账本，兼容期）
```

| 概念 | 定义 |
|------|------|
| Source | 内容来源（claude-blog 自动流水线；talks 手动来源） |
| RawDocument | 原文快照（HTML / 字幕），默认不公开 |
| Post | 一篇文章的中文双语译读 markdown |
| IndexEntry | 索引中指向某 Post 的一行 |
| ProcessedState | `processed.json` 中某 URL 已处理的去重条目（旧 claude-blog 脚本过渡用） |

## 跨功能不变量

| ID | 不变量 | 违反后果 |
|----|--------|---------|
| CI-001 | 一个 Source URL 至多对应一个 Post 与一条 ProcessedState | 重复归档、索引重复行 |
| CI-002 | 索引每行必对应实际存在的 Post 文件 | 索引指向失效链接 |
| CI-003 | 只归档公开可访问内容，公开仓不含凭据或受限内容 | 合规风险 |
| CI-004 | 重复运行流水线不产生重复产物（增量幂等） | 产物污染 |

门户自身的不变量（baseurl、构建期依赖、301 范围）见 [portal/README.md](portal/README.md)。

## 质量底线

| 维度 | 要求 | 验收方式 |
|------|------|---------|
| 合规 | 仅公开可访问内容，无凭据 | 提交前内容审查 |
| 数据一致 | 索引 ↔ posts 文件 ↔ processed.json 三方一致 | `scripts/validate-site.rb` |
| 构建 | 配置或字段错误时非零退出、不产残缺站（fail-loud） | `scripts/verify-build.sh` |
| 下游兼容 | markdown 对站点与钉钉文档可解析 | 下游渲染验证 |
| 可观测 | 调度成功/失败/无新增均有通知 | 私有编排层 |

## 生产者契约

通用处理引擎输出 canonical package，本仓 archive adapter 负责 front matter、目录、索引、manifest 与构建校验。完整契约见 [../docs/producer-contract.md](../docs/producer-contract.md)。
