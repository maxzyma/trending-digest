---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents-memory
published_at: 2026-04-23
category: Agents
title_en: Built-in memory for Claude Managed Agents
title_zh: Claude 托管智能体（Claude Managed Agents）内置记忆功能
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/QOG9lyrgJP3ORbKxSvykMR2kVzN67Mw4"
---

# Claude 托管智能体（Claude Managed Agents）内置记忆功能

> 来源：Claude Blog，2026-04-23
> 原文链接：https://claude.com/blog/claude-managed-agents-memory
> 分类：Agents

## 核心要点

- Claude 托管智能体（Managed Agents）的记忆功能即日起以公开测试版（public beta）形式上线，让智能体能从每次会话中学习。
- 记忆以文件形式存储，开发者可导出、通过 API 管理，并完全掌控智能体所保留的内容。
- 记忆直接挂载到文件系统（filesystem）上，Claude 可借助其已有的 bash 和代码执行能力进行操作。
- 记忆面向企业部署设计，具备作用域权限（scoped permissions）、审计日志（audit logs）和完整的编程化控制能力。
- 多个智能体可在不同访问作用域下共享存储，并能并发操作同一存储而不互相覆盖。
- 所有变更均记录在详细的审计日志中，支持版本回滚和历史内容删除，相关更新会在 Claude 控制台中以会话事件呈现。

## 中文译文

Claude 托管智能体（Claude Managed Agents）的记忆功能即日起以公开测试版（public beta）形式提供。你的智能体现在可以从每一次会话中学习，使用一个面向智能优化的记忆层（memory layer），在性能与灵活性之间取得平衡。由于记忆以文件形式存储，开发者可以导出它们、通过 API 进行管理，并对智能体所保留的内容保持完全的控制。

## 跨会话学习的智能体

托管智能体将生产级基础设施与一套为性能调优的运行框架（harness）相结合。记忆功能对此进行了扩展：它针对长时间运行的智能体的内部基准（internal benchmarks）进行了优化，使这些智能体能够跨会话不断改进，并彼此共享所学到的内容。

我们发现，当记忆建立在智能体已经使用的工具之上时，记忆的效果最佳。托管智能体上的记忆直接挂载到文件系统（filesystem）上，因此 Claude 可以依赖那些让它在智能体任务中表现出色的同样的 bash 和代码执行能力。借助基于文件系统的记忆，我们最新的模型能够保存更全面、组织更良好的记忆，并且在判断某项任务该记住什么内容时更加审慎。

## 面向生产级智能体的可移植记忆

记忆功能是为企业部署而构建的，具备作用域权限（scoped permissions）、审计日志（audit logs）以及完整的编程化控制。存储（store）可以在多个智能体之间共享，并采用不同的访问作用域。例如，一个组织级（org-wide）存储可以设为只读，而按用户（per-user）划分的存储则允许读写。多个智能体可以并发地操作同一个存储，而不会互相覆盖。

记忆是可以导出、并通过 API 独立管理的文件，从而赋予开发者完全的控制权。所有变更都会通过详细的审计日志进行追踪，因此你可以分辨出某条记忆来自哪个智能体和哪次会话。你可以回滚到较早的版本，或从历史记录中删除（redact）内容。这些更新还会在 Claude 控制台（Claude Console）中以会话事件（session events）的形式呈现，因此开发者可以追溯智能体学到了什么以及这些内容来自何处。

## 各团队的实践

各团队一直在使用记忆功能来闭合反馈循环、加速验证，并替换自建的检索基础设施：

- Netflix 的智能体能够跨会话延续上下文，包括那些需要多轮对话才能挖掘出的洞见，以及人类在对话中途做出的纠正，而无需手动更新提示词（prompt）和技能（skill）。

- Rakuten 基于任务的长时间运行智能体使用记忆来从每次会话中学习，避免重复过去的错误，将首轮（first-pass）错误减少了 97%，而这一切都在工作区作用域（workspace-scoped）且可观测（observable）的边界内完成。

- Wisedocs 在托管智能体上构建了他们的文档验证流水线（pipeline），利用跨会话记忆来发现并记住反复出现的文档问题，将验证速度提升了 30%。

- Ando 正在托管智能体上构建他们的职场消息平台，捕捉每个组织的交互方式，而无需自行构建记忆基础设施。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| memory | 记忆 |
| public beta | 公开测试版 |
| memory layer | 记忆层 |
| filesystem | 文件系统 |
| harness | 运行框架 |
| internal benchmarks | 内部基准 |
| code execution | 代码执行 |
| scoped permissions | 作用域权限 |
| audit logs | 审计日志 |
| store | 存储 |
| org-wide | 组织级 |
| per-user | 按用户划分 |
| redact | 删除/编辑 |
| Claude Console | Claude 控制台 |
| session events | 会话事件 |
| prompt | 提示词 |
| skill | 技能 |
| first-pass errors | 首轮错误 |
| workspace-scoped | 工作区作用域 |
| pipeline | 流水线 |
