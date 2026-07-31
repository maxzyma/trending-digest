# 将 MCP 2026-07-28 引入 Claude

> Bringing MCP 2026-07-28 to Claude

> 来源：Claude Blog / Anthropic，2026-07-28
> 原文链接：https://claude.com/blog/bringing-mcp-2026-07-28-to-claude
> 分类：AI 工程 / 智能体协议

## 核心要点

- MCP 2026-07-28 是模型上下文协议的第五个规范版本，于今日正式发布。
- MCP 的 SDK 下载量近期突破每月 4 亿次，今年增长了 4 倍，已成为将 AI 智能体连接到应用程序的行业标准。
- 新规范将 MCP 从双向有状态协议转向请求/响应模型，使服务器可以部署在无服务器和边缘基础设施上。
- MCP Apps 与 Tasks 被纳入一套带版本管理的扩展框架，开发者无需改动核心协议即可添加交互式 UI 和长时间运行任务等能力。
- 授权机制已与生产环境中的 OAuth 2.0 和 OIDC 部署保持一致，MCP 服务器可直接接入 Entra、Okta 等企业身份系统而无需变通方案。
- 自 beta 版本以来，生态中的众多公司已与 MCP 社区一同基于新规范进行构建。
- Claude 的连接器目录已收录超过 950 个 MCP 服务器，每天有数百万人使用。
- MCP Apps 让服务器直接在对话中渲染交互式界面，用户可在对话内查看连接器的行为并与之协作，无需切换标签页。
- 企业托管认证允许管理员通过身份提供商为整个组织一次性预配 MCP 连接器，用户凭现有 IdP 群组继承访问权限并在首次登录时自动完成连接。
- 面向连接器开发者的可观测性提供仪表板，用于跟踪采用情况、诊断错误与延迟并按产品细分使用情况；MCP 隧道（研究预览版）则让 Claude 连接私有网络内的服务器，无需公开端点或配置入站防火墙规则。

## 正文

模型上下文协议（Model Context Protocol）的第五个规范版本 [MCP 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28)**，**今日正式发布。最新规范将 MCP 转向无状态核心，同时强化了授权机制，并将官方扩展升级为正式功能。相关支持正在 Claude 各产品中陆续上线。  


> The fifth spec release of the Model Context Protocol, [MCP 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28)**,** is live today. The latest spec moves MCP to a stateless core, while hardening authorization and graduating official extensions. Support is being rolled out across Claude products.  

#### **MCP 有哪些新变化**‍

> **What's new in MCP**‍

MCP 近期突破了每月 4 亿次 SDK 下载量，今年增长了 4 倍，并已成为将 AI 智能体连接到应用程序的行业标准。MCP 2026-07-28 是迄今为止最重要的规范版本之一：**  
  
无状态内核。** MCP 从双向有状态协议转向请求/响应模型。服务器现在可以部署在无服务器和边缘基础设施上。这简化了为 Claude 构建 MCP 服务器的体验，并能随着采用率的提升而扩展其使用规模。 

> MCP recently surpassed 400M monthly SDK downloads, a 4x increase this year, and has become the industry standard for connecting AI agents to applications. MCP 2026-07-28 is one of the most significant spec releases to date:**  
>
> Stateless core.** MCP moves from a bidirectional stateful protocol to a request/response model. Servers can now deploy on serverless and edge infrastructure. This simplifies the experience of building MCP servers for Claude and scaling their usage as they grow in adoption. 

