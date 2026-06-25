---
source: claude-blog
source_url: https://claude.com/blog/claude-for-foundation-models
published_at: 2026-06-08
category: Product announcements
title_en: Building intelligent apps for Apple platforms with Claude in the Foundation Models framework
title_zh: 在 Foundation Models 框架中借助 Claude 为 Apple 平台构建智能应用
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/7NkDwLng8ZM3voXGiNdPb17LJKMEvZBY"
---

# 在 Foundation Models 框架中借助 Claude 为 Apple 平台构建智能应用

> 来源：Claude Blog，2026-06-08
> 原文链接：https://claude.com/blog/claude-for-foundation-models
> 分类：Product announcements

## 核心要点

- 通过一个新的 Swift 软件包（Swift package），Apple 开发者现在可以在 Apple 的基础模型框架（Foundation Models framework）中调用 Claude，以处理更复杂的工作流。
- Apple 的基础模型框架支持开发者从 Swift 原生调用模型，借助引导式生成（guided generation）最少三行代码即可返回带类型的 Swift 值。
- 设备端（on-device）模型适合摘要、信息提取等快速本地任务；当需要多步推理、代码生成等能力时可移交给 Claude。
- Claude 还可联网搜索最新信息，并执行代码进行数据分析，且响应可以流式返回到同一视图中。
- 由于 Apple 框架通过 `@Generable` 注解返回带类型的 Swift 值，调用 Claude API 时输入是干净的结构化数据，而非原始用户文本。
- 该支持适用于 iOS 27、iPadOS 27、macOS 27、visionOS 27 和 watchOS 27。

## 中文译文

今天，我们通过一个新的 Swift 软件包（Swift package）发布了对 Claude 的基础模型框架（Foundation Models framework）支持，让 Apple 开发者能够使用 Apple 的基础模型框架来调用 Claude，以处理更复杂的工作流。

Apple 的基础模型框架让开发者能够从 Swift 原生地接入模型。它非常易于使用，借助引导式生成（guided generation），最少只需三行代码即可返回带类型的 Swift 值。开发者可以借此接入 Apple 的设备端（on-device）模型，完成摘要或信息提取等快速的本地任务。

现在，当某个请求需要多步推理、代码生成等能力时，开发者可以使用 Apple 的基础模型框架将任务移交给 Claude。Claude 还能联网搜索最新信息，并执行代码进行数据分析。Claude 的响应可以流式返回到同一个视图中。

由于 Apple 的框架会从 `@Generable` 注解返回带类型的 Swift 值，开发者在调用 Claude API 时拿到的是干净的输入，而非原始的用户文本。

## 这能解锁什么

基础模型框架已经在驱动一系列智能的设备端功能——能给出个性化提示的日志应用、能摘要合同的文档应用、能按学生水平讲解概念的学习应用。加入 Claude 进一步扩展了所有这些模式。

一个日志应用可以在设备端生成每日提示，然后让 Claude 在跨越数月的条目中找出线索。一个学习应用可以在设备端定义一个术语，当学生追问"这为什么对我们学过的所有内容都重要？"时再移交给 Claude。

对用户而言这是一个统一的体验，而每一步背后都由最合适的模型支撑。

## 入门

对 Claude 的基础模型框架支持将于明天上线，可通过 Apple 的基础模型框架在 iOS 27、iPadOS 27、macOS 27、visionOS 27 和 watchOS 27 上使用。将其添加到你的项目中，使用 Anthropic API 密钥登录，并将 Apple 设备端处理输出的带类型结果传入一个 Claude 请求——该软件包会处理流式传输、工具调用，以及将结构化响应返回到你的 SwiftUI 视图中。

## 术语对照

| English | 中文 |
|---|---|
| Foundation Models framework | 基础模型框架 |
| Swift package | Swift 软件包 |
| guided generation | 引导式生成 |
| typed Swift values | 带类型的 Swift 值 |
| on-device | 设备端 |
| multi-step reasoning | 多步推理 |
| code generation | 代码生成 |
| streaming | 流式传输 |
| tool calls | 工具调用 |
| structured responses | 结构化响应 |
| Anthropic API key | Anthropic API 密钥 |
