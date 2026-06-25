---
source: claude-blog
source_url: https://claude.com/blog/observability-for-developers-building-connectors
published_at: 2026-06-08
category: Product announcements
title_en: Observability for developers building connectors
title_zh: 为构建连接器的开发者提供的可观测性
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 0
source_image_count: 1
---

# 为构建连接器的开发者提供的可观测性

> ⌁ Observability for developers building connectors

> 来源：Claude Blog，2026-06-08
> 原文链接：https://claude.com/blog/observability-for-developers-building-connectors
> 分类：Product announcements

## 核心要点

- 目录中已发布的连接器现在拥有一个仪表盘，展示其在 Claude 各产品界面上的表现。
- 连接器所有者可以追踪采用情况，包括活跃用户、工具调用总数以及目录排名随时间的变化。
- 仪表盘可诊断错误和延迟，提供健康分数、错误率、延迟概览，并按工具细分错误以定位故障。
- 可按产品细分使用情况，比较 Claude、Claude Code、Cowork 等界面上的工具调用。
- 该功能现已开放公开测试版（public beta），位于组织设置（Organization settings）的目录（Directory）下。
- 连接器基于模型上下文协议（Model Context Protocol，MCP）构建，目录中已有超过 300 个第三方连接器。
- 开发者现在可以直接在 Claude 中将自己的 MCP 服务器提交到目录。

## 正文

开发者现在可以跨 Claude 各产品监控自己连接器的性能，并在应用内将连接器提交到目录。

> ⌁ Developers can now monitor their connectors' performance across Claude products and submit connectors to the directory in-app.

### 监测、调试并改进连接器

> Monitor, debug, and improve connectors

目录中已发布的连接器现在配有仪表盘，展示它们在各个 Claude 产品界面上的表现。连接器所有者可以用它来：

> ⌁ Published connectors in the directory now have a dashboard showing how they’re performing across Claude product surfaces. Connector owners can use it to:

- 跟踪采用情况。监测活跃用户、工具调用总数，以及目录排名随时间的变化。
- 诊断错误与延迟。一眼查看健康评分、错误率和延迟，并按工具细分错误，精准定位故障所在。
- 按产品细分使用情况。对比工具调用在 Claude、Claude Code、Cowork 等产品中的分布，了解用户在哪里参与互动。

> ⌁ - Track adoption. Monitor active users, total tool calls, and directory rank over time.
> - Diagnose errors and latency. See health score, error rates, and latency at a glance, with per-tool error breakdowns to pinpoint what's failing. ‍
> - Break down usage by product. Compare tool calls across Claude, Claude Code, Cowork, and more to understand where users are engaging.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a26eb0505466f798299b38a_MCP%20Observability.png)

今日起以公开测试版（public beta）形式提供。在 Claude 中的「组织设置」（Organization settings）下的「目录」（Directory）里即可找到。需要团队版（Team）或企业版（Enterprise）的管理员（Admin）或所有者（Owner）权限。在企业版中，所有者还可以通过具备「目录管理」（Directory management）或「库」（Libraries）权限的自定义角色来委派访问权限。

> ⌁ Available today in public beta. Find it in Claude under Directory in Organization settings . Requires Admin or Owner access on a Team or Enterprise plan. On Enterprise, Owners can also delegate access with a custom role that has the Directory management or Libraries permission.

### 加入目录

> Joining the directory

连接器（Connectors）基于模型上下文协议（Model Context Protocol，MCP）构建。目录中已有超过 300 个第三方连接器，每天有数百万人使用。如果你希望将自己的 MCP 服务器提交到目录中，现在可以直接在 Claude 中完成。了解更多。

> ⌁ Connectors are built on the Model Context Protocol (MCP) . There are over 300 third-party connectors in the directory , used by millions of people every day. If you wish to submit your MCP server to the directory, you can now do so directly in Claude. Learn more .

## 术语对照

| English | 中文 |
|---|---|
| connector | 连接器 |
| dashboard | 仪表盘 |
| directory | 目录 |
| product surface | 产品界面 |
| adoption | 采用情况 |
| tool calls | 工具调用 |
| directory rank | 目录排名 |
| health score | 健康分数 |
| error rate | 错误率 |
| latency | 延迟 |
| public beta | 公开测试版 |
| Organization settings | 组织设置 |
| Admin | 管理员 |
| Owner | 所有者 |
| Team plan | 团队版计划 |
| Enterprise plan | 企业版计划 |
| custom role | 自定义角色 |
| Libraries permission | 资料库权限 |
| Model Context Protocol (MCP) | 模型上下文协议 |
| MCP server | MCP 服务器 |
