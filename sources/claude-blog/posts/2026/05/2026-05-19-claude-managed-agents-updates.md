---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents-updates
published_at: 2026-05-19
category: Agents
title_en: New in Claude Managed Agents: self-hosted sandboxes and MCP tunnels
title_zh: Claude 托管代理新功能：自托管沙箱与 MCP 隧道
source_intro_paragraphs: 3
source_image_count: 2
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/P7QG4Yx2Jp7NyRBaIQwarp7jV9dEq3XD"
---

# Claude 托管代理新功能：自托管沙箱与 MCP 隧道

> 来源：Claude Blog，2026-05-19
> 原文链接：https://claude.com/blog/claude-managed-agents-updates
> 分类：Agents

## 导语

从今天起，Claude 托管代理（Claude Managed Agents）可以在你掌控的沙箱中运行，并连接到你的私有模型上下文协议（Model Context Protocol，MCP）服务器。代理执行工具所在的沙箱，以及它所访问的服务，都运行在你企业既定的边界之内，受你的安全与运行时控制管辖。

## 核心要点

- 自托管沙箱（self-hosted sandboxes）让工具执行迁移到你自己配置的环境中，而代理循环仍保留在 Anthropic 的基础设施上。
- 敏感文件、依赖包和服务保留在你的基础设施内，文件与代码库不会外泄。
- 你可自带任意沙箱客户端，或使用 Cloudflare、Daytona、Modal、Vercel 等受支持的托管服务商。
- 你掌控计算资源：资源规格与运行时镜像由你设定，满足重计算任务的需要。
- MCP 隧道（MCP tunnels）让代理在不暴露到公网的情况下访问私有网络内的 MCP 服务器。
- 你部署的轻量级网关仅建立一条出站连接，无需入站防火墙规则、无公开端点，流量端到端加密。
- 在 Claude 平台上，自托管沙箱处于公开测试阶段，MCP 隧道处于研究预览阶段。

## 中文译文

从今天起，Claude 托管代理可以在你掌控的沙箱中运行，并连接到你的私有模型上下文协议（MCP）服务器。代理执行工具所在的沙箱，以及它所访问的服务，都运行在你企业既定的边界之内，受你的安全与运行时控制管辖。

沙箱可以运行在你自己的基础设施上，也可以借助 Cloudflare、Daytona、Modal 或 Vercel 等托管服务商，由它们为你处理计算与隔离。

在 Claude 平台上，自托管沙箱已进入公开测试（public beta），MCP 隧道处于研究预览（research preview）阶段（申请使用权限）。

### 让代理执行保持在你的边界之内

借助自托管沙箱，你可以将敏感文件、依赖包和服务保留在你自己的基础设施中，或交由托管沙箱服务商管理。负责编排、上下文管理和错误恢复的代理循环（agent loop）仍保留在 Anthropic 的基础设施上，而工具执行则迁移到你自己配置的环境中。

在你的边界之内，网络策略、审计日志和安全工具均已就位，文件与代码库不会离开。你还掌控着计算资源：资源规格和运行时镜像由你这边设定，因此执行重计算任务（例如长时间构建或图像生成）的代理能够获得任务所需的 CPU、内存和容量。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a0c965b35dd4ce814b00c56_Sandboxes_3%20(1).png)

### 选择你的沙箱客户端

自带任意你想要的沙箱客户端，或从我们支持的服务商之一开始：

- **Cloudflare** 使用微虚拟机（microVMs）和更轻量的隔离体（isolates）大规模运行沙箱。出站网络请求由你掌控，配有零信任密钥注入（zero-trust secrets injection）、可定制的代理（用于审计、重新路由或修改出站流量），以及通过 Cloudflare 网络连接内部服务的能力。Amplitude 正在 Managed Agents 和 Cloudflare 上构建 Design Agent，这是一个用于符合品牌的生产级 UI 与营销设计的内部工具，以获得更紧密的可观测性与控制。

- **Daytona** 沙箱是完整的可组合计算机，长时间运行且有状态。同一基本单元既能运行一次短暂的突发任务，也能运行工作数小时的代理。会话运行期间，沙箱可通过 SSH 或带认证的预览 URL 持续访问，也可以暂停并在完整保留状态的情况下恢复。Clay 的 GTM 工程代理 Sculptor 在 Managed Agents 和 Daytona 上自主构建、测试并监控工作流。

- **Modal** 是为 AI 工作负载打造的云平台，其沙箱与 Modal 的函数、存储和网络基本单元共享同一基础，为你提供构建生产级 AI 系统所需的一切。Modal 的自定义容器运行时可在任意镜像上实现亚秒级启动，扩展到数十万个并发沙箱，并按需提供 CPU 和 GPU 资源。

- **Vercel** 沙箱将虚拟机安全、VPC 对等连接（VPC peering）和自带云（bring your own cloud）结合在一起，并具备毫秒级启动时间。Managed Agents 处理模型、工具和会话状态，而 Vercel Sandbox 防火墙在网络边界注入凭证，使其永远不会进入沙箱。面向机构金融的 AI 平台 Rogo 正在 Managed Agents 和 Vercel Sandbox 上构建一个分析师代理，以安全地处理其专有数据。

### 连接到你私有网络内的服务

借助 MCP 隧道，你的代理可以访问私有网络内的 MCP 服务器，而无需将它们暴露到公共互联网。内部数据库、私有 API、知识库和工单系统都成为你的代理可以调用的工具。你部署的一个轻量级网关只建立一条出站连接——无需入站防火墙规则、无公开端点，且流量端到端加密。

MCP 隧道在 Managed Agents 和 Messages API 中受支持。MCP 隧道由组织管理员在 Claude Console 的工作区设置中进行管理。

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
