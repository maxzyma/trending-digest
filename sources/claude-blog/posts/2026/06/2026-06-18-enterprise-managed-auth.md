---
source: claude-blog
source_url: https://claude.com/blog/enterprise-managed-auth
published_at: 2026-06-18
category: Enterprise AI
title_en: Centrally manage authorization for MCP connectors
title_zh: 集中管理 MCP 连接器的授权
source_intro_paragraphs: 0
source_image_count: 0
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/93NwLYZXWyglMOjysNazaqo0JkyEqBQm"
---

# 集中管理 MCP 连接器的授权

> 来源：Claude Blog，2026-06-18
> 原文链接：https://claude.com/blog/enterprise-managed-auth
> 分类：Enterprise AI

## 导语

管理员现在可以通过身份提供商（identity provider）为整个组织预配 MCP 连接器，首批支持 Okta。用户在首次登录时即可自动获得连接器访问权限，授权由其所在组织集中配置。

## 核心要点

- 企业托管授权（Enterprise-managed authorization）让管理员只需授权一次连接器，用户即可通过既有的身份提供商组与角色自动继承访问权限。
- 用户首次打开 Claude 时连接器就已就位，实现端用户的零接触（zero-touch）连接器设置。
- 该功能是模型上下文协议（Model Context Protocol，MCP）的「企业托管授权扩展」的首个实现，基于开放标准，任何连接器（包括自建的自定义连接器）都可支持。
- 访问权限通过组织已信任的身份提供商运行，连接器纳入与其他系统相同的安全与访问控制。
- 管理员可缩短访问令牌生命周期而不影响生产力，并可要求连接器只能通过身份提供商连接，从而干净地区分工作与个人使用。
- 首批身份提供商支持 Okta；MCP 提供商支持 Asana、Atlassian、Canva、Figma、Granola、Linear 和 Supabase。

## 中文译文

管理员现在可以通过身份提供商为整个组织预配 MCP 连接器，首批支持 Okta。用户在首次登录时即可自动获得连接器访问权限，授权由其所在组织集中配置。

连接器（connectors）让 Claude 在工作中更加有用——它们从你的团队已经在使用的工具中为 Claude 提供所需的上下文。在此之前，启用连接器需要两个步骤的操作：管理员为组织启用某个连接器，然后每位用户各自对其进行授权。

企业托管授权简化了第二步。管理员对连接器授权一次，用户通过其已拥有的身份提供商组（IdP groups）和角色继承访问权限，连接器在某人首次打开 Claude 时便已就位。最终为端用户实现了零接触的连接器设置。

企业托管授权是模型上下文协议「企业托管授权扩展」的首个实现。它构建于开放标准之上，因此任何连接器都可以支持它——包括你的团队自行构建的自定义连接器——并且对每一位 Claude 客户都以相同方式运作。

### 工作原理

将你的身份提供商接入 Claude，并选择要为组织启用哪些 MCP 连接器。当一名员工登录时，他们的连接器就已经在那里。访问权限在 Claude 聊天、Claude Code 和 Cowork 之间保持一致。

对管理员而言，这将 MCP 访问管理纳入了与管理你其余技术栈相同的工作流程：预配一次、按组划分范围、通过身份提供商管理撤销。由于通过身份提供商检查访问权限毫无阻力，管理员可以缩短访问令牌（access token）的生命周期而不影响生产力——因此当某人被取消预配时，其连接器访问权限会迅速过期，而不是依附在旧令牌上长期残留。访问权限通过你已经信任的身份提供商运行，因此连接器与其他一切一样纳入相同的安全与访问控制，而不是另一个需要监控的独立面。

管理员还可以要求某个连接器始终只能通过身份提供商连接，这能干净地区分工作与个人用途，并防止有人不慎将个人账户关联到工作工具上。

### 与生态系统共同构建

企业托管授权在三类群体之间运作：管理访问权限的身份提供商、支持该标准的 MCP 提供商，以及在团队中部署托管连接的 Claude 客户。

身份提供商。发布时支持 Okta，对更多身份提供商的支持即将推出。

MCP 提供商。Asana、Atlassian、Canva、Figma、Granola、Linear 和 Supabase 在发布时支持企业托管授权，Slack 即将支持。

Claude 客户。Hubspot、Ramp 和 Webflow 是正在团队中推广企业托管授权的组织之一。

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
