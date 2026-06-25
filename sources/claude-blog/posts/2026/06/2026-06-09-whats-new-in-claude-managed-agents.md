---
source: claude-blog
source_url: https://claude.com/blog/whats-new-in-claude-managed-agents
published_at: 2026-06-09
category: Product announcements
title_en: New in Claude Managed Agents: run agents on a schedule and store environment variables in vaults
title_zh: Claude 托管智能体新功能：按计划运行智能体，并在保险库中存储环境变量
source_intro_paragraphs: 1
source_image_count: 2
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/dQPGYqjpJYg04PkAsBv4arolWakx1Z5N"
---

# Claude 托管智能体新功能：按计划运行智能体，并在保险库中存储环境变量

> 来源：Claude Blog，2026-06-09
> 原文链接：https://claude.com/blog/whats-new-in-claude-managed-agents
> 分类：Product announcements

## 导语

从今天起，Claude 托管智能体（Claude Managed Agents）可以按计划运行，并安全地访问命令行工具（CLI）及其他需要身份验证的服务。这两项功能现已在 Claude 平台（Claude Platform）上以公开测试版（public beta）形式提供。

## 核心要点

- 智能体现可按计划（cron）自动运行，无需自行搭建或托管调度器。
- 计划部署适用于夜间数据同步、每周合规扫描、每日摘要等周期性工作，并支持随时暂停、恢复、归档或按需触发。
- 保险库（vault）现已扩展支持环境变量，使 CLI 和其他工具能够发起经过身份验证的请求。
- 智能体永远看不到真实密钥，沙箱中仅保存占位符，真实密钥在网络边界附加，且仅用于你所允许的域名。
- Browserbase 与 KERNEL 首次为托管智能体带来了浏览器能力，使智能体能够浏览并与网页交互。
- Rakuten、Actively AI、Ando、Notion、KERNEL、Milana 等团队已在使用这些功能自动化周期性工作并安全接入认证工具。

## 中文译文

从今天起，Claude 托管智能体（Claude Managed Agents）可以按计划运行，并安全地访问命令行工具（CLI）及其他需要身份验证的服务。这两项功能现已在 Claude 平台（Claude Platform）上以公开测试版（public beta）形式提供。

### 按计划运行智能体

智能体现在可以按计划运行，自动完成日常工作。计划部署（scheduled deployment）为智能体设定一个 cron 计划。每当计划触发时，智能体便会启动一个新会话并完成其任务，你无需自行构建或托管任何调度器。

可将其用于周期性工作，例如夜间数据同步、每周合规扫描或每日摘要。部署上线后，你可以随时暂停、恢复或归档它，也可以按需触发额外的运行。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a2704ab5b6bc1de3bb952fc_Claude-Console-Scheduled-Deployments.png)

已有团队在使用计划部署来自动化周期性工作：

- Rakuten 使用计划部署，按每周或每月的计划分析电子表格数据并生成报告与演示文稿。团队还借此监控生产环境的日志与指标，使产品经理无需创建仪表盘即可了解应用的健康状况。

- Actively AI 使用托管智能体为销售团队提供跨账户的智能体搜索（agentic search）能力。计划部署定期刷新答案，取代了团队最初自行构建的调度基础设施，从而简化了其技术栈。

- Ando 使用计划部署来推动招聘和销售团队的工作。智能体会自主关注各渠道中提出的后续步骤，在到期时进行跟进，并发送会议提醒。

### 在保险库中存储环境变量，以对 CLI 及其他工具进行身份验证

智能体通过直接的 API 调用、CLI 和 MCP 连接到外部系统。现在，我们正在扩展保险库（vault）以支持环境变量，使 CLI 和其他工具能够发起经过身份验证的请求。CLI 让智能体能够通过 shell 直接驱动现有的命令行工具，使其成为一条快速、轻量的集成路径。只需注册一个 API 密钥，并为其指定环境变量名称及其可访问的域名，安装在智能体沙箱中的 CLI 便可使用它来发起经过身份验证的 API 调用。

智能体永远看不到你的密钥，因为沙箱中只保存一个占位符。真实密钥在网络边界附加，且仅用于发往你所允许域名的请求，因此它只会前往你已批准的地方。要更改密钥，只需在保险库中更新它，正在运行的会话将在其下一次调用时获取新值。大多数在 HTTP 请求中发送密钥的 CLI 都以这种方式工作，包括 Browserbase、KERNEL、Notion、Ramp 和 Sentry 的 CLI。Browserbase 和 KERNEL 首次为托管智能体带来了浏览器能力，使智能体能够在其他工具之外导航并与网页交互。

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a27074e40b19ba74e79b134_Claude-Managed-Agents-CLI-credential-vaults-diagram%20(1).png)

已有团队在保险库中使用环境变量，为智能体提供对认证工具的安全访问：

- Notion 在保险库中使用环境变量，将其 CLI 与 MCP 工具一同推出，从而为其智能体添加文件上传能力，且 API 令牌从不交给模型。

- Browserbase 使用经保险库认证的 browse CLI 构建了其公开的浏览器技能目录。一个计划部署定期验证该目录，以保持其准确性。

- KERNEL 在保险库中使用环境变量，将智能体安全地连接到其追踪使用情况和客户对话的数据库。智能体会在使用量激增时实时标记，使团队能够与客户确认相关活动是否符合预期。

- Milana 在保险库中使用环境变量，将其 AI 产品工程师安全地连接到客户的代码库。智能体会自动查找并修复 bug，且大规模数据分析的运行速度比以往更快。

## 术语对照

| English | 中文 |
|---|---|
| Claude Managed Agents | Claude 托管智能体 |
| Claude Platform | Claude 平台 |
| public beta | 公开测试版 |
| scheduled deployment | 计划部署 |
| cron schedule | cron 计划 |
| data sync | 数据同步 |
| compliance scan | 合规扫描 |
| digest | 摘要 |
| agentic search | 智能体搜索 |
| vault | 保险库 |
| environment variable | 环境变量 |
| CLI | 命令行工具 |
| MCP | MCP |
| API key | API 密钥 |
| sandbox | 沙箱 |
| placeholder | 占位符 |
| network boundary | 网络边界 |
| browser skills | 浏览器技能 |
