---
source: claude-blog
source_url: https://claude.com/blog/introducing-the-claude-apps-gateway
published_at: 2026-06-29
category: Product announcements
title_en: Introducing the Claude apps gateway for Amazon Bedrock and Google Cloud
title_zh: 面向 Amazon Bedrock 与 Google Cloud 推出 Claude 应用网关
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 1
source_image_count: 0
---

# 面向 Amazon Bedrock 与 Google Cloud 推出 Claude 应用网关

> Introducing the Claude apps gateway for Amazon Bedrock and Google Cloud

> 来源：Claude Blog，2026-06-29
> 原文链接：https://claude.com/blog/introducing-the-claude-apps-gateway
> 分类：Product announcements

## 核心要点

- 网关作为自托管控制平面，统一提供企业单点登录、集中策略、基于角色的访问控制和按用户成本归集。
- 以单个无状态容器形式部署在 Linux 上，后端由 PostgreSQL 数据库支撑，开发者的纳入与移除只需在身份提供方中增删账号。
- 网关与客户端由 Anthropic 一同构建并随同一个 claude 二进制文件发布，登录流程感知网关，客户端在登录时自动应用受管设置。
- 身份方面充当 OpenID Connect 依赖方，对接 Google Workspace、Microsoft Entra ID、Okta 等兼容提供方，并签发短期会话，开发者机器上不留长期密钥。
- 遥测数据通过 OTLP 转发到用户自行配置的收集器，由用户掌控网络与留存周期；推理可路由至 Claude API、Amazon Bedrock 或 Google Cloud，并支持可选的多提供方故障转移。
- 支持按组织、群组或用户设置每日、每周、每月的开销上限。
- 除非配置使用 Claude API，否则网关不会向 Anthropic 发送推理流量或使用数据；其所用协议同时公开发布，供其他网关开发者实现相同功能。

## 正文

今天，我们推出面向 Amazon Bedrock 与 Google Cloud 的 Claude 应用网关。此前，在这些平台上运行 Claude Code 意味着要为每位开发者单独配置云凭证、手动将设置推送到每台笔记本电脑，并搭建独立工具来查看每位开发者的开销。该网关是一个自托管的控制平面，为 Claude Code 提供企业级单点登录、集中实施的策略、基于角色的访问控制，以及按用户归集的成本核算。

> Today, we're introducing the Claude apps gateway for Amazon Bedrock and Google Cloud. Previously, running Claude Code on these platforms has meant provisioning a cloud credential per developer, manually pushing settings to every laptop, and standing up separate tooling to see per-developer spend. The gateway is a self-hosted control plane that gives you corporate SSO login, centrally enforced policy, role-based access, and per-user cost attribution for Claude Code.

今天，我们推出面向 Amazon Bedrock 和 Google Cloud 的 Claude 应用网关（Claude apps gateway）。此前，在这些平台上运行 Claude Code 意味着要为每位开发者分配一份云凭据、手动把配置推送到每台笔记本电脑，并单独搭建工具来查看每位开发者的支出。该网关是一个自托管的控制平面，为 Claude Code 提供企业级单点登录（SSO）、集中实施的策略、基于角色的访问控制，以及按用户的成本归因。

> Today, we're introducing the Claude apps gateway for Amazon Bedrock and Google Cloud. Previously, running Claude Code on these platforms has meant provisioning a cloud credential per developer, manually pushing settings to every laptop, and standing up separate tooling to see per-developer spend. The gateway is a self-hosted control plane that gives you corporate SSO login, centrally enforced policy, role-based access, and per-user cost attribution for Claude Code.

### 部署网关

> Deploying the gateway

该网关以单个无状态容器的形式运行，部署在 Linux 上，并由 PostgreSQL 数据库支撑。它持有你的上游凭证、对照你的身份提供方（identity provider）验证开发者身份、分发并强制执行托管设置（managed settings），并将各用户的使用量上报给你所运营的收集器（collector）。接纳一名开发者意味着把他添加到你的身份提供方（IdP），停用则意味着把他移除。

> The gateway is run as a single stateless container deployed on Linux and backed by a PostgreSQL database. It holds your upstream credential, authenticates developers against your identity provider, distributes and enforces managed settings, and reports per-user usage to a collector you operate. Onboarding a developer means adding them to your Identity Provider (IdP). Offboarding means removing them.

