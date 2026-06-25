---
source: claude-blog
source_url: https://claude.com/blog/the-full-claude-desktop-experience-on-aws-google-cloud-and-microsoft-foundry
published_at: 2026-06-22
category: Enterprise AI
title_en: The full Claude Desktop experience on AWS, Google Cloud, and Microsoft Foundry
title_zh: 在 AWS、Google Cloud 和 Microsoft Foundry 上获得完整的 Claude Desktop 体验
source_intro_paragraphs: 0
source_image_count: 0
---

# 在 AWS、Google Cloud 和 Microsoft Foundry 上获得完整的 Claude Desktop 体验

> 来源：Claude Blog，2026-06-22
> 原文链接：https://claude.com/blog/the-full-claude-desktop-experience-on-aws-google-cloud-and-microsoft-foundry
> 分类：Enterprise AI

## 导语

通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可以获得完整的 Desktop 体验——聊天（chat）、Claude Cowork 和 Claude Code 全部集成在一个应用中。

## 核心要点

- 通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可在一个应用中获得完整体验：聊天、Claude Cowork 和 Claude Code。
- 推理（inference）在你自己的云环境、你配置的区域内运行，对话历史存储在本地。
- 聊天、Claude Cowork 和 Claude Code 各有独立的策略密钥（policy key），IT 团队可决定谁在何时获得哪项功能。
- 支持按用户单点登录（SSO）、MDM 策略模板、离线安装程序选项，以及可完全在设备上运行的 M365 连接器。
- 员工使用现有工作账户登录，无需共享密钥轮换或在终端机器上存储云凭证。
- Microsoft 365 连接器通过你自己的 Entra 应用提供邮件和文档访问，支持租户允许列表，并对 GCC High/DoD 端点提供测试版（beta）支持。

## 中文译文

通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可以获得完整的 Desktop 体验——聊天（chat）、Claude Cowork 和 Claude Code 全部集成在一个应用中。

现在，IT 团队可以在各个产品中将推理（inference）保持在自己的环境内，并在全组织范围内部署 Claude Desktop，配备按用户单点登录（SSO）、MDM 策略模板、离线安装程序选项，以及可完全在设备上运行的 M365 连接器。

推理在你的云环境、你配置的区域内运行，对话历史存储在本地。你掌控数据连接器可访问的端点，以及 Anthropic 接收的聚合遥测数据（aggregated telemetry）。

### 面向整个组织的统一界面

直到今天，通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的客户只能访问 Claude Cowork 和 Claude Code。现在，一次部署即可覆盖每一个角色，且每个界面都有自己的策略密钥（policy key），因此由你决定谁在何时获得什么。聊天用于获取快速答案和理清问题思路。Claude Cowork 用于处理人们更愿意交付出去的工作：Claude 在已批准的来源中进行研究，处理设备上已有的文件并构建交付成果，完成后呈现结果。Claude Code 面向希望进行智能体编码（agentic coding）而不必常驻终端的工程师。

### 部署控制

在全组织范围内部署 Claude Desktop，意味着在你已有的系统中开展工作。

像任何工作应用一样登录。员工使用他们处理其他一切事务时所用的同一工作账户：IAM Identity Center、Workforce Identity Federation、Microsoft Entra ID，或任何 OIDC 提供商（如 Okta）。无需轮换共享密钥，终端用户机器上也不存储云凭证。

像你已管理的任何应用一样部署。从设置界面导出策略模板，并通过 Intune、GPO 或 Jamf 推送。离线安装程序可覆盖气隙隔离（air-gapped）环境。

在任何人看到之前就确认其正常运行。在推出前测试每一个连接器、确认你的提供商所提供的 Claude 模型，并验证连接。模型守卫（model guard）会让路由保持在 Claude 上，包括在 GovCloud 中，即使某项设置配置有误也是如此。

从小处着手，随着采用扩大而扩展。聊天、Claude Cowork 和 Claude Code 各有自己的策略密钥，因此你可以给非技术团队提供聊天和 Claude Cowork，给工程团队提供 Claude Code，然后随着各团队对每个界面的采用而扩大访问权限。你的硬性拒绝规则（hard-deny rules）适用于每一个标签页。

把 Claude 带到工作所在之处。Microsoft 365 连接器通过你自己的 Entra 应用让 Claude 访问邮件和文档，支持租户允许列表（tenant allowlisting），并对 GCC High/DoD 端点提供测试版（beta）支持。对于最严格的驻留要求，可使用我们的本地连接器，连接将仅在设备与 Microsoft 之间进行。

> "我们通过现有的云环境快速推出了 Claude Desktop——无需单独的供应商合同。我们自己的 LLM 网关（LLM Gateway）让一个团队就能将其部署给全球数百名用户，无需繁重的基础设施建设。" —— Sarang Oh，Hanwha Solutions 分析/AI 团队负责人

### 入门上手

对于管理员，部署指南会逐步介绍 SSO、策略模板和推出前验证。或者联系你的客户团队，我们将帮助你规划推出。

## 术语对照

| English | 中文 |
|---|---|
| inference | 推理 |
| chat | 聊天 |
| policy key | 策略密钥 |
| aggregated telemetry | 聚合遥测数据 |
| agentic coding | 智能体编码 |
| air-gapped | 气隙隔离 |
| model guard | 模型守卫 |
| hard-deny rules | 硬性拒绝规则 |
| tenant allowlisting | 租户允许列表 |
| LLM Gateway | LLM 网关 |
| offline installer | 离线安装程序 |
