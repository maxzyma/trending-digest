---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents-memory
published_at: 2026-04-23
category: Agents
title_en: Built-in memory for Claude Managed Agents
title_zh: Claude 托管智能体（Managed Agents）内置记忆能力
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 1
source_image_count: 1
---

# Claude 托管智能体（Managed Agents）内置记忆能力

> • Built-in memory for Claude Managed Agents

> • 来源：Claude Blog，2026-04-23
> • 原文链接：https://claude.com/blog/claude-managed-agents-memory
> • 分类：Agents

## 核心要点

- 托管智能体的记忆功能现已开放公测，让智能体能够跨会话学习并相互共享所学。
- 记忆直接挂载到文件系统（filesystem）上，Claude 可借助其已有的 bash 与代码执行能力，保存更全面、组织更良好的记忆。
- 记忆面向企业部署而构建，具备作用域权限（scoped permissions）、审计日志（audit logs）以及完整的程序化控制。
- 记忆存储可在多个智能体间共享，并可设置不同的访问作用域；多个智能体能够并发操作同一存储而不会互相覆盖。
- 所有变更均通过详细的审计日志追踪，可回滚到早期版本或从历史中删改内容，并在 Claude Console 中以会话事件形式呈现。
- 多家团队已使用记忆功能闭合反馈回路、加速验证流程，并替代自建的检索基础设施。

## 正文

Claude 托管智能体（Managed Agents）的记忆功能现已开放公测（public beta）。你的智能体现在可以从每一次会话中学习，使用一个面向智能优化（intelligence-optimized）的记忆层，在性能与灵活性之间取得平衡。由于记忆以文件形式存储，开发者可以导出这些记忆、通过 API 进行管理，并对智能体所保留的内容保持完全掌控。

> Memory on Claude Managed Agents is available today in public beta. Your agents can now learn from every session, using an intelligence-optimized memory layer that balances performance with flexibility. Because memories are stored as files, developers can export them, manage them via the API, and keep full control over what agents retain.

Claude 托管智能体（Managed Agents）的记忆功能今日开放公开测试版（public beta）。你的智能体现在可以从每一次会话中学习，使用经过智能优化的记忆层，在性能与灵活性之间取得平衡。由于记忆以文件形式存储，开发者可以导出它们、通过 API 管理它们，并完全掌控智能体所保留的内容。

> Memory on Claude Managed Agents is available today in public beta. Your agents can now learn from every session, using an intelligence-optimized memory layer that balances performance with flexibility. Because memories are stored as files, developers can export them, manage them via the API, and keep full control over what agents retain.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69e911b25f02df256c8cba87_Claude-Blog-CMA-Memory.png)

### 跨会话学习的智能体

> Agents that learn across sessions

托管智能体（Managed Agents）将生产基础设施与一套为性能调优的执行框架（harness）结合起来。记忆功能进一步扩展了这一点：它针对长期运行的智能体在内部基准上做了优化，使其能够跨会话不断改进，并彼此分享所学到的内容。

> Managed Agents pairs production infrastructure with a harness tuned for performance. Memory extends that: it’s optimized against internal benchmarks for long-running agents that improve across sessions and share what they've learned with each other.

我们发现，当记忆建立在智能体已经使用的工具之上时，它们对记忆的运用最为有效。托管智能体上的记忆直接挂载到文件系统上，因此 Claude 可以依赖那些使其擅长智能体任务的 bash 和代码执行能力。借助基于文件系统的记忆，我们最新的模型能够保存更全面、更有条理的记忆，并且在为特定任务决定记住什么时更加有辨别力。

> We've found that agents are most effective with memory when it builds on the tools they already use. Memory on Managed Agents mounts directly onto a filesystem, so Claude can rely on the same bash and code execution capabilities that make it effective at agentic tasks. With filesystem-based memory, our latest models save more comprehensive, well-organized memories and are more discerning about what to remember for a given task.

### 生产级智能体的可移植记忆

> Portable memories for production-grade agents

记忆功能专为企业部署打造，具备范围化权限、审计日志和完整的编程控制。存储库（store）可在多个智能体之间共享，并设置不同的访问范围。例如，组织级存储库可设为只读，而每个用户的存储库则允许读写。多个智能体可以并发访问同一存储库，而不会相互覆盖。

> Memory is built for enterprise deployments, with scoped permissions, audit logs, and full programmatic control. Stores can be shared across multiple agents with different access scopes. For example, an org-wide store might be read-only, while per-user stores allow reads and writes. Multiple agents can work concurrently against the same store without overwriting each other.

记忆是文件，可通过 API 导出并独立管理，赋予开发者完全的控制权。所有改动都会通过详细的审计日志记录，因此你可以分辨某条记忆来自哪个智能体、哪个会话。你可以回滚到较早的版本，或从历史中删去（redact）某些内容。更新还会作为会话事件显示在 Claude 控制台（Console）中，让开发者能够追溯智能体学到了什么以及来源何处。

> Memories are files that can be exported and independently managed via the API, giving developers full control. All changes are tracked with a detailed audit log, so you can tell which agent and session a memory came from. You can roll back to an earlier version or redact content from history. Updates also surface in the Claude Console as session events, so developers can trace what an agent learned and where it came from.

### 团队正在构建什么

> What teams are building

团队一直在使用记忆来闭合反馈循环、加快验证速度，并替代定制的检索基础设施：

> Teams have been using memory to close feedback loops, speed up verification, and replace custom retrieval infrastructure:

- Netflix 的智能体在多个会话之间携带上下文，包括需要多轮对话才能发现的洞察，以及人类在对话中途做出的更正，而无需手动更新提示词（prompt）和技能。
- 乐天（Rakuten）基于任务的长时间运行智能体利用记忆从每个会话中学习，避免重复过去的错误，将首轮错误减少了 97%，而这一切都在以工作区为范围、可观测的边界内进行。
- Wisedocs 在托管智能体（Managed Agents）上构建了文档验证流水线，利用跨会话记忆发现并记住反复出现的文档问题，将验证速度提升了 30%。
- Ando 在托管智能体上构建其职场消息平台，捕捉每个组织的交互方式，而无需自行搭建记忆基础设施。

> • Netflix agents carry context across sessions, including insights that took multiple turns to uncover and corrections from a human mid-conversation, instead of manually updating prompts and skills.

> • Rakuten's task-based long-running agents use memory to learn from every session and avoid repeating past mistakes, cutting first-pass errors by 97%, all within workspace-scoped, observable boundaries.

> • Wisedocs built their document verification pipeline on Managed Agents, using cross-session memory to spot and remember recurring document issues, speeding up verification by 30%. ‍

> • Ando is building their workplace messaging platform on Managed Agents, capturing how each organization interacts instead of building memory infrastructure themselves.

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| memory | 记忆 |
| public beta | 公测 |
| intelligence-optimized | 面向智能优化 |
| memory layer | 记忆层 |
| filesystem | 文件系统 |
| harness | 运行框架 |
| internal benchmarks | 内部基准 |
| code execution | 代码执行 |
| scoped permissions | 作用域权限 |
| audit logs | 审计日志 |
| store | 存储 |
| session events | 会话事件 |
| Claude Console | Claude Console |
| feedback loops | 反馈回路 |
| retrieval infrastructure | 检索基础设施 |
| prompts | 提示词 |
| skills | 技能 |
| workspace-scoped | 工作区作用域 |
