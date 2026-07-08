---
source: claude-blog
source_url: https://claude.com/blog/bringing-claude-code-and-claude-cowork-to-government
published_at: 2026-07-07
category: Claude Code
title_en: Bringing Claude Code and Claude Cowork to government
title_zh: 将 Claude Code 与 Claude Cowork 引入政府部门
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 4
source_image_count: 0
---

# 将 Claude Code 与 Claude Cowork 引入政府部门

> Bringing Claude Code and Claude Cowork to government

> 来源：Claude Blog，2026-07-07
> 原文链接：https://claude.com/blog/bringing-claude-code-and-claude-cowork-to-government
> 分类：Claude Code

## 核心要点

- Claude Code 与 Claude Cowork 以公开测试形式登陆 Claude for Government Desktop，与商业版基于同一应用，并运行在 FedRAMP High 授权环境中。
- 公共部门团队可用 Claude Code 构建与现代化支撑公共服务的软件系统，用 Claude Cowork 直接处理桌面文件，委托备忘录撰写、招标评审、案件处理和演示文稿制作。
- 对话历史存储在机构管理的本地设备上，推理在 FedRAMP High 授权环境内运行，机构与商业用户同步获得新功能。
- 计费方式贴合财政拨款：预付固定额度、设有不可超支上限，管理员可按用户与模型追踪用量，余额偏低时自动预警。
- 管理体系匹配部门组织结构：部门级管理员可向下属机构分配席位与预付用量，并通过 SCIM 分组映射设定速率限制、金额上限和可用模型。
- 内建监督机制：所有管理操作记录在哈希链审计日志中，敏感操作需双人审批，用量导出仅含计量数据，便于机构应对 ATO 与监察长审查。
- 面向安全团队公开发布 FedRAMP 安全配置指南、变更通知与渗透测试摘要，应用通过标准机构 MDM 平台部署。

## 正文

Claude Code 与 Claude Cowork 现已在 Claude for Government Desktop 中开放公开测试，其构建于我们商业客户所使用的同一款应用，并通过 FedRAMP High 授权环境交付。

> Claude Code and Claude Cowork are now available in public beta in Claude for Government Desktop, built on the same application our commercial customers use and delivered through a FedRAMP High authorized environment.

借助 Claude Code，公共部门团队可以构建和现代化支撑公共服务的软件系统。Claude Cowork 直接处理桌面上的文件，让机构人员能够将备忘录撰写、招标书（RFP）审阅、案件处理和演示文稿等工作委托给 Claude。

> With Claude Code, public sector teams can build and modernize the software systems that underpin public services. Claude Cowork works directly with files on the desktop, allowing agency staff to delegate memo creation, RFP reviews, casework, and decks to Claude.

扩展后的体验还带来了额外的治理能力。管理员可以设置默认配置，并在各部门之间分配和管控支出。安全团队和授权官员可获得防篡改的审计日志，以及支持机构 ATO 流程的文档。

> The expanded experience also comes with additional governance capabilities. Administrators can set configuration defaults as well as allocate and control spending across departments. Security teams and authorizing officials get tamper-evident audit logs and documentation that supports the agency ATO process.

今天的发布让各机构能够更轻松地获取、授权和分配 AI，以推进其使命。

> Today’s launch makes it easier for agencies to acquire, authorize, and allocate AI in pursuit of their missions.

### 新功能

> What's new

Claude Code 与 Claude Cowork。政府机构与我们的商业用户以相同节奏获得新功能。对话历史存储在机构管理的本地设备上。推理在获得 FedRAMP High 授权的环境中运行。

> Claude Code and Claude Cowork. Agencies get new capabilities on the same cadence as our commercial users. Conversation history is stored locally on the agency-managed device. Inference runs inside a FedRAMP High authorized environment.

契合拨款方式的计费。项目办公室可以用标准席位将 AI 支出与已拨付资金挂钩，也可以自行定义带有支出和模型限制的席位层级，用量按固定增量购买，并设有硬性的不可超支上限（not-to-exceed cap）。管理员可以在管理控制台中按用户和按模型追踪用量，余额不足前会自动发出消耗预警。

