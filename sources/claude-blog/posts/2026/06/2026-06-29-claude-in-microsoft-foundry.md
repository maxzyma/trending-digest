---
source: claude-blog
source_url: https://claude.com/blog/claude-in-microsoft-foundry
published_at: 2026-06-29
category: Product announcements
title_en: Claude in Microsoft Foundry is now generally available
title_zh: Claude 入驻 Microsoft Foundry 正式全面可用
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 0
source_image_count: 0
---

# Claude 入驻 Microsoft Foundry 正式全面可用

> Claude in Microsoft Foundry is now generally available

> 来源：Claude Blog，2026-06-29
> 原文链接：https://claude.com/blog/claude-in-microsoft-foundry
> 分类：Product announcements

## 核心要点

- Claude 模型现已在托管于 Azure 的 Microsoft Foundry 中全面开放使用。
- Claude 直接运行在你的 Azure 环境中，复用现有的身份验证、计费与治理控制。
- 首批提供 Claude Opus 4.8 与 Claude Haiku 4.5，通过 Messages API 接入。
- 支持提示缓存、扩展思考等核心能力，覆盖编程、智能体任务到复杂推理等场景。
- 提供合并账单；符合条件的 Microsoft 企业协议客户可用 Azure 承诺额度抵扣 Claude 用量。
- 提供两种运行方式：托管于 Azure 与托管于 Anthropic，后者具备完整 API 功能与更新模型。
- 可选推理处理位置，包括满足数据驻留需求的美国数据区域；推理由 Anthropic 运营。

## 正文

自即日起，托管于 Azure 的 Claude 模型在 Microsoft Foundry 中全面开放。Claude 运行在你的 Azure 环境中，沿用团队已在使用的身份验证、计费与治理控制。你可以选择推理处理的位置，包括面向有数据驻留要求团队的美国数据区域。推理由 Anthropic 运营，Anthropic 作为数据处理方。

> Starting today, Claude models are generally available in Microsoft Foundry, hosted on Azure. Claude runs in your Azure environment with the authentication, billing, and governance controls your teams already use. You can choose where inference is processed, including a US data zone for teams with data residency requirements. Anthropic operates the inference and is the data processor.

#### 通过你的 Azure 账户使用 Claude 进行构建

> Build with Claude through your Azure account

首先，Claude Opus 4.8 和 Claude Haiku 4.5 已在 Messages API 中提供，并具备提示缓存（prompt caching）和扩展思考（extended thinking）等核心能力，可支持从编码、智能体工作到复杂推理的各类用例。我们会持续扩展 Foundry 中可用的内容。

> To start, Claude Opus 4.8 and Claude Haiku 4.5 are available in the Messages API, with core capabilities like prompt caching and extended thinking to support use cases ranging from coding and agentic work to complex reasoning. We'll continue expanding what's available in Foundry over time.

Microsoft Foundry 中的 Claude 是 Azure 原生（Azure-native）的，可与你现有的 Azure 身份、网络和治理控制协同工作。你会收到一张合并后的发票；对于持有 Microsoft 企业协议（Enterprise Agreement）的符合条件客户，Claude 的使用量会从 Microsoft Azure 的承诺额度中扣减。

> Claude in Microsoft Foundry is Azure-native, working with your existing Azure identity, networking, and governance controls. You receive a single consolidated invoice, and for eligible customers with a Microsoft Enterprise Agreement, Claude usage draws down a Microsoft Azure commitment.

#### 在 Azure 中运行 Claude，由 Anthropic 运营

> Run Claude in Azure, operated by Anthropic

在 Microsoft Foundry 中运行 Claude 有两种方式。如果在你自己的 Azure 环境中运行很重要，并需要 Azure 的身份验证、计费、治理和美国数据区，请选择托管于 Azure（hosted on Azure）。如果你需要完整的 API 功能集，或某个尚未在 Azure 上提供的模型，请选择托管于 Anthropic（hosted on Anthropic，即此前的 Foundry Preview）。随着时间推移，我们的目标是让托管于 Azure 的方案与托管于 Anthropic 的方案在功能和模型上达到一致。

> There are two ways to run Claude in Microsoft Foundry. Choose hosted on Azure when running in your Azure environment matters, with Azure authentication, billing, governance, and a US data zone. Choose hosted on Anthropic (previously the Foundry Preview) when you need the full set of API features or a model that is not yet available on Azure. Over time, we aim to have feature and model parity between the hosted on Azure offering and the Anthropic-hosted one.

#### 开始使用

> Get started

Microsoft Foundry 中的 Claude 今天起正式商用。要开始使用，请打开 Microsoft Foundry 中的 Claude，或查阅相关文档。

> Claude in Microsoft Foundry is generally available today. To get started, open Claude in Microsoft Foundry or explore the documentation .

## 术语对照

| English | 中文 |
|---|---|
| Microsoft Foundry | 微软 Foundry |
| generally available | 全面开放使用 |
| inference | 推理 |
| data zone | 数据区域 |
| data residency | 数据驻留 |
| data processor | 数据处理方 |
| Messages API | 消息 API |
| prompt caching | 提示缓存 |
| extended thinking | 扩展思考 |
| agentic work | 智能体任务 |
| governance controls | 治理控制 |
| consolidated invoice | 合并账单 |
| Microsoft Enterprise Agreement | 微软企业协议 |
| feature and model parity | 功能与模型对等 |
