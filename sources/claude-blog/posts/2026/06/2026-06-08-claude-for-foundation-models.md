---
source: claude-blog
source_url: https://claude.com/blog/claude-for-foundation-models
published_at: 2026-06-08
category: Product announcements
title_en: Building intelligent apps for Apple platforms with Claude in the Foundation Models framework
title_zh: 在 Foundation Models 框架中通过 Claude 为 Apple 平台构建智能应用
source_intro_paragraphs: 4
source_image_count: 2
---

# 在 Foundation Models 框架中通过 Claude 为 Apple 平台构建智能应用

> 来源：Claude Blog，2026-06-08
> 原文链接：https://claude.com/blog/claude-for-foundation-models
> 分类：Product announcements

## 导语

今天，我们通过一个全新的 Swift 软件包发布了对 Claude 的 Foundation Models 框架（Foundation Models framework）支持，让 Apple 开发者能够使用 Apple 的 Foundation Models 框架调用 Claude，以处理更复杂的工作流。

## 核心要点

- 新发布的 Swift 软件包让 Apple 开发者可通过 Apple 的 Foundation Models 框架调用 Claude。
- Apple 的 Foundation Models 框架让开发者能原生地从 Swift 访问模型，并通过引导式生成（guided generation）返回带类型的 Swift 值。
- 当请求需要多步推理、代码生成等能力时，开发者可将任务移交给 Claude，Claude 还能联网搜索最新信息并执行代码进行数据分析。
- 由于 Apple 框架通过 `@Generable` 注解返回带类型的 Swift 值，开发者在调用 Claude API 时获得的是干净的输入，而非原始用户文本。
- Claude 扩展了日志、文档、学习等多种已有的设备端智能功能模式。
- 该支持将于明天上线，覆盖 iOS 27、iPadOS 27、macOS 27、visionOS 27 与 watchOS 27。

## 中文译文

今天，我们通过一个全新的 Swift 软件包发布了对 Claude 的 Foundation Models 框架支持，让 Apple 开发者能够使用 Apple 的 Foundation Models 框架调用 Claude，以处理更复杂的工作流。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a26f71ab79bc169ff9bdec4_8dfc12d1.png)

Apple 的 Foundation Models 框架让开发者能够原生地从 Swift 访问模型。它非常易于使用，最少只需三行代码即可通过引导式生成（guided generation）返回带类型的 Swift 值。开发者可以借此调用 Apple 的设备端（on-device）模型，完成诸如摘要或提取等快速、本地的任务。

现在，当某个请求需要多步推理、代码生成等能力时，开发者可以使用 Apple 的 Foundation Models 框架将任务移交给 Claude。Claude 还能联网搜索最新信息，并执行代码进行数据分析。Claude 的响应可以流式回传到同一个视图中。

由于 Apple 的框架会从 `@Generable` 注解返回带类型的 Swift 值，开发者在抵达 Claude API 调用时得到的是干净的输入，而不是原始的用户文本。

### 这带来了什么

Foundation Models 框架已经驱动了一系列智能的设备端功能——会浮现个性化提示的日志应用、会总结合同的文档应用、会按学生水平讲解概念的学习应用。加入 Claude 扩展了上述每一种模式。

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a26f71ab79bc169ff9bdec1_7c4a5aaf.png)

一个日志应用可以在设备端生成每日提示，然后请 Claude 在数月的条目中找出贯穿其间的线索。一个学习应用可以在设备端给出术语定义，然后在学生追问"这为什么对我们讲过的所有内容都重要？"时移交给 Claude。

对用户而言这是一种连贯的体验，背后则由最适合每一步的模型来支撑。

### 开始使用

Claude 与 Foundation Models 框架的支持将于明天上线，通过 Apple 的 Foundation Models 框架在 iOS 27、iPadOS 27、macOS 27、visionOS 27 以及 watchOS 27 上运行。将其添加到你的项目中，使用 Anthropic API 密钥登录，并把来自 Apple 设备端处理的带类型输出传入一个 Claude 请求——该软件包会处理流式传输、工具调用，以及将结构化响应回传到你的 SwiftUI 视图。

## 术语对照

| English | 中文 |
|---|---|
| Foundation Models framework | Foundation Models 框架 |
| Swift package | Swift 软件包 |
| guided generation | 引导式生成 |
| typed Swift values | 带类型的 Swift 值 |
| on-device | 设备端 |
| multi-step reasoning | 多步推理 |
| code generation | 代码生成 |
| tool calls | 工具调用 |
| structured responses | 结构化响应 |
| streaming | 流式传输 |
