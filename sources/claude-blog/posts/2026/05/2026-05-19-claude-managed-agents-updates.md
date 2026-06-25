---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents-updates
published_at: 2026-05-19
category: Agents
title_en: New in Claude Managed Agents: self-hosted sandboxes and MCP tunnels
title_zh: Claude 托管代理新功能：自托管沙箱与 MCP 隧道
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 3
source_image_count: 2
---

# Claude 托管代理新功能：自托管沙箱与 MCP 隧道

> 🌏︎ • New in Claude Managed Agents: self-hosted sandboxes and MCP tunnels

> • 来源：Claude Blog，2026-05-19
> • 原文链接：https://claude.com/blog/claude-managed-agents-updates
> • 分类：Agents

## 核心要点

- 自托管沙箱（self-hosted sandboxes）让工具执行迁移到你自己配置的环境中，而代理循环仍保留在 Anthropic 的基础设施上。
- 敏感文件、依赖包和服务保留在你的基础设施内，文件与代码库不会外泄。
- 你可自带任意沙箱客户端，或使用 Cloudflare、Daytona、Modal、Vercel 等受支持的托管服务商。
- 你掌控计算资源：资源规格与运行时镜像由你设定，满足重计算任务的需要。
- MCP 隧道（MCP tunnels）让代理在不暴露到公网的情况下访问私有网络内的 MCP 服务器。
- 你部署的轻量级网关仅建立一条出站连接，无需入站防火墙规则、无公开端点，流量端到端加密。
- 在 Claude 平台上，自托管沙箱处于公开测试阶段，MCP 隧道处于研究预览阶段。

## 正文

从今天起，Claude 托管代理（Claude Managed Agents）可以在你掌控的沙箱中运行，并连接到你的私有模型上下文协议（Model Context Protocol，MCP）服务器。代理执行工具所在的沙箱，以及它所访问的服务，都运行在你企业既定的边界之内，受你的安全与运行时控制管辖。

> 🌏︎ Starting today, Claude Managed Agents can operate in a sandbox you control and connect to your private Model Context Protocol (MCP) servers. Both the sandbox where an agent executes tools and the services it reaches run within the established boundaries of your enterprise, under your security and runtime controls.

从今天起，Claude 托管智能体（Claude Managed Agents）可以在你控制的沙箱中运行，并连接到你的私有模型上下文协议（MCP）服务器。智能体执行工具所在的沙箱，以及它访问的服务，都运行在你企业既有的边界内，受你的安全与运行时控制约束。

> 🌏︎ Starting today, Claude Managed Agents can operate in a sandbox you control and connect to your private Model Context Protocol (MCP) servers. Both the sandbox where an agent executes tools and the services it reaches run within the established boundaries of your enterprise, under your security and runtime controls.

沙箱可以运行在你自己的基础设施上，也可以借助 Cloudflare、Daytona、Modal 或 Vercel 等托管服务商，由它们为你处理计算与隔离。

> 🌏︎ The sandbox runs on your own infrastructure, or with managed providers like Cloudflare , Daytona , Modal , or Vercel to handle the compute and isolation for you.

在 Claude 平台上，自托管沙箱已进入公开测试（public beta），MCP 隧道（MCP tunnels）处于研究预览阶段（可申请访问）。

> 🌏︎ On the Claude Platform, self-hosted sandboxes is available in public beta and MCP tunnels in research preview ( request access ).

### 让智能体执行保持在你的边界之内

> Keep agent execution within your perimeter

使用自托管沙箱（self-hosted sandbox），你可以把敏感文件、软件包和服务保留在自己的基础设施中，或交由托管沙箱提供商管理。负责编排、上下文管理和错误恢复的智能体循环（agent loop）仍运行在 Anthropic 的基础设施上，而工具执行则转移到你自己配置的环境中。

> 🌏︎ With self-hosted sandboxes, you keep sensitive files, packages, and services in your own infrastructure or with a managed sandbox provider. The agent loop that handles orchestration, context management, and error recovery stays on Anthropic’s infrastructure, while tool execution moves to your own configured environment.

在你的边界之内，网络策略、审计日志和安全工具已经就位，文件和代码仓库也不会外流。你还掌控算力：资源规格和运行时镜像都由你这一侧设定，因此运行长时间构建或图像生成等算力密集型工作的智能体能够获得任务所需的 CPU、内存和容量。

> 🌏︎ Inside your perimeter, network policies, audit logging, and security tooling are already in place, and files and repositories don't leave. You also control the compute: resource sizing and the runtime image are set on your side, so agents running compute-heavy work such as long builds or image generation get the CPU, memory, and capacity the task needs.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a0c965b35dd4ce814b00c56_Sandboxes_3%20(1).png)

### 选择你的沙箱客户端

> Choose your sandbox client

你可以接入任意你想用的沙箱客户端，也可以从我们支持的服务商之一开始：

> 🌏︎ Bring any sandbox client you want, or start with one of our supported providers:

