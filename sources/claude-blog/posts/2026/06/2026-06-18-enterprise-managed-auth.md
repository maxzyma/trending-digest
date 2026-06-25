---
source: claude-blog
source_url: https://claude.com/blog/enterprise-managed-auth
published_at: 2026-06-18
category: Enterprise AI
title_en: Centrally manage authorization for MCP connectors
title_zh: 集中管理 MCP 连接器的授权
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 0
source_image_count: 0
---

# 集中管理 MCP 连接器的授权

> 🌏︎ • Centrally manage authorization for MCP connectors

> • 来源：Claude Blog，2026-06-18
> • 原文链接：https://claude.com/blog/enterprise-managed-auth
> • 分类：Enterprise AI

## 核心要点

- 企业托管授权（Enterprise-managed authorization）让管理员只需授权一次连接器，用户即可通过既有的身份提供商组与角色自动继承访问权限。
- 用户首次打开 Claude 时连接器就已就位，实现端用户的零接触（zero-touch）连接器设置。
- 该功能是模型上下文协议（Model Context Protocol，MCP）的「企业托管授权扩展」的首个实现，基于开放标准，任何连接器（包括自建的自定义连接器）都可支持。
- 访问权限通过组织已信任的身份提供商运行，连接器纳入与其他系统相同的安全与访问控制。
- 管理员可缩短访问令牌生命周期而不影响生产力，并可要求连接器只能通过身份提供商连接，从而干净地区分工作与个人使用。
- 首批身份提供商支持 Okta；MCP 提供商支持 Asana、Atlassian、Canva、Figma、Granola、Linear 和 Supabase。

## 正文

管理员现在可以通过身份提供商（identity provider）为整个组织预配 MCP 连接器，首批支持 Okta。用户在首次登录时即可自动获得连接器访问权限，授权由其所在组织集中配置。

> 🌏︎ Admins can now provision MCP connectors for their whole organization through their identity provider, starting with Okta. Users get connector access automatically on first login, with authorization configured centrally by their organization.

管理员现在可以通过身份提供商（IdP）为整个组织配置 MCP 连接器（connector），首批支持 Okta。用户首次登录即自动获得连接器访问权限，授权由组织集中配置。

> 🌏︎ Admins can now provision MCP connectors for their whole organization through their identity provider, starting with Okta. Users get connector access automatically on first login, with authorization configured centrally by their organization.

连接器让 Claude 在工作中更有用——它们从团队已经在使用的工具中为 Claude 提供所需的上下文。在此之前，启用连接器需要两个步骤的操作：管理员为组织启用某个连接器，然后每个用户再自行授权。

> 🌏︎ Connectors make Claude more useful at work — they give Claude the context it needs from the tools that your teams already use. Until now, turning them on required action at two steps: admins enabled a connector for the organization, and then every individual user authorized it themselves.

企业托管授权简化了第二步。管理员只需授权一次连接器，用户便通过其已有的 IdP 组和角色继承访问权限，连接器在他们首次打开 Claude 时就已就位。最终实现了终端用户零操作的连接器设置。

> 🌏︎ Enterprise-managed authorization streamlines that second step. Admins authorize a connector once, users inherit access through the IdP groups and roles they already have, and the connector is there the first time someone opens Claude. The result is zero-touch connector setup for the end user.

企业托管授权是模型上下文协议（Model Context Protocol）"企业托管授权"扩展的首个实现。它构建于开放标准之上，因此任何连接器都可以支持它——包括你的团队自己构建的自定义连接器——并且它们对每一个 Claude 客户都以相同方式运作。

> 🌏︎ Enterprise-managed auth is the first implementation of the Enterprise-Managed Authorization extension to the Model Context Protocol. It's built on an open standard so any connector can support it — including the custom connectors your own teams build — and they all work the same way for every Claude customer.

#### 工作原理

> How it works

将身份提供商连接到 Claude，并选择要为组织启用哪些 MCP 连接器。当员工登录时，连接器已经就位。访问权限在 Claude 聊天、Claude Code 和 Cowork 中保持一致。

> 🌏︎ Connect your identity provider to Claude and choose which MCP connectors to enable for your organization. When an employee logs in, their connectors are already there. Access stays consistent across Claude chat, Claude Code, and Cowork.

对管理员而言，这把 MCP 访问管理纳入了治理其余技术栈的同一套工作流程：配置一次、按组限定范围、通过 IdP 管理撤销。由于与 IdP 校验访问权限毫无阻力，管理员可以缩短访问令牌（access token）的有效期而不影响生产力——这样当某人被取消授权时，其连接器访问权限会迅速过期，而不会在旧令牌上残留。访问通过你已经信任的身份提供商进行，因此连接器与其他一切都受同样的安全和访问控制约束，而不是需要单独监控的另一个面。

> 🌏︎ For admins, this folds MCP access management into the same workflow that governs the rest of your stack: provision once, scope by group, manage revocation through the IdP. Because checking access with the IdP is frictionless, admins can shorten access token lifetimes without impacting productivity — so when someone is deprovisioned, their connector access expires fast instead of lingering on an old token. Access runs through the identity provider you already trust, so connectors fall under the same security and access controls as everything else, rather than a separate surface to monitor.

管理员还可以要求某个连接器只能通过 IdP 连接，这能让工作与个人用途清晰分离，并防止有人不慎将个人账户关联到工作工具。

> 🌏︎ Admins can also require that a connector only ever connects through the IdP, which keeps work and personal use cleanly separated and prevents someone from accidentally linking a personal account to a work tool.

#### 生态共建

> Built with an ecosystem

企业托管授权在三个群体间协同运作：治理访问权限的身份提供商、支持该标准的 MCP 提供商，以及在各团队中部署托管连接的 Claude 客户。

> 🌏︎ Enterprise-managed authorization works across three groups: the identity providers that govern access, the MCP providers that support the standard, and the Claude customers deploying managed connections across their teams.

身份提供商。发布时支持 Okta，更多身份提供商的支持即将到来。

> 🌏︎ Identity providers. Okta is supported at launch, with support for additional identity providers coming soon.

MCP 提供商。Asana、Atlassian、Canva、Figma、Granola、Linear 和 Supabase 在发布时支持企业托管授权，Slack 即将支持。

> 🌏︎ MCP providers. Asana, Atlassian, Canva, Figma, Granola, Linear, and Supabase support Enterprise-managed auth at launch, with Slack coming soon.

Claude 客户。Hubspot、Ramp 和 Webflow 等组织正在各自团队中推广企业托管授权。

> 🌏︎ Claude customers. Hubspot, Ramp, and Webflow are among the organizations rolling out enterprise-managed auth across their teams.

## 术语对照

| English | 中文 |
|---|---|
| Enterprise-managed authorization | 企业托管授权 |
| identity provider (IdP) | 身份提供商 |
| connector | 连接器 |
| Model Context Protocol (MCP) | 模型上下文协议 |
| access token | 访问令牌 |
| zero-touch | 零接触 |
| provision / deprovision | 预配 / 取消预配 |
| revocation | 撤销 |
