---
source: claude-blog
source_url: https://claude.com/blog/the-full-claude-desktop-experience-on-aws-google-cloud-and-microsoft-foundry
published_at: 2026-06-22
category: Enterprise AI
title_en: The full Claude Desktop experience on AWS, Google Cloud, and Microsoft Foundry
title_zh: 在 AWS、Google Cloud 和 Microsoft Foundry 上获得完整的 Claude Desktop 体验
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/P7QG4Yx2Jp7NyRBaIQwr35owV9dEq3XD"
---

# 在 AWS、Google Cloud 和 Microsoft Foundry 上获得完整的 Claude Desktop 体验
> 来源：Claude Blog，2026-06-22
> 原文链接：https://claude.com/blog/the-full-claude-desktop-experience-on-aws-google-cloud-and-microsoft-foundry
> 分类：Enterprise AI

## 核心要点
- 通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可在同一应用中获得完整体验：聊天（chat）、Claude Cowork 和 Claude Code。
- 推理（inference）可保留在组织自有环境中，并支持按用户单点登录（SSO）、移动设备管理（MDM）策略模板、离线安装程序，以及可完全在设备本地运行的 M365 连接器。
- 推理运行在你配置区域内的云上，对话历史存储于本地；你可控制数据连接器可触达的端点，以及 Anthropic 接收的聚合遥测数据。
- 聊天、Claude Cowork 和 Claude Code 各有独立的策略键（policy key），可由管理员决定谁在何时获得哪项能力。
- 登录与部署沿用已有系统：企业身份账户、Intune/GPO/Jamf 推送、air-gapped 环境的离线安装。
- Microsoft 365 连接器通过你自己的 Entra 应用访问邮件与文档，支持租户允许列表，并对 GCC High/DoD 端点提供测试版支持；最严格的驻留要求可使用本地连接器。

## 中文译文

通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可获得完整的 Desktop 体验——聊天（chat）、Claude Cowork 和 Claude Code，全部集成在一个应用中。

现在，IT 团队可以在各项产品中将推理（inference）保留在自己的环境内，并在全组织范围部署 Claude Desktop，支持按用户单点登录（SSO）、移动设备管理（MDM）策略模板、离线安装程序选项，以及可完全在设备上运行的 M365 连接器。

推理运行在你所配置区域内的云上，对话历史存储于本地。你可控制数据连接器可触达的端点，以及 Anthropic 接收的聚合遥测数据。

### 面向整个组织的统一界面

在今天之前，通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的客户只能访问 Claude Cowork 和 Claude Code。现在，一次部署即可覆盖所有角色，且每个界面都有自己的策略键（policy key），由你决定谁在何时获得哪项能力。聊天用于快速获取答案和理清问题。Claude Cowork 用于人们更愿意交托出去的工作：Claude 在已获批准的来源中进行调研，处理设备上已有的文件并构建交付物，完成后将结果呈现出来。Claude Code 面向希望进行代理式编码（agentic coding）、又不想一直待在终端里的工程师。

### 部署控制

在全组织范围部署 Claude Desktop，意味着在你已有的系统内运作。

像登录任何办公应用一样登录。员工使用与其他一切相同的工作账户：IAM Identity Center、Workforce Identity Federation、Microsoft Entra ID，或任何 OIDC 提供商（如 Okta）。无需轮换共享密钥，终端用户机器上也不存放云凭证。

像部署任何你已管理的应用一样部署。从设置界面导出策略模板，并通过 Intune、GPO 或 Jamf 推送。离线安装程序覆盖 air-gapped（物理隔离）环境。

在任何人看到之前确认它能正常工作。在推广前测试每个连接器、确认你的提供商所提供的 Claude 模型，并验证连接。即使设置配置有误，模型守卫（model guard）也会确保路由保持在 Claude 上，包括在 GovCloud 中。

从小规模起步，随采用度增长而扩展。聊天、Claude Cowork 和 Claude Code 各有独立的策略键，因此你可以给非技术团队提供聊天和 Claude Cowork，给工程团队提供 Claude Code，随后随着各团队对每个界面的采用而扩大访问范围。你的硬性拒绝规则（hard-deny rules）适用于每一个标签页。

把 Claude 带到工作所在之处。Microsoft 365 连接器通过你自己的 Entra 应用让 Claude 访问邮件和文档，支持租户允许列表（tenant allowlisting），并对 GCC High/DoD 端点提供测试版（beta）支持。对于最严格的驻留要求，可使用我们的本地连接器，连接仅在设备与 Microsoft 之间进行。

> “我们通过已有的云环境快速推出了 Claude Desktop——无需单独的供应商合同。我们自己的 LLM Gateway 让一个团队就能将其部署给全球数百名用户，无需进行繁重的基础设施建设。”——Sarang Oh，Hanwha Solutions 分析/AI 团队负责人

### 如何开始

对于管理员，部署指南将逐步介绍 SSO、策略模板和推广前验证。或者联系你的客户团队，我们将协助你规划推广。

## 术语对照
| English | 中文 |
|---|---|
| Claude Desktop | Claude Desktop |
| chat | 聊天 |
| Claude Cowork | Claude Cowork |
| Claude Code | Claude Code |
| inference | 推理 |
| SSO | 单点登录 |
| MDM | 移动设备管理 |
| policy key | 策略键 |
| policy template | 策略模板 |
| offline installer | 离线安装程序 |
| connector | 连接器 |
| telemetry | 遥测数据 |
| agentic coding | 代理式编码 |
| IAM Identity Center | IAM Identity Center |
| Workforce Identity Federation | Workforce Identity Federation |
| Microsoft Entra ID | Microsoft Entra ID |
| OIDC provider | OIDC 提供商 |
| air-gapped | 物理隔离 |
| model guard | 模型守卫 |
| hard-deny rules | 硬性拒绝规则 |
| tenant allowlisting | 租户允许列表 |
| local connector | 本地连接器 |
| LLM Gateway | LLM Gateway |