- Cloudflare 使用微虚拟机（microVM）和更轻量的隔离体（isolate）大规模运行沙箱。出站网络请求由你掌控，支持零信任密钥注入、可定制的代理以审计、重新路由或修改出口流量，并能通过 Cloudflare 网络连接到内部服务。Amplitude 正在 Managed Agents 和 Cloudflare 上构建 Design Agent，这是一款用于符合品牌规范的生产级 UI 和营销设计的内部工具，以获得更严密的可观测性和控制力。
- Daytona 沙箱是完整、可组合的计算机，长时间运行且有状态。同一套基础组件既能处理一次快速突发任务，也能支撑工作数小时的智能体。会话通过 SSH 或经过身份验证的预览 URL 运行时，沙箱保持可访问，也可以在完整保留状态的情况下暂停和恢复。Clay 的 GTM 工程智能体 Sculptor，在 Managed Agents 和 Daytona 上自主构建、测试和监控工作流。
- Modal 是为 AI 工作负载打造的云平台，其沙箱与 Modal 的函数、存储和网络基础组件共享同一基础，为你构建生产级 AI 系统提供所需的一切。Modal 的自定义容器运行时可在任意镜像上实现亚秒级启动，能扩展到数十万个并发沙箱，并按需提供 CPU 和 GPU 资源。
- Vercel 沙箱将虚拟机安全性、VPC 对等连接（VPC peering）和自带云能力相结合，并具备毫秒级启动时间。Managed Agents 负责处理模型、工具和会话状态，而 Vercel Sandbox 防火墙在网络边界注入凭证，使其永不进入沙箱。Rogo 是一个面向机构金融的 AI 平台，正在 Managed Agents 和 Vercel Sandbox 上构建一款分析师智能体，以安全地处理其专有数据。

> 🌏︎ • Cloudflare runs sandboxes at scale using microVMs and lighter weight isolates. Outbound network requests are in your control with zero-trust secrets injection, customizable proxies to audit, reroute, or modify egress, and the ability to connect to internal services over Cloudflare's network. Amplitude is building Design Agent, an internal tool for on-brand production UI and marketing design, on Managed Agents and Cloudflare for tighter observability and control.

> • Daytona sandboxes are full composable computers, long-running and stateful. The same primitive runs a quick burst or an agent that works for hours. The sandbox stays accessible while a session runs over SSH or an authenticated preview URL, or can be paused and restored with full state preserved. Clay’s GTM engineering agent, Sculptor, builds, tests, and monitors workflows autonomously on Managed Agents and Daytona.

> • Modal is a cloud platform built for AI workloads, where sandboxes share the same foundation as Modal's functions, storage, and networking primitives, giving you everything you need to build production AI systems. Modal's custom container runtime delivers sub-second startup on any image, scales to hundreds of thousands of concurrent sandboxes, and gives you CPU and GPU resources on demand.

> • Vercel sandboxes combine VM security, VPC peering, and bring your own cloud with millisecond startup time. Managed Agents handles the model, tools, and session state, while the Vercel Sandbox firewall injects credentials at the network boundary so they never enter the sandbox. Rogo , an AI platform for institutional finance, is building an analyst agent on Managed Agents and Vercel Sandbox to handle their proprietary data securely.

### 连接到私有网络内的服务

> Connect to services within your private network

借助 MCP 隧道（MCP tunnels），你的智能体（agent）无需将私有网络内的 MCP 服务器暴露到公共互联网，即可访问它们。内部数据库、私有 API、知识库和工单系统都成为智能体可以调用的工具。你部署的一个轻量级网关只发起单向的出站连接，无需入站防火墙规则，无需公共端点，流量端到端加密。

> 🌏︎ With MCP tunnels , your agents reach MCP servers inside your private network without exposing them to the public internet. Internal databases, private APIs, knowledge bases, and ticketing systems become tools your agents can call. A lightweight gateway you deploy makes a single outbound connection, no inbound firewall rules, no public endpoints, and traffic encrypted end to end.

MCP 隧道在受管智能体（Managed Agents）和 Messages API 中均受支持。MCP 隧道由组织管理员在 Claude 控制台（Claude Console）的工作区设置中管理。

> 🌏︎ MCP tunnels is supported in Managed Agents and the Messages API. MCP tunnels is managed from workspace settings within the Claude Console by organization admins.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a0b4fdc9749bb31acafa95b_MCP%20tunnel%20(1).png)

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管代理 |
| self-hosted sandboxes | 自托管沙箱 |
| MCP tunnels | MCP 隧道 |
| Model Context Protocol (MCP) | 模型上下文协议 |
| agent loop | 代理循环 |
| public beta | 公开测试 |
| research preview | 研究预览 |
| microVMs | 微虚拟机 |
| isolates | 隔离体 |
| zero-trust secrets injection | 零信任密钥注入 |
| egress | 出站流量 |
| VPC peering | VPC 对等连接 |
| bring your own cloud | 自带云 |
| gateway | 网关 |
| end to end | 端到端 |
