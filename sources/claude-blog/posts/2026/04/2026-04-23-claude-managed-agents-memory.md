---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents-memory
published_at: 2026-04-23
category: Agents
title_en: Built-in memory for Claude Managed Agents
title_zh: Claude 托管智能体（Managed Agents）内置记忆能力
source_intro_paragraphs: 1
source_image_count: 1
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/MNDoBb60VLrOaAqbUm9gkvoQ8lemrZQ3"
---

# Claude 托管智能体（Managed Agents）内置记忆能力

> 来源：Claude Blog，2026-04-23
> 原文链接：https://claude.com/blog/claude-managed-agents-memory
> 分类：Agents

## 导语

Claude 托管智能体（Managed Agents）的记忆功能现已开放公测（public beta）。你的智能体现在可以从每一次会话中学习，使用一个面向智能优化（intelligence-optimized）的记忆层，在性能与灵活性之间取得平衡。由于记忆以文件形式存储，开发者可以导出这些记忆、通过 API 进行管理，并对智能体所保留的内容保持完全掌控。

## 核心要点

- 托管智能体的记忆功能现已开放公测，让智能体能够跨会话学习并相互共享所学。
- 记忆直接挂载到文件系统（filesystem）上，Claude 可借助其已有的 bash 与代码执行能力，保存更全面、组织更良好的记忆。
- 记忆面向企业部署而构建，具备作用域权限（scoped permissions）、审计日志（audit logs）以及完整的程序化控制。
- 记忆存储可在多个智能体间共享，并可设置不同的访问作用域；多个智能体能够并发操作同一存储而不会互相覆盖。
- 所有变更均通过详细的审计日志追踪，可回滚到早期版本或从历史中删改内容，并在 Claude Console 中以会话事件形式呈现。
- 多家团队已使用记忆功能闭合反馈回路、加速验证流程，并替代自建的检索基础设施。

## 中文译文

Claude 托管智能体（Managed Agents）的记忆功能现已开放公测（public beta）。你的智能体现在可以从每一次会话中学习，使用一个面向智能优化（intelligence-optimized）的记忆层，在性能与灵活性之间取得平衡。由于记忆以文件形式存储，开发者可以导出这些记忆、通过 API 进行管理，并对智能体所保留的内容保持完全掌控。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/69e911b25f02df256c8cba87_Claude-Blog-CMA-Memory.png)

### 能够跨会话学习的智能体

托管智能体将生产级基础设施与一个为性能调优的运行框架（harness）结合在一起。记忆功能在此基础上进一步拓展：它针对长时运行智能体的内部基准（internal benchmarks）进行了优化，使这些智能体能够跨会话不断改进，并相互共享所学到的内容。

我们发现，当记忆建立在智能体已经使用的工具之上时，记忆功能最为有效。托管智能体上的记忆直接挂载到文件系统（filesystem）上，因此 Claude 可以依赖那些让它在智能体任务中表现出色的同一套 bash 与代码执行能力。借助基于文件系统的记忆，我们最新的模型能够保存更全面、组织更良好的记忆，并在判断某项任务该记住什么时更加审慎。

### 面向生产级智能体的可移植记忆

记忆功能是为企业部署而构建的，具备作用域权限（scoped permissions）、审计日志（audit logs）以及完整的程序化控制。存储（store）可以在多个具有不同访问作用域的智能体之间共享。例如，一个组织级的存储可能设为只读，而每个用户独立的存储则允许读写。多个智能体可以并发操作同一存储，而不会互相覆盖彼此的内容。

记忆是可以导出、并通过 API 独立管理的文件，从而赋予开发者完全的控制权。所有变更都通过详细的审计日志进行追踪，因此你可以判断某条记忆来自哪个智能体和哪次会话。你可以回滚到更早的版本，或从历史中删改内容。更新还会在 Claude Console 中以会话事件（session events）的形式呈现，因此开发者可以追溯智能体学到了什么以及这些内容的来源。

### 各团队正在构建什么

各团队一直在使用记忆功能来闭合反馈回路、加速验证流程，并替代自建的检索基础设施：

- Netflix 的智能体能够跨会话承载上下文，包括那些需要多轮对话才能挖掘出的洞见，以及人类在对话中途做出的更正，而无需手动更新提示词（prompts）和技能（skills）。

- Rakuten 基于任务的长时运行智能体使用记忆功能从每次会话中学习，避免重复过去的错误，将首次通过的错误率削减了 97%，而且这一切都在工作区作用域（workspace-scoped）、可观测的边界之内完成。

- Wisedocs 在托管智能体之上构建了他们的文档验证流水线，利用跨会话记忆来发现并记住反复出现的文档问题，将验证速度提升了 30%。

- Ando 正在托管智能体之上构建他们的职场消息平台，捕捉每个组织的互动方式，而无需自行构建记忆基础设施。

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