该网关由 Anthropic 构建并随你的开发者已经安装的同一个 claude 二进制文件一起发布，因此你可以在自己的基础设施上以一个无状态容器运行它。由于网关和客户端是一起构建的，/login 流程能够感知网关，客户端会在登录时自动应用托管设置，策略也会在每个请求上被一致地强制执行。

> The gateway is built and shipped by Anthropic inside the same claude binary your developers already install, so you can run it in one stateless container on your infrastructure. Because the gateway and the client are built together, the /login flow is gateway-aware, the client applies managed settings automatically at sign-in, and policy is enforced consistently on every request.

### 网关如何工作

> How the gateway works

该网关负责处理：

> The gateway handles:

- 身份认证。它作为 OpenID Connect（OIDC）依赖方，对接 Google Workspace、Microsoft Entra ID、Okta 或任何符合标准的 OIDC 提供方，并签发短期会话。开发者机器上不会留存长期密钥。
- 策略。你可以在服务端一次性定义托管设置，客户端在登录时接收策略，网关在每次请求时强制执行。你可以集中调整允许的模型和默认设置。
- 遥测。客户端为每次请求标记一项用量指标，网关通过 OTLP 将其转发到你配置的收集器，运行在你的网络中并遵循你的留存周期。
- 路由。网关持有你的上游凭证，并将推理请求路由到 Claude API、Amazon Bedrock 或 Google Cloud，并可在不同提供方之间进行可选的故障转移。
- 支出上限。网关允许你设置每日、每周和每月的支出限额。限额可按组织、群组或用户分别应用。

> • Identity. It acts as an OpenID Connect (OIDC) relying party against Google Workspace, Microsoft Entra ID, Okta, or any standards-compliant OIDC provider, and issues a short-lived session. No long-lived secrets sit on developer machines.
> • Policy. You can define managed settings once on the server, and clients receive the policy at sign-in and the gateway enforces it on every request. You can adjust allowed models and default settings centrally.
> • Telemetry. The client stamps a usage metric for every request, and the gateway relays it over OTLP to a collector you configure, in your network and on your retention schedule.
> • Routing. The gateway holds your upstream credential and routes inference to the Claude API, Amazon Bedrock, or Google Cloud, with optional failover between providers.
> • Spend caps. The gateway allows you to set daily, weekly, and monthly spend limits. Limits can be applied per organization, group, or user.
除非你将网关配置为使用 Claude API，否则它不会向 Anthropic 发送推理流量或用量数据。我们也将公布该网关所使用的协议，以便其他网关开发者实现相同的功能。

> The gateway does not send inference traffic or usage data to Anthropic unless you configure it to use the Claude API. We're also publishing the protocol the gateway uses, so other gateway developers can implement the same features.

### 入门

> Getting started

该网关现已可用。开始使用：

> The gateway is available now. To get started:

- 部署网关：下载 Claude Code CLI 二进制文件，将 gateway.yaml 指向你的 OIDC 签发方（issuer）和上游凭据，并在你的身份提供方（IdP）中注册一个 OIDC 应用。
- 推广上线：在客户端机器的 managed-settings.json 中配置 forceLoginMethod 和 forceLoginGatewayUrl 参数。客户端在首次启动时即连接到你的网关。

> • Deploy the gateway : Download the Claude Code CLI binary, point gateway.yaml at your OIDC issuer and upstream credential, and register one OIDC app in your IdP.
> • Roll it out : Configure the forceLoginMethod and forceLoginGatewayUrl parameters in managed-settings.json on client machines. Clients connect to your gateway on first boot.
参见文档以了解更多。

> See the documentation to learn more.

## 术语对照

| English | 中文 |
|---|---|
| gateway | 网关 |
| control plane | 控制平面 |
| self-hosted | 自托管 |
| single sign-on (SSO) | 单点登录 |
| role-based access | 基于角色的访问控制 |
| cost attribution | 成本归集 |
| stateless container | 无状态容器 |
| identity provider (IdP) | 身份提供方 |
| OpenID Connect (OIDC) | OpenID Connect 协议 |
| relying party | 依赖方 |
| managed settings | 受管设置 |
| telemetry | 遥测 |
| failover | 故障转移 |
| spend caps | 开销上限 |
