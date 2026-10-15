# Claude 平台上的智能体可观测性

> Agent observability on the Claude Platform

> 来源：Claude Blog / Anthropic，2026-10-14
> 原文链接：https://claude.com/resources/articles/agent-observability-on-the-claude-platform
> 分类：AI 工程 / 智能体可观测性

## 核心要点

- Claude Managed Agents、Messages API 和 Claude SDK 产生的 OpenTelemetry 追踪数据现在可以发送到任意 OTel 工具，用于跟踪智能体执行的每一个步骤。
- 已将 Claude Code 或 Cowork 追踪数据接入可观测性工具的用户，可以让基于 Claude Platform 构建的智能体在同一处呈现。
- 追踪模型调用、工具使用和 MCP 服务器调用是放心扩大智能体访问权限的前提，应在其证明可靠后再逐步放权。
- 在 Claude Console 中添加目标端点后，每次智能体轮次、模型调用和工具使用都会以标准 OTel 追踪形式发送，并附带延迟、token 用量和各类 ID。
- Claude 追踪数据遵循 OpenTelemetry GenAI 语义约定，因此可与其他提供商的数据在相同工具和仪表盘中共同使用。
- 在 Grafana Cloud、Honeycomb、Sentry 和 Splunk 中，智能体追踪与日志和指标并列呈现，便于定位缓慢或失败步骤所在的服务。
- 借助 Arize AI、Braintrust、Datadog、Langfuse、LangSmith、New Relic 和 PostHog，可以将真实追踪转化为评估、发现质量问题并衡量改动效果。
- 将追踪数据发送到 Databricks Unity Gateway 后，平台和安全团队可以按团队查看 token 用量并标记异常活动。
- Claude 追踪数据也适用于任何接受标准 OTLP 端点的 OpenTelemetry 工具。
- Managed Agents 和 Messages API 需在 Claude Console 中配置目标端点，而 Claude SDK 会自动导出追踪数据。

## 正文

现在，你可以将 Claude Managed Agents、Messages API 和 Claude SDK 产生的 OpenTelemetry（OTel）链路追踪数据发送到任意 OTel 工具，跟踪智能体执行的每一个步骤。如果你已经将 Claude Code 或 Cowork 的追踪数据发送到可观测性工具，那么你在 Claude Platform 上构建的智能体也能在同一处呈现。

> You can now send OpenTelemetry (OTel) traces from Claude Managed Agents, the Messages API, and Claude SDKs to any OTel tool, and follow each step your agents take. If you already send Claude Code or Cowork traces to your observability tool, the agents you build on the Claude Platform can also show up in the same place.

#### 使用 OpenTelemetry 追踪智能体

> Trace agents with OpenTelemetry

要放心地给智能体更多访问权限，首先要追踪它的模型调用、工具使用和 MCP 服务器调用。审查它的追踪记录，随着它证明自己可靠，再逐步扩大其访问权限。

> Trusting an agent with more access starts with tracing its model calls, tool use, and MCP server calls. Review its traces, then widen its access as it proves reliable.

在 Claude Console 中添加一个目标端点后，每一次智能体轮次、模型调用和工具使用都会以标准 OpenTelemetry 追踪的形式发送到你的可观测性工具中，并附带延迟、token 用量和各类 ID。

> Add a destination in the Claude Console, and every agent turn, model call, and tool use arrives in your observability tool as a standard OpenTelemetry trace, with latency, tokens, and IDs.

