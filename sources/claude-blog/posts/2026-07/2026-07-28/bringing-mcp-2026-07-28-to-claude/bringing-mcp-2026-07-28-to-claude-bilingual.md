# 将 MCP 2026-07-28 引入 Claude

> Bringing MCP 2026-07-28 to Claude

> 来源：Claude Blog / Anthropic，2026-07-28
> 原文链接：https://claude.com/blog/bringing-mcp-2026-07-28-to-claude
> 分类：AI 基础设施 / 协议标准

## 核心要点

- Model Context Protocol 的第五个规范版本 MCP 2026-07-28 正式发布，核心变化包括转向无状态内核、强化授权机制以及让官方扩展正式毕业。
- MCP 近期月度 SDK 下载量突破 4 亿次，今年增长了 4 倍，已成为将 AI 智能体连接到应用程序的行业标准。
- 新规范将 MCP 从双向有状态协议转向请求/响应模型，使服务器可以部署在 serverless 和边缘基础设施上，并随采用率提升而扩展使用规模。
- MCP Apps 和 Tasks 现已纳入一套带版本管理的扩展框架，开发者无需改动核心协议即可添加交互式 UI 和长时间运行任务等能力。
- 授权机制已与生产环境的 OAuth 2.0 和 OIDC 部署保持一致，MCP 服务器因此可以无需变通方案直接对接 Entra 或 Okta 等企业身份系统。
- 自 beta 版本发布以来，生态系统中的众多公司已与 MCP 社区一起基于新规范进行构建。
- Claude 的连接器目录已收录超过 950 个 MCP 服务器，每天有数百万人在使用。
- MCP Apps 让服务器直接在对话中渲染交互式界面，用户可以看到连接器正在做什么并就地交互，无需切换标签页。
- 企业托管认证允许管理员通过身份提供商为整个组织一次性授权 MCP 连接器，用户凭现有 IdP 群组继承访问权限并在首次登录时自动连接。
- 面向连接器开发者的可观测性提供仪表板，用于跟踪采用情况、诊断错误和延迟，并按 Claude 产品细分使用量。
- MCP 隧道（研究预览）可将 Claude 连接到私有网络内的 MCP 服务器，无需入站防火墙规则、公共端点或源端 IP 白名单。
- 开发者可通过浏览规范与 SDK 开始使用，相关支持将陆续登陆各款 Claude 产品，MCP 服务器也可提交至 Claude 连接器目录。

## 正文

Model Context Protocol 的第五个规范版本 [MCP 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28)**，**今天正式发布。最新规范将 MCP 转向无状态内核，同时强化了授权机制，并使官方扩展正式毕业。相关支持正在 Claude 各产品中陆续上线。$  
/$

> The fifth spec release of the Model Context Protocol, [MCP 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28)**,** is live today. The latest spec moves MCP to a stateless core, while hardening authorization and graduating official extensions. Support is being rolled out across Claude products.$  
> /$

#### **MCP 的新变化**‍

> **What's new in MCP**‍

MCP 近期月度 SDK 下载量突破 4 亿次，今年增长了 4 倍，已成为将 AI 智能体连接到应用程序的行业标准。MCP 2026-07-28 是迄今为止最重要的规范发布之一：**$  
/$$  
/$无状态内核。** MCP 从双向有状态协议转向请求/响应模型。服务器现在可以部署在 serverless 和边缘基础设施上。这简化了为 Claude 构建 MCP 服务器的体验，并让它们随着采用率的提升而扩展使用规模。

> MCP recently surpassed 400M monthly SDK downloads, a 4x increase this year, and has become the industry standard for connecting AI agents to applications. MCP 2026-07-28 is one of the most significant spec releases to date:**$  
> /$$  
> /$Stateless core.** MCP moves from a bidirectional stateful protocol to a request/response model. Servers can now deploy on serverless and edge infrastructure. This simplifies the experience of building MCP servers for Claude and scaling their usage as they grow in adoption. 

