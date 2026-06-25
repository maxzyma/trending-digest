---
source: claude-blog
source_url: https://claude.com/blog/observability-for-developers-building-connectors
published_at: 2026-06-08
category: Product announcements
title_en: Observability for developers building connectors
title_zh: 为构建连接器的开发者提供可观测性
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/ZX6GRezwJl7D0RwpIg3OPMPXVdqbropQ"
---

# 为构建连接器的开发者提供可观测性

> 来源：Claude Blog，2026-06-08
> 原文链接：https://claude.com/blog/observability-for-developers-building-connectors
> 分类：Product announcements

## 核心要点

- 目录中已发布的连接器（connector）现在拥有一个仪表盘，用于展示其在各 Claude 产品界面上的表现。
- 仪表盘可追踪采用情况，包括活跃用户数、工具调用总数以及目录排名随时间的变化。
- 可诊断错误与延迟，提供健康评分、错误率、延迟概览，以及按工具划分的错误明细。
- 可按产品拆分使用情况，比较 Claude、Claude Code、Cowork 等界面中的工具调用。
- 该功能现已开放公测，需在 Team 或 Enterprise 计划下拥有管理员（Admin）或所有者（Owner）权限。
- 连接器基于模型上下文协议（Model Context Protocol，MCP）构建，目录中已有 300 多个第三方连接器；现在可直接在 Claude 中提交 MCP 服务器加入目录。

## 中文译文

## 监控、调试并改进连接器

目录中已发布的连接器现在拥有一个仪表盘，展示它们在各 Claude 产品界面上的表现。连接器所有者可以用它来：

- 追踪采用情况。监控活跃用户数、工具调用总数以及目录排名随时间的变化。

- 诊断错误与延迟。一目了然地查看健康评分、错误率和延迟，并通过按工具划分的错误明细来精确定位故障所在。

- 按产品拆分使用情况。比较 Claude、Claude Code、Cowork 等界面中的工具调用，以了解用户在何处进行交互。

该功能即日起以公测（public beta）形式提供。可在 Claude 的「组织设置（Organization settings）」中的「目录（Directory）」下找到它。需要在 Team 或 Enterprise 计划下拥有管理员（Admin）或所有者（Owner）权限。在 Enterprise 计划上，所有者还可以通过具备「目录管理（Directory management）」或「库（Libraries）」权限的自定义角色来委派访问权。

## 加入目录

连接器基于模型上下文协议（Model Context Protocol，MCP）构建。目录中已有 300 多个第三方连接器，每天被数百万人使用。如果你希望将自己的 MCP 服务器提交至目录，现在可以直接在 Claude 中进行。了解更多。

## 术语对照

| English | 中文 |
|---|---|
| connector | 连接器 |
| dashboard | 仪表盘 |
| observability | 可观测性 |
| tool call | 工具调用 |
| health score | 健康评分 |
| error rate | 错误率 |
| latency | 延迟 |
| directory | 目录 |
| public beta | 公测 |
| Model Context Protocol (MCP) | 模型上下文协议 |
| MCP server | MCP 服务器 |
| Admin | 管理员 |
| Owner | 所有者 |
