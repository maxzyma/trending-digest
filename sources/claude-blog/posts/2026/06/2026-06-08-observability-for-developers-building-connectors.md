---
source: claude-blog
source_url: https://claude.com/blog/observability-for-developers-building-connectors
published_at: 2026-06-08
category: Product announcements
title_en: Observability for developers building connectors
title_zh: 为构建连接器的开发者提供的可观测性
source_intro_paragraphs: 0
source_image_count: 1
---

# 为构建连接器的开发者提供的可观测性

> 来源：Claude Blog，2026-06-08
> 原文链接：https://claude.com/blog/observability-for-developers-building-connectors
> 分类：Product announcements

## 导语

开发者现在可以跨 Claude 各产品监控自己连接器的性能，并在应用内将连接器提交到目录。

## 核心要点

- 目录中已发布的连接器现在拥有一个仪表盘，展示其在 Claude 各产品界面上的表现。
- 连接器所有者可以追踪采用情况，包括活跃用户、工具调用总数以及目录排名随时间的变化。
- 仪表盘可诊断错误和延迟，提供健康分数、错误率、延迟概览，并按工具细分错误以定位故障。
- 可按产品细分使用情况，比较 Claude、Claude Code、Cowork 等界面上的工具调用。
- 该功能现已开放公开测试版（public beta），位于组织设置（Organization settings）的目录（Directory）下。
- 连接器基于模型上下文协议（Model Context Protocol，MCP）构建，目录中已有超过 300 个第三方连接器。
- 开发者现在可以直接在 Claude 中将自己的 MCP 服务器提交到目录。

## 中文译文

### 监控、调试并改进连接器

目录中已发布的连接器现在拥有一个仪表盘（dashboard），展示它们在 Claude 各产品界面上的表现。连接器所有者可以用它来：

- 追踪采用情况。监控活跃用户、工具调用总数以及目录排名随时间的变化。

- 诊断错误和延迟。一目了然地查看健康分数（health score）、错误率和延迟，并按工具细分错误，以精准定位故障所在。‍

- 按产品细分使用情况。比较 Claude、Claude Code、Cowork 等产品中的工具调用，以了解用户在何处参与互动。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a26eb0505466f798299b38a_MCP%20Observability.png)

今日起以公开测试版（public beta）形式提供。可在 Claude 的组织设置（Organization settings）中的目录（Directory）下找到。需要团队版（Team）或企业版（Enterprise）计划下的管理员（Admin）或所有者（Owner）权限。在企业版上，所有者还可以通过具有目录管理（Directory management）或资料库（Libraries）权限的自定义角色来委派访问权限。

### 加入目录

连接器基于模型上下文协议（Model Context Protocol，MCP）构建。目录中有超过 300 个第三方连接器，每天有数百万人使用。如果你希望将自己的 MCP 服务器提交到目录，现在可以直接在 Claude 中完成。了解更多。

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