**标准化扩展。** [MCP Apps](https://modelcontextprotocol.io/extensions/apps/overview) 和 [Tasks](https://modelcontextprotocol.io/extensions/tasks/overview) 现已在一套带版本管理的扩展框架下发布，为开发者提供了一条正式途径，无需改动核心协议即可添加交互式 UI 和长时间运行任务等能力。$  
/$$  
/$**身份验证加固。**授权机制现已与生产环境的 OAuth 2.0 和 OIDC 部署保持一致，因此 MCP 服务器无需变通方案即可对接 Entra 或 Okta 等企业身份系统。

> **Standardized extensions.** [MCP Apps](https://modelcontextprotocol.io/extensions/apps/overview) and [Tasks](https://modelcontextprotocol.io/extensions/tasks/overview) now ship under a versioned extensions framework, giving developers a formal path to add capabilities like interactive UIs and long-running work without changing the core protocol.$  
> /$$  
> /$**Auth hardening. **Authorization now aligns with production OAuth 2.0 and OIDC deployments, so MCP servers connect to enterprise identity systems like Entra or Okta without workarounds.

自 beta 版本以来，整个生态系统中的众多公司一直与 MCP 社区一起基于新规范进行构建：$  
/$

> Companies across the ecosystem have been building on the new spec alongside the MCP community since beta:$  
> /$

请参阅 [MCP 2026-07-28 发布公告](https://blog.modelcontextprotocol.io/posts/2026-07-28/)，了解新规范的完整细节。

> See the [MCP 2026-07-28 release announcement](https://blog.modelcontextprotocol.io/posts/2026-07-28/) for full details on the new spec.

#### ‍**推进 Claude 中的 MCP**‍

> ‍**Advancing MCP in Claude**‍

Claude 的[连接器目录](https://claude.ai/directory/connectors)现已收录超过 950 个 MCP 服务器，每天有数百万人在使用。今年我们发布了对新协议扩展的支持，以及让 MCP 更易于构建和部署的功能：$  
/$$  
/$[MCP Apps](https://claude.com/blog/interactive-tools-in-claude) 让服务器可以直接在对话中渲染交互式界面。用户能看到连接器正在做什么，并就地与之交互，无需切换标签页。$  
/$$  
/$[企业托管认证](https://claude.com/blog/enterprise-managed-auth)让管理员可以通过身份提供商为整个组织配置 MCP 连接器。管理员只需授权一次连接器，用户便可通过其现有的 IdP 群组继承访问权限，并在首次登录时自动连接：对终端用户而言是零操作配置。

> Claude now lists over 950 MCP servers in the [connectors directory](https://claude.ai/directory/connectors), used by millions of people every day. This year we shipped support for new protocol extensions alongside features that make MCP easier to build on and deploy:$  
> /$$  
> /$[MCP Apps](https://claude.com/blog/interactive-tools-in-claude) let servers render interactive UI directly in the conversation. Users can see what a connector is doing and work with it inline, without switching tabs.$  
> /$$  
> /$[Enterprise-managed auth](https://claude.com/blog/enterprise-managed-auth) lets admins provision MCP connectors for their whole organization through their identity provider. Admins authorize a connector once, users inherit access through their existing IdP groups, and it's connected on first login: zero-touch setup for the end user.

[面向连接器开发者的可观测性](https://claude.com/blog/observability-for-developers-building-connectors)为我们目录中已发布的连接器提供了一个仪表板，展示它们在各个 Claude 产品界面上的表现。开发者可以用它来跟踪采用情况、诊断错误和延迟，并按产品细分使用量。

> [Observability for developers building connectors](https://claude.com/blog/observability-for-developers-building-connectors) gives published connectors in our directory a dashboard showing how they perform across Claude product surfaces. Developers can use it to track adoption, diagnose errors and latency, and break down usage by product.

[MCP 隧道（研究预览）](https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview)可将 Claude 连接到私有网络内部的 MCP 服务器，而无需将其暴露到公共互联网。团队可以把内部工具接入 Claude，不需要入站防火墙规则，不需要公共端点，也不需要在源端做 IP 白名单。$  
/$$  
/$2026-07-28 版本中的无状态内核、标准化扩展和强化的认证机制，将帮助开发者把更多应用接入 Claude，并带来摩擦更低、更一致的终端用户体验。我们将继续与社区一起投入 MCP 这一开放标准，也将继续投入那些让 MCP 在生产环境中更易用、更有效的 Claude 功能。

> [MCP tunnels (research preview)](https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview) connect Claude to MCP servers inside a private network without exposing them to the public internet. Teams can bring internal tools to Claude with no inbound firewall rules, no public endpoints, and no IP allowlisting on the origin.$  
> /$$  
> /$The stateless core, standardized extensions, and hardened auth in 2026-07-28 will help developers bring more applications to Claude, with a lower-friction, more consistent end-user experience. We'll continue investing in MCP as an open standard alongside the community, and in the Claude features that make MCP more accessible and effective in production.

#### ‍**开始使用**

> ‍**Getting started**

**‍**浏览[规范](https://modelcontextprotocol.io/specification/2026-07-28/)和 [SDK](https://modelcontextprotocol.io/docs/sdk) 即可开始使用。相关支持即将陆续登陆各款 Claude 产品。如果你打算将自己的 MCP 服务器提交到 Claude 的[连接器目录](https://claude.ai/directory/connectors)，可以在[此处](https://claude.com/docs/connectors/building/submission)了解更多信息。

> **‍**Explore the [spec](https://modelcontextprotocol.io/specification/2026-07-28/) and [SDKs](https://modelcontextprotocol.io/docs/sdk) to get started. Support is rolling out across Claude products soon. If you’re planning to submit your MCP server to Claude’s [connectors directory](https://claude.ai/directory/connectors), you can learn more [here](https://claude.com/docs/connectors/building/submission).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Model Context Protocol (MCP) | 模型上下文协议 | 用于将 AI 智能体连接到外部应用与数据源的开放协议标准。 |
| stateless core | 无状态内核 | 协议核心不再维持会话状态，改以独立的请求/响应交互完成通信。 |
| request/response model | 请求/响应模型 | 客户端发起请求、服务器返回结果的单向交互模式，无需长连接。 |
| serverless | 无服务器 | 由平台按需分配运行资源、开发者无需管理服务器的部署形态。 |
| edge infrastructure | 边缘基础设施 | 部署在靠近用户的网络边缘节点上的计算与分发设施。 |
| MCP Apps | MCP Apps（MCP 应用扩展） | 官方扩展，允许 MCP 服务器在对话中直接渲染交互式界面。 |
| Tasks | Tasks（任务扩展） | 官方扩展，为 MCP 提供长时间运行任务的标准化支持。 |
| versioned extension framework | 带版本管理的扩展框架 | 为协议扩展提供独立版本演进路径的机制，避免改动核心协议。 |
| OAuth 2.0 | OAuth 2.0 | 广泛使用的开放授权标准，用于第三方应用获取受限访问权限。 |
| OIDC (OpenID Connect) | OpenID Connect | 构建在 OAuth 2.0 之上的身份认证层，用于验证用户身份。 |
| IdP (identity provider) | 身份提供商 | 集中管理并验证用户身份、向应用签发凭据的服务。 |
| enterprise managed auth | 企业托管认证 | 由管理员通过身份提供商为整个组织统一配置连接器授权的方式。 |
| connector directory | 连接器目录 | Claude 中收录可供用户启用的 MCP 服务器的公开目录。 |
| observability | 可观测性 | 通过指标、错误与延迟数据了解系统运行状况的能力。 |
| MCP tunnels | MCP 隧道 | 在不暴露公共端点的前提下，将 Claude 连接到私有网络内 MCP 服务器的通道。 |
