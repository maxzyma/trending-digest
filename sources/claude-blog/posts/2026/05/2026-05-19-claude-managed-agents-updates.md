---
source: claude-blog
source_url: https://claude.com/blog/claude-managed-agents-updates
published_at: 2026-05-19
category: Agents
title_en: New in Claude Managed Agents: self-hosted sandboxes and MCP tunnels
title_zh: Claude 托管智能体新功能：自托管沙箱与 MCP 隧道
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/ZX6GRezwJl7D0RwpIg3ObO5jVdqbropQ"
---

# Claude 托管智能体新功能：自托管沙箱与 MCP 隧道

> 来源：Claude Blog，2026-05-19
> 原文链接：https://claude.com/blog/claude-managed-agents-updates
> 分类：Agents

## 核心要点

- Claude 托管智能体（Claude Managed Agents）现在可以在你自己掌控的沙箱（sandbox）中运行，并连接到你私有的模型上下文协议（Model Context Protocol，MCP）服务器。
- 智能体的工具执行迁移到你配置的环境中，而负责编排、上下文管理与错误恢复的智能体循环仍保留在 Anthropic 的基础设施上。
- 沙箱可运行在你自己的基础设施上，或借助 Cloudflare、Daytona、Modal、Vercel 等托管服务商处理计算与隔离。
- 通过 MCP 隧道（MCP tunnels），智能体可以访问私有网络内的 MCP 服务器，而无需将其暴露在公共互联网上。
- 在 Claude 平台上，自托管沙箱已进入公开测试版（public beta），MCP 隧道处于研究预览阶段（research preview）。

## 中文译文

从今天起，Claude 托管智能体可以在你掌控的沙箱中运行，并连接到你私有的模型上下文协议（MCP）服务器。无论是智能体执行工具的沙箱，还是它所访问的服务，都运行在你企业既有的边界之内，受你的安全与运行时控制约束。

沙箱可以运行在你自己的基础设施上，也可以借助 Cloudflare、Daytona、Modal 或 Vercel 等托管服务商，由它们为你处理计算与隔离。

在 Claude 平台上，自托管沙箱（self-hosted sandboxes）已进入公开测试版，MCP 隧道处于研究预览阶段（[申请访问](https://claude.com/blog/claude-managed-agents-updates)）。

### 将智能体执行保持在你的边界内

借助自托管沙箱，你可以将敏感文件、软件包和服务保留在自己的基础设施或托管沙箱服务商处。负责编排、上下文管理和错误恢复的智能体循环（agent loop）仍保留在 Anthropic 的基础设施上，而工具执行则迁移到你自己配置的环境中。

在你的边界内，网络策略、审计日志和安全工具已经就位，文件和代码仓库不会外流。你也掌控计算资源：资源规格和运行时镜像由你这一侧设定，因此承担长时间构建或图像生成等计算密集型工作的智能体，能够获得任务所需的 CPU、内存和容量。

### 选择你的沙箱客户端

你可以接入任意你想用的沙箱客户端，也可以从我们支持的服务商之一开始：

- **Cloudflare** 使用微虚拟机（microVMs）和更轻量的隔离单元（isolates）大规模运行沙箱。出站网络请求由你掌控，具备零信任密钥注入、可定制的代理（用于审计、重新路由或修改出口流量），以及通过 Cloudflare 网络连接内部服务的能力。Amplitude 正在托管智能体与 Cloudflare 之上构建 Design Agent——一款用于品牌一致的生产级 UI 和营销设计的内部工具，以获得更紧密的可观测性与控制力。

- **Daytona** 沙箱是完整、可组合的计算机，长时间运行且具备状态。同一种原语既能运行一次短暂的突发任务，也能运行一个工作数小时的智能体。在会话进行期间，沙箱可通过 SSH 或带认证的预览 URL 持续访问，也可以暂停后再恢复，且完整保留状态。Clay 的 GTM 工程智能体 Sculptor 在托管智能体与 Daytona 之上自主构建、测试和监控工作流。

- **Modal** 是一个为 AI 工作负载打造的云平台，其沙箱与 Modal 的函数、存储和网络原语共享同一基础，为你提供构建生产级 AI 系统所需的一切。Modal 的自定义容器运行时在任意镜像上都能实现亚秒级启动，可扩展至数十万个并发沙箱，并按需提供 CPU 和 GPU 资源。

- **Vercel** 沙箱将虚拟机安全、VPC 对等连接（VPC peering）和自带云（bring your own cloud）与毫秒级启动时间相结合。托管智能体负责处理模型、工具和会话状态，而 Vercel 沙箱防火墙在网络边界处注入凭据，使其永远不会进入沙箱。面向机构金融的 AI 平台 Rogo 正在托管智能体与 Vercel 沙箱之上构建一个分析师智能体，以安全处理其专有数据。

### 连接到私有网络内的服务

借助 MCP 隧道，你的智能体可以访问私有网络内的 MCP 服务器，而无需将其暴露在公共互联网上。内部数据库、私有 API、知识库和工单系统都将成为智能体可以调用的工具。你部署一个轻量级网关，它只发起一个出站连接——无需入站防火墙规则，无需公共端点，且流量端到端加密。

MCP 隧道在托管智能体和消息 API（Messages API）中均受支持。MCP 隧道由组织管理员在 Claude Console 的工作区设置中进行管理。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| sandbox | 沙箱 |
| self-hosted sandboxes | 自托管沙箱 |
| Model Context Protocol (MCP) | 模型上下文协议 |
| MCP tunnels | MCP 隧道 |
| agent loop | 智能体循环 |
| public beta | 公开测试版 |
| research preview | 研究预览 |
| microVMs | 微虚拟机 |
| isolates | 隔离单元 |
| zero-trust secrets injection | 零信任密钥注入 |
| egress | 出口流量 |
| VPC peering | VPC 对等连接 |
| bring your own cloud | 自带云 |
| Messages API | 消息 API |
| runtime image | 运行时镜像 |
