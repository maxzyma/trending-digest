---
source: claude-blog
source_url: https://claude.com/blog/the-full-claude-desktop-experience-on-aws-google-cloud-and-microsoft-foundry
published_at: 2026-06-22
category: Enterprise AI
title_en: The full Claude Desktop experience on AWS, Google Cloud, and Microsoft Foundry
title_zh: 在 AWS、Google Cloud 和 Microsoft Foundry 上获得完整的 Claude Desktop 体验
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 0
source_image_count: 0
---

# 在 AWS、Google Cloud 和 Microsoft Foundry 上获得完整的 Claude Desktop 体验

> • The full Claude Desktop experience on AWS, Google Cloud, and Microsoft Foundry

> • 来源：Claude Blog，2026-06-22
> • 原文链接：https://claude.com/blog/the-full-claude-desktop-experience-on-aws-google-cloud-and-microsoft-foundry
> • 分类：Enterprise AI

## 核心要点

- 通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可在一个应用中获得完整体验：聊天、Claude Cowork 和 Claude Code。
- 推理（inference）在你自己的云环境、你配置的区域内运行，对话历史存储在本地。
- 聊天、Claude Cowork 和 Claude Code 各有独立的策略密钥（policy key），IT 团队可决定谁在何时获得哪项功能。
- 支持按用户单点登录（SSO）、MDM 策略模板、离线安装程序选项，以及可完全在设备上运行的 M365 连接器。
- 员工使用现有工作账户登录，无需共享密钥轮换或在终端机器上存储云凭证。
- Microsoft 365 连接器通过你自己的 Entra 应用提供邮件和文档访问，支持租户允许列表，并对 GCC High/DoD 端点提供测试版（beta）支持。

## 正文

通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可以获得完整的 Desktop 体验——聊天（chat）、Claude Cowork 和 Claude Code 全部集成在一个应用中。

> Organizations that use Claude Desktop through AWS, Google Cloud, and Microsoft Foundry now get the full Desktop experience — chat, Claude Cowork, and Claude Code, all in one app.

通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的组织，现在可以获得完整的 Desktop 体验——聊天、Claude Cowork 和 Claude Code，全部集中在一个应用中。

> Organizations that use Claude Desktop through AWS, Google Cloud, and Microsoft Foundry now get the full Desktop experience — chat, Claude Cowork, and Claude Code, all in one app.

现在 IT 团队可以在各个产品中将推理保持在自己的环境内，并在全组织范围部署 Claude Desktop，支持按用户单点登录（SSO）、MDM 策略模板、离线安装选项，以及可完全在设备上运行的 M365 连接器（connector）。

> Now IT teams can keep inference inside their own environment across products, and deploy Claude Desktop organization-wide with per-user SSO, MDM policy templates, an offline installer option, and an M365 connector that can run entirely on the device.

推理运行在你配置区域内的自有云上，对话历史存储在本地。你可以控制数据连接器访问的端点，以及 Anthropic 收到的聚合遥测数据。

> Inference runs on your cloud in the regions you configure and conversation history is stored locally. You control the endpoints data connectors reach and the aggregated telemetry Anthropic receives.

#### 面向整个组织的统一界面

> One surface for the entire organization

在今天之前，通过 AWS、Google Cloud 和 Microsoft Foundry 使用 Claude Desktop 的客户只能使用 Claude Cowork 和 Claude Code。现在，一次部署即可覆盖每一种角色，且每个界面都有各自的策略密钥，由你决定谁在什么时候获得什么。聊天用于快速获取答案和梳理问题。Claude Cowork 用于人们更愿意交付出去的工作：Claude 在已批准的来源中进行研究，处理设备上已有的文件并构建交付物，完成后呈现结果。Claude Code 面向希望进行智能体编码（agentic coding）又不想一直待在终端里的工程师。