> Billing that fits appropriations. Program offices can tie AI spend to appropriated funds with standard seats or they can define their own seat tiers with spend and model limits, and usage is purchased in fixed increments with a hard not-to-exceed cap. Administrators can track usage per user and per model in the admin console, and automatic burndown alerts warn them before the balance runs low.

契合部门组织架构的管理方式。部门级管理员可以向下属机构分配席位和预付用量，同时允许各机构自行管理其用户。管理员可以使用 SCIM 组映射，为特定席位层级设置速率限制、金额上限和允许使用的模型。此外，分层配置可为下属机构设定默认项，包括 Claude 可连接的对象、可用的功能，以及指导 Claude 如何与用户交互的说明。

> Administration that matches how departments are organized. Department-level administrators can allocate seats and prepaid usage to sub-agencies while allowing each to manage its own users. Administrators can use SCIM group mappings to set rate limits, dollar caps, and allowed models for specific seat tiers. Additionally, layered configuration sets defaults for sub-agencies including what Claude can connect to, which features are available, and instructions that guide how Claude interacts with users.

内建监督机制。每一项管理操作都会记录在哈希链式审计日志（hash-chained audit log）中，组织管理员可直接在产品中查看。Anthropic 一侧的敏感操作需要双人审批。用量导出仅包含计量数据，因此机构在应对授权运行（ATO）和监察长（IG）请求时无需转移敏感材料。

> Oversight by design. Every administrative action is recorded in a hash-chained audit log that organization administrators can review directly in the product. Sensitive operations on Anthropic's side require two-person approval. Usage exports are metering data only so agencies can answer ATO and IG requests without moving sensitive material.

### 安全与监管

> Security and oversight

对于评估桌面部署的安全团队，我们将把 FedRAMP 安全配置指南（FedRAMP Secure Configuration Guide）作为一份面向公众的文档发布，客户可用它以安全的方式配置其 Claude for Government 产品。

> For security teams evaluating the desktop deployment, we're publishing our FedRAMP Secure Configuration Guide as a public-facing document that customers can use to configure their Claude for Government product in a secure manner.

此外，FedRAMP 要求我们提供正式的变更通知，其中包含与此次变更相关的详细信息。

> In addition, FedRAMP requires us to provide our formal change notification, which contains details associated with this change.

最后，新桌面客户端已提供渗透测试摘要，后续的跟进渗透测试摘要也将在可用时提供。变更通知和渗透测试摘要可通过 Anthropic 的信任中心（trust center）在保密协议（NDA）下获取。该应用通过标准的机构移动设备管理（MDM）平台部署。

> Lastly, a penetration-test summary is available for the new desktop client, and subsequent follow up penetration-tests summaries will be provided once available. The change notification and pentest summary are available under NDA through Anthropic’s trust center. The application deploys through standard agency MDM platforms.

### 快速开始

> Getting started

Claude for Government 自今日起提供测试版（beta）。Anthropic 仍是签约方和账单方——各机构无需单独建立云服务商关系即可开始使用。

> Claude for Government is available in beta starting today. Anthropic remains the contracted and billing party—agencies don't need a separate cloud-provider relationship to get started.

新客户可在 claude.com/solutions/government 申请访问权限。

> New customers can request access at claude.com/solutions/government .

安全团队可通过以下链接下载渗透测试（penetration-test）成果文件。

> Security teams can download the penetration-test artifact through the following link .

## 术语对照

| English | 中文 |
|---|---|
| Claude Code | Claude Code |
| Claude Cowork | Claude Cowork |
| public beta | 公开测试 |
| FedRAMP High | FedRAMP High（联邦风险与授权管理计划高级别） |
| ATO (Authority to Operate) | 运行授权 |
| audit log | 审计日志 |
| hash-chained | 哈希链 |
| SCIM group mappings | SCIM 分组映射 |
| seat tiers | 席位层级 |
| burndown alerts | 余额消耗预警 |
| MDM (Mobile Device Management) | 移动设备管理 |
| penetration test | 渗透测试 |
| RFP (Request for Proposal) | 招标书 |
| Inspector General (IG) | 监察长 |