**标准化扩展。** [MCP Apps](https://modelcontextprotocol.io/extensions/apps/overview) 和 [Tasks](https://modelcontextprotocol.io/extensions/tasks/overview) 现已纳入一套带版本管理的扩展框架，为开发者提供了一条正式路径，无需改动核心协议即可添加交互式 UI、长时间运行任务等能力。  
  
**认证加固。**授权机制现已与生产环境中的 OAuth 2.0 和 OIDC 部署保持一致，因此 MCP 服务器无需变通方案即可接入 Entra 或 Okta 等企业身份系统。

> **Standardized extensions.** [MCP Apps](https://modelcontextprotocol.io/extensions/apps/overview) and [Tasks](https://modelcontextprotocol.io/extensions/tasks/overview) now ship under a versioned extensions framework, giving developers a formal path to add capabilities like interactive UIs and long-running work without changing the core protocol.  
>
> **Auth hardening. **Authorization now aligns with production OAuth 2.0 and OIDC deployments, so MCP servers connect to enterprise identity systems like Entra or Okta without workarounds.

自 beta 版本以来，整个生态中的众多公司已与 MCP 社区一同基于新规范进行构建：  


> Companies across the ecosystem have been building on the new spec alongside the MCP community since beta:  

有关新规范的完整细节，请参阅 [MCP 2026-07-28 发布公告](https://blog.modelcontextprotocol.io/posts/2026-07-28/)。

> See the [MCP 2026-07-28 release announcement](https://blog.modelcontextprotocol.io/posts/2026-07-28/) for full details on the new spec.

#### ‍**推进 Claude 中的 MCP**‍

> ‍**Advancing MCP in Claude**‍

Claude 的[连接器目录](https://claude.ai/directory/connectors)中现已收录超过 950 个 MCP 服务器，每天有数百万人在使用。今年我们发布了对新协议扩展的支持，以及一系列让 MCP 更易于构建和部署的功能：  
  
[MCP Apps](https://claude.com/blog/interactive-tools-in-claude) 让服务器可以直接在对话中渲染交互式界面。用户能够看到连接器正在做什么，并在对话内直接与之协作，无需切换标签页。  
  
[企业托管认证](https://claude.com/blog/enterprise-managed-auth)让管理员可以通过其身份提供商为整个组织预配 MCP 连接器。管理员只需授权连接器一次，用户便可通过其现有的 IdP 群组继承访问权限，并在首次登录时自动完成连接：对终端用户而言是零操作配置。

> Claude now lists over 950 MCP servers in the [connectors directory](https://claude.ai/directory/connectors), used by millions of people every day. This year we shipped support for new protocol extensions alongside features that make MCP easier to build on and deploy:  
>
> [MCP Apps](https://claude.com/blog/interactive-tools-in-claude) let servers render interactive UI directly in the conversation. Users can see what a connector is doing and work with it inline, without switching tabs.  
>
> [Enterprise-managed auth](https://claude.com/blog/enterprise-managed-auth) lets admins provision MCP connectors for their whole organization through their identity provider. Admins authorize a connector once, users inherit access through their existing IdP groups, and it's connected on first login: zero-touch setup for the end user.

[面向连接器开发者的可观测性](https://claude.com/blog/observability-for-developers-building-connectors)为我们目录中已发布的连接器提供了一个仪表板，展示它们在各个 Claude 产品界面上的表现。开发者可以用它来跟踪采用情况、诊断错误和延迟，并按产品细分使用情况。

> [Observability for developers building connectors](https://claude.com/blog/observability-for-developers-building-connectors) gives published connectors in our directory a dashboard showing how they perform across Claude product surfaces. Developers can use it to track adoption, diagnose errors and latency, and break down usage by product.

[MCP 隧道（研究预览版）](https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview)可将 Claude 连接到私有网络内部的 MCP 服务器，而无需将其暴露到公共互联网。团队可以把内部工具接入 Claude，无需配置入站防火墙规则、无需公开端点，也无需在源站上做 IP 白名单。  
  
2026-07-28 版本中的无状态内核、标准化扩展和强化的身份认证，将帮助开发者把更多应用接入 Claude，并带来摩擦更少、更一致的终端用户体验。我们将继续与社区一同投入 MCP 这一开放标准的建设，并持续投入那些让 MCP 在生产环境中更易用、更有效的 Claude 功能。

> [MCP tunnels (research preview)](https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview) connect Claude to MCP servers inside a private network without exposing them to the public internet. Teams can bring internal tools to Claude with no inbound firewall rules, no public endpoints, and no IP allowlisting on the origin.  
>
> The stateless core, standardized extensions, and hardened auth in 2026-07-28 will help developers bring more applications to Claude, with a lower-friction, more consistent end-user experience. We'll continue investing in MCP as an open standard alongside the community, and in the Claude features that make MCP more accessible and effective in production.

#### ‍**开始使用**

> ‍**Getting started**

**‍**探索 [规范](https://modelcontextprotocol.io/specification/2026-07-28/) 和 [SDK](https://modelcontextprotocol.io/docs/sdk) 即可上手。相关支持即将陆续覆盖各款 Claude 产品。如果你打算把自己的 MCP 服务器提交到 Claude 的 [连接器目录](https://claude.ai/directory/connectors)，可以在[这里](https://claude.com/docs/connectors/building/submission)了解更多信息。

> **‍**Explore the [spec](https://modelcontextprotocol.io/specification/2026-07-28/) and [SDKs](https://modelcontextprotocol.io/docs/sdk) to get started. Support is rolling out across Claude products soon. If you’re planning to submit your MCP server to Claude’s [connectors directory](https://claude.ai/directory/connectors), you can learn more [here](https://claude.com/docs/connectors/building/submission).

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Model Context Protocol (MCP) | 模型上下文协议 | 用于将 AI 智能体与外部应用、数据和工具连接起来的开放标准协议。 |
| stateless core | 无状态内核 | 协议核心不在服务端保留会话状态，每次交互都是独立的请求/响应。 |
| request/response model | 请求/响应模型 | 客户端发起请求、服务器返回响应的单向交互模式，区别于双向持久连接。 |
| serverless | 无服务器 | 由平台按需分配运行实例、开发者无需管理服务器的部署形态。 |
| edge infrastructure | 边缘基础设施 | 靠近用户网络边缘部署的计算资源，用于降低访问延迟。 |
| MCP Apps | MCP Apps（MCP 应用扩展） | 允许 MCP 服务器直接在对话界面中渲染交互式界面的官方扩展。 |
| Tasks | Tasks（任务扩展） | 为 MCP 提供长时间运行任务能力的官方扩展。 |
| versioned extension framework | 带版本管理的扩展框架 | 为协议附加能力提供独立版本化演进路径的机制，避免改动核心协议。 |
| OAuth 2.0 | OAuth 2.0 | 被广泛采用的授权框架标准，用于向第三方应用委托受限访问权限。 |
| OIDC (OpenID Connect) | OpenID Connect | 构建在 OAuth 2.0 之上的身份认证层，用于验证用户身份。 |
| IdP (Identity Provider) | 身份提供商 | 负责存储和校验用户身份并向应用签发凭证的系统，如 Entra、Okta。 |
| enterprise managed auth | 企业托管认证 | 由管理员通过身份提供商为组织统一授权和预配连接器的认证方式。 |
| connector directory | 连接器目录 | Claude 中集中收录并分发可用 MCP 服务器的官方目录。 |
| observability | 可观测性 | 通过指标、错误和延迟数据洞察系统运行状况的能力。 |
| MCP tunnels | MCP 隧道 | 在不暴露公共端点的前提下将 Claude 连接到私有网络内 MCP 服务器的通道机制。 |