> Until today, customers using Claude Desktop through AWS, Google Cloud, and Microsoft Foundry only had access to Claude Cowork and Claude Code. Now, one deployment covers every role, and each surface has its own policy key, so you decide who gets what, and when. Chat for quick answers and thinking through a problem. Claude Cowork for the work your people would rather hand off: Claude researches across approved sources, works with the files already on the device and builds the deliverable, surfacing results when it’s done. Claude Code for engineers who want agentic coding without living in a terminal.

#### 部署控制

> Deployment controls

在全组织范围部署 Claude Desktop 意味着在你已有的系统内开展工作。

> Deploying Claude Desktop organization-wide means working within the systems you already have.

像任何办公应用一样登录。员工使用与其他一切相同的工作账户：IAM Identity Center、Workforce Identity Federation、Microsoft Entra ID，或任何 OIDC 提供方（如 Okta）。没有需要轮换的共享密钥，终端用户机器上也没有云凭证。

> Sign in like any work app. Employees use the same work account they use for everything else: IAM Identity Center, Workforce Identity Federation, Microsoft Entra ID, or any OIDC provider like Okta. No shared keys to rotate, no cloud credentials on end-user machines.

像你已经管理的任何应用一样部署。从设置界面导出策略模板，并通过 Intune、GPO 或 Jamf 推送。离线安装程序可覆盖气隙（air-gapped）环境。

> Deploy like any app you already manage. Export policy templates from the setup UI and push them through Intune, GPO, or Jamf. An offline installer covers air-gapped environments.

在任何人看到之前确认其正常运行。测试每个连接器，确认你的提供方所服务的 Claude 模型，并验证连接，全部在推广之前完成。模型保护（model guard）会确保路由始终指向 Claude，包括在 GovCloud 中，即使某项设置配置有误也是如此。

> Know it works before anyone sees it. Test every connector, confirm which Claude models your provider serves, and verify the connection, all before rollout. A model guard keeps routing on Claude, including in GovCloud, even if a setting is misconfigured.

从小规模起步，随采用度增长而扩展。聊天、Claude Cowork 和 Claude Code 各自拥有独立的策略密钥，因此你可以给非技术团队提供聊天和 Claude Cowork，给工程团队提供 Claude Code，然后随着各团队采用每个界面而扩大访问范围。你设置的硬性拒绝规则适用于每一个标签页。

> Start small, expand as adoption grows. Chat, Claude Cowork, and Claude Code each have their own policy key, so you can give non-technical teams chat and Claude Cowork, engineering Claude Code, and then broaden access as teams adopt each surface. Your hard-deny rules apply across every tab.

将 Claude 带到工作所在之处。Microsoft 365 连接器通过你自己的 Entra 应用让 Claude 访问邮件和文档，支持租户白名单，并对 GCC High/DoD 端点提供 beta 支持。对于最严格的数据驻留要求，可使用我们的本地连接器，连接将仅在设备与 Microsoft 之间进行。

> • Bring Claude to where the work lives. A Microsoft 365 connector gives Claude access to mail and documents through your own Entra app, with tenant allowlisting and beta support for GCC High/DoD endpoints. For the strictest residency requirements, use our local connector, and the connection stays between the device and Microsoft.

> • "我们通过现有的云环境快速推出了 Claude Desktop——无需单独的供应商合同。我们自己的 LLM Gateway 让一个团队就能将其部署给全球数百名用户，无需大规模的基础设施建设。" - Sarang Oh，韩华解决方案（Hanwha Solutions）分析/AI 团队负责人

> "We rolled out Claude Desktop fast through our existing cloud environment — no separate vendor contract. Our own LLM Gateway let one team deploy it to hundreds of users worldwide, with no heavy infrastructure build-out." - Sarang Oh, Analytics/AI Team Leader, Hanwha Solutions

#### 开始使用

> Getting started

对于管理员，部署指南将逐步讲解 SSO、策略模板和推广前验证。或者联系你的客户团队，我们将帮助你规划推广。

> For admins, the deployment guide walks through SSO, policy templates, and pre-rollout validation. Or contact your account team and we'll help you plan the rollout.

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
