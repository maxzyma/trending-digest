---
source: claude-blog
source_url: https://claude.com/blog/claude-code-desktop-redesign
published_at: 2026-04-14
category: Claude Code
title_en: Redesigning Claude Code on desktop for parallel agents
title_zh: 为并行智能体重新设计桌面端 Claude Code
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 1
source_image_count: 0
---

# 为并行智能体重新设计桌面端 Claude Code

> 🌏︎ • Redesigning Claude Code on desktop for parallel agents

> • 来源：Claude Blog，2026-04-14
> • 原文链接：https://claude.com/blog/claude-code-desktop-redesign
> • 分类：Claude Code

## 核心要点

- 全新侧边栏统一管理多个活动中和近期的会话，可按状态、项目或环境筛选。
- 拖放式布局可自由排布终端、预览、差异查看器和聊天面板。
- 集成终端（terminal）与应用内文件编辑器，让你无需离开应用即可审阅、修改并交付。
- 桌面应用现已与 CLI 插件功能对齐，SSH 支持扩展到 Mac。
- 提供 Verbose、Normal、Summary 三种视图模式，并新增快捷键与用量查看按钮。
- 底层重建以提升可靠性与速度，并支持流式输出响应。

## 正文

今天，我们发布了 Claude Code 桌面应用的重新设计版本，旨在帮助你同时运行更多 Claude Code 任务。

> 🌏︎ Today, we're releasing a redesign of the Claude Code desktop app, built to help you run more Claude Code tasks at once.

它包含一个用于管理多个会话的新侧边栏、一个用于布置工作区的拖放式布局、一个集成的终端和文件编辑器，以及性能和体验方面的改进。

> 🌏︎ It includes a new sidebar for managing multiple sessions, a drag-and-drop layout for arranging your workspace, an integrated terminal and file editor, plus performance and quality-of-life improvements.

### 全新的桌面端体验

> The new desktop experience

对许多开发者来说，智能体式工作（agentic work）的形态已经改变。你不再是输入一条提示词然后等待。你会在一个代码仓库里启动重构，在另一个仓库里修复缺陷，又在第三个仓库里跑一遍编写测试的工作，随着结果陆续返回逐个查看，在某项任务跑偏时加以引导，并在交付前审查代码差异（diff）。

> 🌏︎ For many developers, the shape of agentic work has changed. You're not typing one prompt and waiting. You're kicking off a refactor in one repo, a bug fix in another, and a test-writing pass in a third, checking on each as results come in, steering when something drifts, and reviewing diffs before you ship.

新版应用正是为如今智能体式编程的真实感受而打造：多项任务同时进行，而你坐在编排者（orchestrator）的位置上。

> 🌏︎ The new app is built for how agentic coding actually feels now: many things in flight, and you in the orchestrator seat.

### 并行运行会话

> Run sessions in parallel

新的侧边栏把每个活跃会话和近期会话集中到一处。你可以跨多个代码仓库启动工作，并在结果陆续返回时在它们之间切换。

> 🌏︎ The new sidebar puts every active and recent session in one place. Kick off work across multiple repos and move between them as results arrive.

你可以按状态、项目或环境筛选，也可以把侧边栏按项目分组，从而更快找到并恢复会话。当某个会话的 PR 合并或关闭后，它会自动归档，让侧边栏始终聚焦于正在进行的工作。

> 🌏︎ You can filter by status, project, or environment, or group the sidebar by project to find and resume sessions faster. When a session's PR merges or closes, it archives itself so the sidebar stays focused on what's live.

当你需要在任务进行中提问时，可以打开侧聊（⌘ + ; 或 Ctrl + ;）从当前对话分支出去。侧聊会从主线程拉取上下文，但不会把任何内容加回主线程，以免干扰你的任务方向。

> 🌏︎ When you need to ask a question mid-task, you can open a side chat (⌘ + ; or Ctrl + ;) to branch off a conversation. Side chats pull context from the main thread, but don’t add anything back to the thread, to avoid misdirecting your tasks.

### 无需离开应用即可审阅与发布

> Review and ship without leaving the app

此次重新设计将更多常用工具集成进应用，让你无需切换到编辑器就能审阅、调整并发布 Claude 完成的工作：

> 🌏︎ The redesign brings more commonly-used tools into the app, so you can review, tweak, and ship Claude's work without bouncing to your editor:

- 集成终端（terminal）：在会话旁边直接运行测试或构建。
- 应用内文件编辑器：打开文件、直接进行局部修改并保存更改。
- 更快的差异查看器（diff viewer）：针对大型变更集重建，性能更优。
- 扩展的预览功能：除了在预览窗格中运行本地应用服务器外，还可在应用内打开 HTML 文件或 PDF。

> 🌏︎ • Integrated terminal : Run tests or builds alongside your session.

> • In-app file editor : Open files, make spot edits directly, and save changes.

> • Faster diff viewer : Rebuilt for performance on large changesets.

> • Expanded preview : Open HTML files or PDFs in-app, in addition to running local app servers in the preview pane.

每个窗格都支持拖放。你可以按照自己的工作方式，将终端、预览、差异查看器和聊天排布成任意网格布局。

> 🌏︎ Every pane is drag-and-drop. Arrange the terminal, preview, diff viewer, and chat in whatever grid matches how you work.

### 适合你的技术栈

> Fits your stack

桌面应用现已与命令行（CLI）插件功能对齐。如果你的组织集中管理 Claude Code 插件，或者你在本地安装了自己的插件，它们在桌面应用中的运行方式与在终端中完全一致。

> 🌏︎ The desktop app now has parity with CLI plugins. If your org manages Claude Code plugins centrally, or you've installed your own locally, they work in the desktop app exactly the way they do in your terminal.

你仍然可以在本地或云端运行会话。SSH 支持现已从 Linux 扩展到 Mac，因此你可以在两个平台上将会话指向远程机器。

> 🌏︎ You can still run sessions locally or in the cloud. SSH support now extends to Mac alongside Linux, so you can point sessions at remote machines from either platform.

### 为你的工作方式定制

> Customize for how you work

三种视图模式——详细（Verbose）、普通（Normal）和摘要（Summary）——让你把界面从完整展示 Claude 的工具调用，调到只看结果。新的键盘快捷键涵盖会话切换、新建和导航；按 ⌘ + /（或 Ctrl + /）可查看完整列表。新增的用量按钮让你一眼看清上下文窗口和会话用量。

> 🌏︎ Three view modes—Verbose, Normal, and Summary—let you dial the interface from full transparency into Claude's tool calls to just the results. New keyboard shortcuts cover session switching, spawning, and navigation; press ⌘ + / (or Ctrl + / ) to see the full list. A new usage button shows both your context window and session usage at a glance.

在底层，应用已为可靠性和速度重新构建，现在会在 Claude 生成内容时实时流式输出响应。

> 🌏︎ Under the hood, the app has been rebuilt for reliability and speed, and now streams responses as Claude generates them.

### 开始使用

> Getting started

这款重新设计的桌面应用现已面向所有使用 Pro、Max、Team 和 Enterprise 套餐的 Claude Code 用户开放，也可通过 Claude API 使用。

> 🌏︎ The redesigned desktop app is available now for all Claude Code users on Pro, Max, Team, and Enterprise plans, and via the Claude API.

下载该应用，如果你已经安装，则更新并重启。查阅文档以了解更多。

> 🌏︎ Download the app , or update and restart if you already have it. Explore the documentation to learn more.

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
