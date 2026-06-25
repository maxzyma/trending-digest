---
source: claude-blog
source_url: https://claude.com/blog/claude-code-desktop-redesign
published_at: 2026-04-14
category: Claude Code
title_en: Redesigning Claude Code on desktop for parallel agents
title_zh: 为并行智能体重新设计桌面端 Claude Code
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/G1DKw2zgV2RXmzDdUqY0zAgjVB5r9YAn"
---

# 为并行智能体重新设计桌面端 Claude Code

> 来源：Claude Blog，2026-04-14
> 原文链接：https://claude.com/blog/claude-code-desktop-redesign
> 分类：Claude Code

## 核心要点

- 新版桌面应用新增侧边栏，用于集中管理多个会话，可按状态、项目或环境筛选与分组。
- 支持拖放（drag-and-drop）布局，可自由排布终端、预览、差异查看器与聊天面板。
- 集成了内置终端、应用内文件编辑器、更快的差异查看器以及扩展的预览能力。
- 桌面应用现已与命令行插件（CLI plugins）功能对齐，本地或集中管理的插件均可使用。
- 会话既可本地运行也可在云端运行，SSH 支持现已扩展至 Mac。
- 提供详尽（Verbose）、普通（Normal）、摘要（Summary）三种视图模式，并新增快捷键与用量按钮。

## 中文译文

新版应用包含用于管理多个会话的新侧边栏、用于排布工作区的拖放布局、集成的终端与文件编辑器，以及性能与使用体验上的改进。

## 全新的桌面端体验

对许多开发者而言，智能体式工作（agentic work）的形态已经改变。你不再是输入一条提示词然后等待。你会在一个代码仓库中启动重构，在另一个仓库中修复缺陷，在第三个仓库中跑一轮测试编写，随着结果陆续返回逐一查看，在出现偏差时进行引导，并在交付前审查差异。

新版应用正是为当下智能体式编码的真实感受而打造：多项任务同时进行，而你坐在编排者（orchestrator）的位置上。

## 并行运行多个会话

新的侧边栏把每一个活跃和近期的会话集中在一处。你可以在多个仓库中启动工作，并在结果到来时在它们之间切换。

你可以按状态、项目或环境进行筛选，或将侧边栏按项目分组，以更快地查找和恢复会话。当某个会话对应的 PR 被合并或关闭时，它会自动归档，使侧边栏始终聚焦于正在进行的工作。

当你需要在任务进行中提问时，可以打开侧边聊天（side chat）（⌘ + ; 或 Ctrl + ;）来从一段对话中分叉出去。侧边聊天会从主线程中拉取上下文，但不会向主线程添加任何内容，以避免误导你的任务。

## 无需离开应用即可审查与交付

此次重新设计将更多常用工具引入应用之中，使你可以审查、调整并交付 Claude 的工作成果，而无需切换到你的编辑器：

- 集成终端：在会话旁运行测试或构建。

- 应用内文件编辑器：打开文件，直接进行局部编辑并保存更改。

- 更快的差异查看器：针对大型变更集的性能进行了重建。

- 扩展的预览：除了在预览窗格中运行本地应用服务器外，还可在应用内打开 HTML 文件或 PDF。

每个窗格都支持拖放。你可以按照适合自己工作方式的任意网格来排布终端、预览、差异查看器和聊天。

## 契合你的技术栈

桌面应用现已与命令行插件（CLI plugins）功能对齐。如果你的组织集中管理 Claude Code 插件，或者你在本地安装了自己的插件，它们在桌面应用中的运行方式与在终端中完全一致。

你仍然可以在本地或云端运行会话。SSH 支持现在除 Linux 外也扩展到了 Mac，因此你可以在任一平台上将会话指向远程机器。

## 按你的工作方式自定义

详尽（Verbose）、普通（Normal）和摘要（Summary）三种视图模式，让你可以将界面从完整呈现 Claude 的工具调用，调节为只显示结果。新的键盘快捷键涵盖会话切换、新建和导航；按下 ⌘ + /（或 Ctrl + /）即可查看完整列表。新增的用量按钮可让你一目了然地查看上下文窗口和会话用量。

在底层，应用已为可靠性和速度进行了重建，现在会在 Claude 生成响应时进行流式输出。

## 开始使用

重新设计的桌面应用现已面向所有使用 Pro、Max、Team 和 Enterprise 套餐的 Claude Code 用户开放，并可通过 Claude API 使用。

下载该应用，如果你已安装则更新并重启。浏览文档以了解更多。

## 术语对照

| English | 中文 |
|---|---|
| parallel agents | 并行智能体 |
| agentic work / agentic coding | 智能体式工作 / 智能体式编码 |
| sidebar | 侧边栏 |
| drag-and-drop | 拖放 |
| orchestrator | 编排者 |
| session | 会话 |
| side chat | 侧边聊天 |
| PR (pull request) | PR |
| integrated terminal | 集成终端 |
| in-app file editor | 应用内文件编辑器 |
| diff viewer | 差异查看器 |
| changeset | 变更集 |
| preview pane | 预览窗格 |
| CLI plugins | 命令行插件 |
| SSH | SSH |
| view modes (Verbose / Normal / Summary) | 视图模式（详尽 / 普通 / 摘要） |
| context window | 上下文窗口 |
| streams responses | 流式输出响应 |
