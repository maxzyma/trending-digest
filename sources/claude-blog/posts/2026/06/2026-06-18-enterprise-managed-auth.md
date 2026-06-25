---
source: claude-blog
source_url: https://claude.com/blog/enterprise-managed-auth
published_at: 2026-06-18
category: Enterprise AI
title_en: Centrally manage authorization for MCP connectors
title_zh: 集中管理 MCP 连接器的授权
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/vy20BglGWOeO7PEycg7OxyoOJA7depqY"
---

# 集中管理 MCP 连接器的授权

> 来源：Claude Blog，2026-06-18
> 原文链接：https://claude.com/blog/enterprise-managed-auth
> 分类：Enterprise AI

## 核心要点

- 管理员现在可以通过身份提供商（identity provider，IdP）为整个组织统一开通 MCP 连接器（connector），首批支持 Okta。
- 用户在首次登录时即可自动获得连接器访问权限，授权由组织集中配置，实现端用户的零操作（zero-touch）设置。
- 企业托管授权（Enterprise-managed authorization）是模型上下文协议（Model Context Protocol，MCP）"企业托管授权扩展"的首个实现，基于开放标准，任何连接器（包括自建连接器）都可支持。
- 访问权限通过组织已有的 IdP 群组与角色继承，并在 Claude chat、Claude Code 和 Cowork 中保持一致。
- 管理员可缩短访问令牌（access token）有效期、要求连接器仅经由 IdP 连接，从而加快撤销并隔离工作与个人使用。
- 该能力依托身份提供商、MCP 提供商和 Claude 客户三方生态协同推进。

## 中文译文

管理员现在可以通过其身份提供商（identity provider）为整个组织开通 MCP 连接器（connector），首批支持 Okta。用户在首次登录时即可自动获得连接器访问权限，授权由其组织集中配置。

连接器让 Claude 在工作中更加实用——它们为 Claude 提供所需的上下文，这些上下文来自团队已经在使用的工具。在此之前，启用连接器需要两个步骤的操作：管理员为组织启用某个连接器，然后每位用户各自进行授权。

企业托管授权（Enterprise-managed authorization）简化了第二步。管理员只需对连接器授权一次，用户便可通过他们已有的 IdP 群组和角色继承访问权限，连接器在用户首次打开 Claude 时就已就位。最终实现了对端用户而言零操作（zero-touch）的连接器设置。

企业托管授权是模型上下文协议（Model Context Protocol）"企业托管授权扩展（Enterprise-Managed Authorization extension）"的首个实现。它建立在开放标准之上，因此任何连接器都能支持它——包括你的团队自行构建的自定义连接器——并且对每一位 Claude 客户而言，它们的工作方式都完全一致。

### 工作原理

将你的身份提供商连接到 Claude，并选择要为组织启用哪些 MCP 连接器。当员工登录时，他们的连接器就已经准备就绪。访问权限在 Claude chat、Claude Code 和 Cowork 之间保持一致。

对于管理员来说，这将 MCP 访问管理纳入了治理其余技术栈的同一套工作流：一次开通、按群组划分范围、通过 IdP 管理撤销。由于借助 IdP 检查访问权限毫无摩擦，管理员可以缩短访问令牌（access token）的有效期而不影响工作效率——因此当某人被取消授权时，其连接器访问权限会迅速过期，而不会因为留在旧令牌上而长期残留。访问权限通过你已经信任的身份提供商进行，所以连接器与其他一切一样受同一套安全与访问控制约束，而非一个需要单独监控的界面。

管理员还可以要求某个连接器始终只通过 IdP 连接，这样可以将工作与个人使用清晰隔离，并防止有人不小心把个人账户关联到工作工具上。

### 与生态共建

企业托管授权在三类群体之间协同运作：治理访问权限的身份提供商、支持该标准的 MCP 提供商，以及在团队中部署托管连接的 Claude 客户。

**身份提供商。** 发布时支持 Okta，更多身份提供商的支持即将到来。

**MCP 提供商。** Asana、Atlassian、Canva、Figma、Granola、Linear 和 Supabase 在发布时支持企业托管授权，Slack 即将支持。

**Claude 客户。** Hubspot、Ramp 和 Webflow 是首批在团队中推广企业托管授权的组织之一。

## 术语对照

| English | 中文 |
|---|---|
| MCP connector | MCP 连接器 |
| identity provider (IdP) | 身份提供商 |
| Enterprise-managed authorization | 企业托管授权 |
| Model Context Protocol | 模型上下文协议 |
| zero-touch | 零操作 |
| access token | 访问令牌 |
| provision | 开通／配置 |
| revocation | 撤销 |
| deprovision | 取消授权 |
| custom connector | 自定义连接器 |
| open standard | 开放标准 |
