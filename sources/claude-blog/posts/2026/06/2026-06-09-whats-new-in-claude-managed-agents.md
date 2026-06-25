---
source: claude-blog
source_url: https://claude.com/blog/whats-new-in-claude-managed-agents
published_at: 2026-06-09
category: Product announcements
title_en: New in Claude Managed Agents: run agents on a schedule and store environment variables in vaults
title_zh: Claude 托管智能体新功能：按计划运行智能体，并在保险库中存储环境变量
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/QOG9lyrgJP3ORbKxSvykZyBvVzN67Mw4"
---

# Claude 托管智能体新功能：按计划运行智能体，并在保险库中存储环境变量
> 来源：Claude Blog，2026-06-09
> 原文链接：https://claude.com/blog/whats-new-in-claude-managed-agents
> 分类：Product announcements

## 核心要点
- 从今天起，Claude 托管智能体（Managed Agents）可以按计划运行，并能安全访问命令行工具（CLI）及其他需认证的服务，两项功能现已在 Claude 平台上以公测形式推出。
- 计划化部署（scheduled deployment）通过为智能体设定 cron 计划来实现，每次计划触发时智能体会启动新会话并完成任务，无需自行搭建或托管调度器。
- 适用于每夜数据同步、每周合规扫描、每日摘要等周期性工作，部署上线后可随时暂停、恢复、归档或按需触发额外运行。
- 保险库（vaults）现已扩展支持环境变量，使 CLI 及其他工具能够发起经过认证的请求。
- 智能体永远看不到密钥本身，沙箱中仅保存占位符，真实密钥在网络边界附加，且只在发往你允许的域名的请求中生效。
- Rakuten、Actively AI、Ando、Notion、Browserbase、KERNEL、Milana 等团队已在使用这些功能自动化周期性工作并安全连接认证工具。

## 中文译文

从今天起，Claude 托管智能体（Managed Agents）可以按计划运行，并能安全访问命令行工具（CLI）及其他需认证的服务。两项功能现已在 Claude 平台（Claude Platform）上以公测（public beta）形式推出。

## 按计划运行智能体

智能体现在可以按计划运行，自动完成例行工作。计划化部署（scheduled deployment）为智能体设定一个 cron 计划。每次计划触发时，智能体会启动一个新会话并完成其任务，你无需构建或托管任何调度器。

可将其用于周期性工作，例如每夜数据同步、每周合规扫描或每日摘要。部署一旦上线，你可以随时暂停、恢复或归档它，也可以按需触发额外的运行。

各团队已在使用计划化部署来自动化周期性工作：

- Rakuten 使用计划化部署，按每周或每月的计划分析电子表格数据并生成报告和演示文稿。团队还会监控生产日志和指标，使产品经理无需创建仪表盘即可了解应用健康状况。

- Actively AI 使用托管智能体为销售团队提供跨账户的智能体式搜索（agentic search）能力。计划化部署会定期刷新答案，通过替换团队最初自行搭建的调度基础设施，简化了他们的技术栈。

- Ando 使用计划化部署来推进招聘和销售团队的工作。智能体自主监测各渠道中提出的后续步骤，在到期时进行跟进，并发送会议提醒。

## 在保险库中存储环境变量，以认证 CLI 及其他工具

智能体通过直接 API 调用、CLI 和 MCP 连接到外部系统。现在我们扩展了保险库（vaults），使其支持环境变量，让 CLI 及其他工具能够发起经过认证的请求。CLI 让智能体可以通过 shell 直接驱动已有的命令行工具，使其成为一条快速、轻量的集成路径。只需注册一个 API 密钥，并为其指定环境变量名称及可访问的域名，安装在智能体沙箱（sandbox）中的 CLI 便可使用它发起经过认证的 API 调用。

智能体永远看不到你的密钥，因为沙箱中只保存一个占位符。真实密钥在网络边界附加，且只在发往你允许的域名的请求中生效，因此它只会去往你批准的地方。要更改密钥，只需在保险库中更新它，正在运行的会话会在下一次调用时获取新值。大多数在 HTTP 请求中发送密钥的 CLI 都以这种方式工作，包括 Browserbase、KERNEL、Notion、Ramp 和 Sentry 的 CLI。Browserbase 和 KERNEL 首次为托管智能体提供了浏览器能力，使智能体能够在使用其他工具的同时浏览网页并与之交互。

各团队正使用保险库中的环境变量，让智能体安全访问需认证的工具：

- Notion 使用保险库中的环境变量，将其 CLI 与 MCP 工具一同推出，为其智能体增加文件上传能力，且 API 令牌从不交给模型。

- Browserbase 通过保险库认证的 browse CLI 构建了其公开的浏览器技能目录。一个计划化部署会定期验证该目录，以保持其准确性。

- KERNEL 使用保险库中的环境变量，将智能体安全连接到其跟踪使用情况和客户对话的数据库。智能体会在使用量激增时即时标记，使团队能够向客户确认该活动是否属于预期。

- Milana 使用保险库中的环境变量，将其 AI 产品工程师安全连接到客户的代码库。智能体能够自动发现并修复缺陷，且大规模数据分析的运行速度比以往更快。

## 术语对照
| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| public beta | 公测 |
| Claude Platform | Claude 平台 |
| scheduled deployment | 计划化部署 |
| cron schedule | cron 计划 |
| session | 会话 |
| data sync | 数据同步 |
| compliance scan | 合规扫描 |
| digest | 摘要 |
| dashboard | 仪表盘 |
| agentic search | 智能体式搜索 |
| vaults | 保险库 |
| environment variables | 环境变量 |
| CLI | 命令行工具 |
| MCP | MCP |
| API key | API 密钥 |
| sandbox | 沙箱 |
| network boundary | 网络边界 |
| placeholder | 占位符 |
| browser capabilities | 浏览器能力 |
| API tokens | API 令牌 |
| codebase | 代码库 |
