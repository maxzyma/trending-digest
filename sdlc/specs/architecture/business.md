# 业务架构

<!-- 回答：业务端到端怎么运转、有哪些跨功能的铁律 -->

## 角色

| 角色 | 职责 | 涉及 Feature |
|------|------|-------------|
| 调度器（coworkspace cron） | 定时触发增量抓取流水线 | claude-blog-ingestion |
| 抓取/译读流水线（coworkspace 脚本） | 抓原文 → 生成中文译读 → 写归档 → 更新索引/state | 全部 |
| 中文技术读者 | 消费归档的中文译读 | bilingual-digest-format |
| 下游站点 theuntold | 渲染归档 markdown 为公开站点 | archive-index-maintenance |

## 端到端业务流程

### 增量译读归档流程

```
[cron:定时触发] → [流水线:拉源站文章列表] → {URL 已在 processed.json？}
                                                  │
                                    ┌─────────────┴─────────────┐
                                  是（跳过）                   否（处理）
                                                                │
                          [流水线:抓 raw HTML → 生成中文双语译读 markdown]
                                                                │
                          [写 posts/{year}/{month}/ + raw/{year}/{month}/]
                                                                │
                          [更新 index.md 索引表 + state/processed.json]
```

## 跨功能业务约束

<!-- 跨 Feature 的业务铁律，单 Feature 内的约束在各自 behaviors 中 -->

| 约束 | 涉及 Feature | 违反后果 |
|------|-------------|---------|
| 已记录在 processed.json 的 URL 不重复抓取/归档 | claude-blog-ingestion, archive-index-maintenance | 重复归档、索引重复行 |
| 只归档公开可访问内容 | 全部 | 合规风险，公开仓泄露受限内容 |
| index.md 行与 posts/ 实际文件、processed.json 条目三者一致 | archive-index-maintenance | 索引指向失效链接 |
