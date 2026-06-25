---
source: claude-blog
source_url: https://claude.com/blog/claude-for-foundation-models
published_at: 2026-06-08
category: Product announcements
title_en: Building intelligent apps for Apple platforms with Claude in the Foundation Models framework
title_zh: 在 Foundation Models 框架中通过 Claude 为 Apple 平台构建智能应用
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 4
source_image_count: 2
---

# 在 Foundation Models 框架中通过 Claude 为 Apple 平台构建智能应用

> ⌁ Building intelligent apps for Apple platforms with Claude in the Foundation Models framework

> 来源：Claude Blog，2026-06-08
> 原文链接：https://claude.com/blog/claude-for-foundation-models
> 分类：Product announcements

## 核心要点

- 新发布的 Swift 软件包让 Apple 开发者可通过 Apple 的 Foundation Models 框架调用 Claude。
- Apple 的 Foundation Models 框架让开发者能原生地从 Swift 访问模型，并通过引导式生成（guided generation）返回带类型的 Swift 值。
- 当请求需要多步推理、代码生成等能力时，开发者可将任务移交给 Claude，Claude 还能联网搜索最新信息并执行代码进行数据分析。
- 由于 Apple 框架通过 `@Generable` 注解返回带类型的 Swift 值，开发者在调用 Claude API 时获得的是干净的输入，而非原始用户文本。
- Claude 扩展了日志、文档、学习等多种已有的设备端智能功能模式。
- 该支持将于明天上线，覆盖 iOS 27、iPadOS 27、macOS 27、visionOS 27 与 watchOS 27。

## 正文

今天，我们通过一个全新的 Swift 软件包发布了对 Claude 的 Foundation Models 框架（Foundation Models framework）支持，让 Apple 开发者能够使用 Apple 的 Foundation Models 框架调用 Claude，以处理更复杂的工作流。

> ⌁ Today we're releasing Foundation Models framework support for Claude through a new Swift package that lets Apple developers use Apple's Foundation Models framework to call Claude for more complex workflows.

今天我们通过一个新的 Swift 包发布对 Claude 的 Foundation Models 框架支持，让苹果开发者能够使用苹果的 Foundation Models 框架调用 Claude，处理更复杂的工作流。

> ⌁ Today we're releasing Foundation Models framework support for Claude through a new Swift package that lets Apple developers use Apple's Foundation Models framework to call Claude for more complex workflows.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a26f71ab79bc169ff9bdec4_8dfc12d1.png)

苹果的 Foundation Models 框架让开发者能够从 Swift 原生地调用模型。它非常易用，最少只需三行代码就能通过引导式生成（guided generation）返回带类型的 Swift 值。开发者可以借此调用苹果的设备端模型，完成摘要或信息提取等快速的本地任务。

> ⌁ Apple’s Foundation Models framework gives developers access to tap into models natively from Swift. It is very easy to use and can return typed Swift values through guided generation in as few as three lines of code. Developers can use this to tap into Apple’s on-device models for fast, local tasks like summarization or extraction.

现在，当请求需要多步推理、代码生成等能力时，开发者可以使用苹果的 Foundation Models 框架将任务移交给 Claude。Claude 还能搜索网络获取最新信息，并执行代码进行数据分析。Claude 的响应可以流式返回到同一个视图中。

> ⌁ Developers can now use Apple’s Foundation Models framework to hand off to Claude when a request calls for multi-step reasoning, code generation, and more. Claude can also search the web for current information and execute code for data analysis. Stream Claude's response back into the same view.

由于苹果的框架会从 @Generable 注解返回带类型的 Swift 值，开发者在调用 Claude API 时拿到的是干净的输入，而不是原始的用户文本。

> ⌁ Because Apple's framework returns typed Swift values from @Generable annotations, developers arrive at the Claude API call with clean inputs instead of raw user text.

### 解锁了什么

> What this unlocks

基础模型框架（Foundation Models framework）已经为一系列智能的设备端功能提供支持——日记应用可以呈现个性化的写作提示，文档应用可以总结合同，学习应用可以按学生的水平解释概念。加入 Claude 让这些模式都得到延伸。

> ⌁ The Foundation Models framework already powers a range of intelligent on-device features — journaling apps that surface personalized prompts, document apps that summarize contracts, learning apps that explain a concept at a student's level. Adding Claude extends each of those patterns.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a26f71ab79bc169ff9bdec1_7c4a5aaf.png)

日记应用可以在设备端生成每日提示，再让 Claude 在数月的记录中找出贯穿其间的线索。学习应用可以在设备端定义一个术语，当学生追问"这为什么对我们讲过的所有内容都重要？"时，再交给 Claude 处理。

> ⌁ A journaling app can generate daily prompts on-device, then ask Claude to find threads across months of entries. A study app can define a term on-device, then hand off to Claude when the student follows up with "why does this matter for everything else we've covered?"

对用户来说这是一段连贯的体验，而每一步背后都由合适的模型支撑。

> ⌁ It's one experience for the user, backed by the right model for each step.

### 开始使用

> Getting started

对 Claude 的支持将于明天通过 Apple 的基础模型框架（Foundation Models framework）提供，可在 iOS 27、iPadOS 27、macOS 27、visionOS 27 和 watchOS 27 上使用。将其添加到你的项目中，用 Anthropic API 密钥登录，并把 Apple 设备端传出的类型化输出传入 Claude 请求——该软件包会负责处理流式传输、工具调用，以及将结构化响应返回到你的 SwiftUI 视图中。

> ⌁ Claude support with the Foundation Models framework will be available tomorrow and works through Apple's Foundation Models framework on iOS 27, iPadOS 27, macOS 27, and visionOS 27, and watch OS 27. Add it to your project, sign in with an Anthropic API key, and pass typed outputs from Apple's on-device pass into a Claude request — the package handles streaming, tool calls, and structured responses back into your SwiftUI view.

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
