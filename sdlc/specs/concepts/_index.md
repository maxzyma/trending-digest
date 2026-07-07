# 业务概念地图

## 关系概览

```
Source ──1:N──→ Post ──1:1──→ RawDocument
   │                │
   │                └──1:1──→ IndexEntry
   └──1:1──→ ProcessedState（URL 去重账本）
```

## 核心业务流程

### 增量译读归档（主链路）
Source → （ProcessedState 去重判定）→ RawDocument → Post → IndexEntry

## 级联影响矩阵

> 遍历各概念转换对其他概念的影响。

| 源转换 | 受影响概念 | 影响方式 | 依据 |
|--------|-----------|---------|------|
| Post 删除 | IndexEntry, ProcessedState | index 行需移除；processed 条目需回退否则永不重抓 | 待 Feature 落地确认 |

## 跨概念不变量

> 涉及多个概念的铁律，统一编号 CI-NNN。

| ID | 不变量 | 涉及概念 | 保证机制 | 依据 |
|----|--------|---------|---------|------|
| CI-001 | 一个 Source URL 至多对应一个 Post 与一条 ProcessedState | Source · Post · ProcessedState | processed.json 去重 | 待 Feature 落地确认 |
| CI-002 | index.md 每行必对应一个实际存在的 Post 文件 | IndexEntry · Post | 索引维护一致性校验 | 待 Feature 落地确认 |

> 一致性检查：未发现跨概念不变量冲突（检查范围：当前 2 条 CI）。

## 概念索引

| 概念 | 一句话定义 |
|------|-----------|
| Source | 内容来源（当前实现：Claude 官方博客），多源架构的可扩展维度 |
| RawDocument | 抓取的原文 HTML 归档（`raw/{year}/{month}/*.html`） |
| Post | 一篇文章的中文双语译读 markdown（`posts/{year}/{month}/*.md`） |
| IndexEntry | index.md 中指向某 Post 的一行索引（日期/标题/分类/链接） |
| ProcessedState | `processed.json` 中记录某 URL 已处理的去重条目 |
