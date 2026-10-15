# Agent observability on the Claude Platform

> 来源：Claude Blog / Anthropic，2026-10-14
> 原文链接：https://claude.com/resources/articles/agent-observability-on-the-claude-platform

You can now send OpenTelemetry (OTel) traces from Claude Managed Agents, the Messages API, and Claude SDKs to any OTel tool, and follow each step your agents take. If you already send Claude Code or Cowork traces to your observability tool, the agents you build on the Claude Platform can also show up in the same place.

### Trace agents with OpenTelemetry

Trusting an agent with more access starts with tracing its model calls, tool use, and MCP server calls. Review its traces, then widen its access as it proves reliable.

Add a destination in the Claude Console, and every agent turn, model call, and tool use arrives in your observability tool as a standard OpenTelemetry trace, with latency, tokens, and IDs.

![How OpenTelemetry traces work](https://assets.claude.com/28fe34519808d40faa51162351234a3790230860.png)

### Works with your observability tools

Claude traces follow the [OpenTelemetry GenAI semantic conventions](https://github.com/open-telemetry/semantic-conventions-genai/), so data from Claude and other providers works in the same tools and dashboards.

- **Debug agents next to the rest of your stack**. In [Grafana Cloud](https://grafana.com/docs/grafana-cloud/observe-and-act/agent-observability/guides/send-claude-platform-traces/), [Honeycomb](https://docs.honeycomb.io/send-data/use-cases/claude-platform), [Sentry](https://sentry.io/cookbook/trace-claude-platform-with-opentelemetry/), and [Splunk](https://agent-observability-docs.splunk.com/sdk-api/third-party-integrations/claude), agent traces sit beside your logs and metrics, so you can see which service a slow or failed step came from.
- **Improve agents with production data**. With [Arize AI](https://arize.com/docs/ax/integrations/platforms/claude-managed-agents/claude-managed-agents-tracing), [Braintrust](https://www.braintrust.dev/docs/integrations/ai-providers/anthropic#export-opentelemetry-traces-from-the-claude-api), [Datadog](https://docs.datadoghq.com/llm_observability/instrument/otel_instrumentation/?tab=python#using-claude-managed-agents), [Langfuse](https://langfuse.com/integrations/model-providers/claude-platform), [LangSmith by LangChain](https://docs.langchain.com/langsmith/trace-anthropic), [New Relic](https://newrelic.com/blog/news/anthropic-otel-ai-observability), and [PostHog](https://posthog.com/docs/ai-observability/installation/anthropic?tab=Claude+Platform&utm_source=anthropic&utm_campaign=anthropic-otel), you can turn real traces into evals, catch quality issues, and measure whether a change helped.
- **Track usage across your organization**. Send traces to [Databricks Unity Gateway](https://docs.databricks.com/aws/en/ai-gateway/unified-trace-table) so platform and security teams can see token usage by team and flag unusual activity.

Claude traces also work with any other OpenTelemetry tool that accepts a standard OTLP endpoint.

### Get started

OpenTelemetry traces on the Claude Platform is available in public beta. Managed Agents and the Messages API need a destination in the Claude Console, while Claude SDKs export traces automatically. 

See the [docs](https://platform.claude.com/docs/en/manage-claude/opentelemetry) to get started.