![How OpenTelemetry traces work](https://assets.claude.com/28fe34519808d40faa51162351234a3790230860.png)

#### 兼容你的可观测性工具

> Works with your observability tools

Claude 的追踪数据遵循 [OpenTelemetry GenAI 语义约定](https://github.com/open-telemetry/semantic-conventions-genai/)，因此来自 Claude 和其他提供商的数据可以在相同的工具和仪表盘中使用。

> Claude traces follow the [OpenTelemetry GenAI semantic conventions](https://github.com/open-telemetry/semantic-conventions-genai/), so data from Claude and other providers works in the same tools and dashboards.

- **在技术栈的其他部分旁边调试智能体**。在 [Grafana Cloud](https://grafana.com/docs/grafana-cloud/observe-and-act/agent-observability/guides/send-claude-platform-traces/)、[Honeycomb](https://docs.honeycomb.io/send-data/use-cases/claude-platform)、[Sentry](https://sentry.io/cookbook/trace-claude-platform-with-opentelemetry/) 和 [Splunk](https://agent-observability-docs.splunk.com/sdk-api/third-party-integrations/claude) 中，智能体追踪与日志和指标并列呈现，让你能够看出缓慢或失败的步骤来自哪个服务。
- **利用生产数据改进智能体**。借助 [Arize AI](https://arize.com/docs/ax/integrations/platforms/claude-managed-agents/claude-managed-agents-tracing)、[Braintrust](https://www.braintrust.dev/docs/integrations/ai-providers/anthropic#export-opentelemetry-traces-from-the-claude-api)、[Datadog](https://docs.datadoghq.com/llm_observability/instrument/otel_instrumentation/?tab=python#using-claude-managed-agents)、[Langfuse](https://langfuse.com/integrations/model-providers/claude-platform)、[LangChain 的 LangSmith](https://docs.langchain.com/langsmith/trace-anthropic)、[New Relic](https://newrelic.com/blog/news/anthropic-otel-ai-observability) 和 [PostHog](https://posthog.com/docs/ai-observability/installation/anthropic?tab=Claude+Platform&utm_source=anthropic&utm_campaign=anthropic-otel)，你可以将真实的追踪记录转化为评估，发现质量问题，并衡量某项改动是否真正带来了改进。
- **跟踪整个组织的使用情况**。将追踪数据发送到 [Databricks Unity Gateway](https://docs.databricks.com/aws/en/ai-gateway/unified-trace-table)，以便平台和安全团队按团队查看 token 用量并标记异常活动。

> • **Debug agents next to the rest of your stack**. In [Grafana Cloud](https://grafana.com/docs/grafana-cloud/observe-and-act/agent-observability/guides/send-claude-platform-traces/), [Honeycomb](https://docs.honeycomb.io/send-data/use-cases/claude-platform), [Sentry](https://sentry.io/cookbook/trace-claude-platform-with-opentelemetry/), and [Splunk](https://agent-observability-docs.splunk.com/sdk-api/third-party-integrations/claude), agent traces sit beside your logs and metrics, so you can see which service a slow or failed step came from.
> • **Improve agents with production data**. With [Arize AI](https://arize.com/docs/ax/integrations/platforms/claude-managed-agents/claude-managed-agents-tracing), [Braintrust](https://www.braintrust.dev/docs/integrations/ai-providers/anthropic#export-opentelemetry-traces-from-the-claude-api), [Datadog](https://docs.datadoghq.com/llm_observability/instrument/otel_instrumentation/?tab=python#using-claude-managed-agents), [Langfuse](https://langfuse.com/integrations/model-providers/claude-platform), [LangSmith by LangChain](https://docs.langchain.com/langsmith/trace-anthropic), [New Relic](https://newrelic.com/blog/news/anthropic-otel-ai-observability), and [PostHog](https://posthog.com/docs/ai-observability/installation/anthropic?tab=Claude+Platform&utm_source=anthropic&utm_campaign=anthropic-otel), you can turn real traces into evals, catch quality issues, and measure whether a change helped.
> • **Track usage across your organization**. Send traces to [Databricks Unity Gateway](https://docs.databricks.com/aws/en/ai-gateway/unified-trace-table) so platform and security teams can see token usage by team and flag unusual activity.

Claude 追踪数据同样适用于任何其他接受标准 OTLP 端点的 OpenTelemetry 工具。

> Claude traces also work with any other OpenTelemetry tool that accepts a standard OTLP endpoint.

#### 快速开始

> Get started

Claude Platform 上的 OpenTelemetry 追踪功能现已开放公开测试版。Managed Agents 和 Messages API 需要在 Claude Console 中配置一个目标端点，而 Claude SDK 会自动导出追踪数据。

> OpenTelemetry traces on the Claude Platform is available in public beta. Managed Agents and the Messages API need a destination in the Claude Console, while Claude SDKs export traces automatically. 

请参阅[文档](https://platform.claude.com/docs/en/manage-claude/opentelemetry)开始使用。

> See the [docs](https://platform.claude.com/docs/en/manage-claude/opentelemetry) to get started.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| OpenTelemetry (OTel) | OpenTelemetry | 用于生成、收集和导出追踪、指标与日志的开源可观测性标准与工具集。 |
| Observability | 可观测性 | 通过系统输出的遥测数据理解其内部运行状态的能力。 |
| Trace | 链路追踪 / 追踪记录 | 记录一次请求或任务在系统中完整执行路径的遥测数据。 |
| Managed Agents | 托管智能体 | Claude Platform 提供的由平台托管运行的智能体服务。 |
| Messages API | Messages API | 用于向 Claude 模型发送消息并获取回复的核心接口。 |
| Agent Turn | 智能体轮次 | 智能体完成一次输入处理与响应输出的交互单元。 |
| Tool Use | 工具使用 | 模型在执行任务时调用外部函数或工具的能力。 |
| MCP Server | MCP 服务器 | 基于模型上下文协议向模型提供工具和数据的服务端。 |
| Endpoint | 端点 | 接收遥测数据或请求的网络地址。 |
| Latency | 延迟 | 操作从发起到完成所耗费的时间。 |
| Token Usage | token 用量 | 模型调用中消耗的输入与输出 token 数量。 |
| GenAI Semantic Conventions | GenAI 语义约定 | OpenTelemetry 为生成式 AI 遥测数据定义的统一属性命名与结构规范。 |
| OTLP | OpenTelemetry 协议 | OpenTelemetry 用于传输遥测数据的标准协议。 |
| Evaluation (Evals) | 评估 | 用数据集或真实案例系统衡量模型或智能体输出质量的方法。 |
| Public Beta | 公开测试版 | 向所有用户开放但仍处于测试阶段的产品发布状态。 |
