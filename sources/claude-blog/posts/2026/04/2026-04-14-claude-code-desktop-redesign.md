---
source: claude-blog
source_url: https://claude.com/blog/claude-code-desktop-redesign
published_at: 2026-04-14
category: Claude Code
title_en: Redesigning Claude Code on desktop for parallel agents
title_zh: 为并行智能体重新设计桌面端 Claude Code
source_intro_paragraphs: 1
source_image_count: 0
---

# 为并行智能体重新设计桌面端 Claude Code

> 来源：Claude Blog，2026-04-14
> 原文链接：https://claude.com/blog/claude-code-desktop-redesign
> 分类：Claude Code

## 导语

今天，我们发布了 Claude Code 桌面应用的重新设计版本，旨在帮助你同时运行更多 Claude Code 任务。

## 核心要点

- 全新侧边栏统一管理多个活动中和近期的会话，可按状态、项目或环境筛选。
- 拖放式布局可自由排布终端、预览、差异查看器和聊天面板。
- 集成终端（terminal）与应用内文件编辑器，让你无需离开应用即可审阅、修改并交付。
- 桌面应用现已与 CLI 插件功能对齐，SSH 支持扩展到 Mac。
- 提供 Verbose、Normal、Summary 三种视图模式，并新增快捷键与用量查看按钮。
- 底层重建以提升可靠性与速度，并支持流式输出响应。

## 中文译文

它包含一个用于管理多个会话的全新侧边栏、一个用于排布工作区的拖放式布局、一个集成的终端和文件编辑器，以及性能和使用体验上的改进。

### 全新的桌面端体验

对许多开发者而言，智能体式（agentic）工作的形态已经改变。你不再是输入一条提示词然后等待。你会在一个代码仓库里启动一次重构，在另一个仓库里修复一个 bug，又在第三个仓库里跑一遍写测试的流程，随着结果陆续到来逐个查看，在出现偏差时进行引导，并在交付前审阅差异（diff）。

新应用专为如今智能体式编码真正的体感而打造：多项任务并行推进，而你坐在编排者（orchestrator）的位置上。

### 并行运行会话

全新的侧边栏将每一个活动中和近期的会话集中到一处。在多个代码仓库间启动工作，并随结果到来在它们之间切换。

你可以按状态、项目或环境筛选，也可以将侧边栏按项目分组，从而更快地查找和恢复会话。当某个会话的 PR 被合并或关闭时，它会自动归档，让侧边栏始终聚焦于正在进行的工作。

当你需要在任务进行中提问时，可以打开一个侧边聊天（side chat）（⌘ + ; 或 Ctrl + ;）来从一段对话中分出支线。侧边聊天会从主线程中提取上下文，但不会向主线程添加任何内容，以避免误导你的任务。

### 无需离开应用即可审阅与交付

此次重新设计将更多常用工具引入应用，让你无需切换到编辑器即可审阅、调整并交付 Claude 的工作成果：

- 集成终端（Integrated terminal）：在会话旁运行测试或构建。

- 应用内文件编辑器（In-app file editor）：打开文件，直接做局部编辑并保存更改。

- 更快的差异查看器（Faster diff viewer）：为大型变更集的性能而重建。

- 扩展的预览（Expanded preview）：除了在预览窗格运行本地应用服务器外，还可在应用内打开 HTML 文件或 PDF。

每一个面板都支持拖放。可按你的工作方式，把终端、预览、差异查看器和聊天排布成任意网格。

### 适配你的技术栈

桌面应用现已与 CLI 插件功能对齐。如果你的组织集中管理 Claude Code 插件，或你在本地安装了自己的插件，它们在桌面应用中的运作方式与在终端中完全一致。

你仍可在本地或云端运行会话。SSH 支持现已在 Linux 之外扩展到 Mac，因此你可以从任一平台将会话指向远程机器。

### 按你的工作方式定制

三种视图模式——Verbose（详尽）、Normal（普通）和 Summary（摘要）——让你把界面从对 Claude 工具调用的完全透明，调节到只显示结果。新的键盘快捷键涵盖会话切换、生成和导航；按 ⌘ + /（或 Ctrl + /）可查看完整列表。新的用量按钮可让你一眼看到上下文窗口（context window）和会话用量。

在底层，应用已为可靠性和速度而重建，现在会在 Claude 生成响应的同时进行流式输出。

### 开始使用

重新设计的桌面应用现已面向所有使用 Pro、Max、Team 和 Enterprise 计划的 Claude Code 用户，以及通过 Claude API 的用户开放。

下载应用，或如果你已安装则更新并重启。浏览文档以了解更多。

## 术语对照

| English | 中文 |
|---|---|
| Claude Code | Claude Code |
| desktop app | 桌面应用 |
| parallel agents | 并行智能体 |
| sidebar | 侧边栏 |
| session | 会话 |
| drag-and-drop | 拖放 |
| terminal | 终端 |
| file editor | 文件编辑器 |
| diff / diff viewer | 差异 / 差异查看器 |
| agentic | 智能体式 |
| orchestrator | 编排者 |
| PR | PR（拉取请求） |
| side chat | 侧边聊天 |
| preview pane | 预览窗格 |
| CLI plugins | CLI 插件 |
| SSH | SSH |
| context window | 上下文窗口 |
| Verbose / Normal / Summary | 详尽 / 普通 / 摘要 |
