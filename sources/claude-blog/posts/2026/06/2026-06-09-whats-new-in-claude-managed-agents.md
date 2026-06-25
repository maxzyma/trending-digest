---
source: claude-blog
source_url: https://claude.com/blog/whats-new-in-claude-managed-agents
published_at: 2026-06-09
category: Product announcements
title_en: New in Claude Managed Agents: run agents on a schedule and store environment variables in vaults
title_zh: Claude 托管智能体新功能：按计划运行智能体，并在保险库中存储环境变量
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 1
source_image_count: 2
---

# Claude 托管智能体新功能：按计划运行智能体，并在保险库中存储环境变量

> 🌏︎ • New in Claude Managed Agents: run agents on a schedule and store environment variables in vaults

> • 来源：Claude Blog，2026-06-09
> • 原文链接：https://claude.com/blog/whats-new-in-claude-managed-agents
> • 分类：Product announcements

## 核心要点

- 智能体现可按计划（cron）自动运行，无需自行搭建或托管调度器。
- 计划部署适用于夜间数据同步、每周合规扫描、每日摘要等周期性工作，并支持随时暂停、恢复、归档或按需触发。
- 保险库（vault）现已扩展支持环境变量，使 CLI 和其他工具能够发起经过身份验证的请求。
- 智能体永远看不到真实密钥，沙箱中仅保存占位符，真实密钥在网络边界附加，且仅用于你所允许的域名。
- Browserbase 与 KERNEL 首次为托管智能体带来了浏览器能力，使智能体能够浏览并与网页交互。
- Rakuten、Actively AI、Ando、Notion、KERNEL、Milana 等团队已在使用这些功能自动化周期性工作并安全接入认证工具。

## 正文

从今天起，Claude 托管智能体（Claude Managed Agents）可以按计划运行，并安全地访问命令行工具（CLI）及其他需要身份验证的服务。这两项功能现已在 Claude 平台（Claude Platform）上以公开测试版（public beta）形式提供。

> 🌏︎ Starting today, Claude Managed Agents can run on a schedule and securely access CLI tools and other authenticated services. Both features are now available in public beta on the Claude Platform.

即日起，Claude 托管智能体（Claude Managed Agents）可以按计划定时运行，并安全访问命令行工具（CLI）及其他需要身份验证的服务。这两项功能现已在 Claude 平台（Claude Platform）上以公开测试版（public beta）形式推出。

> 🌏︎ Starting today, Claude Managed Agents can run on a schedule and securely access CLI tools and other authenticated services. Both features are now available in public beta on the Claude Platform.

### 定时运行智能体

> Run agents on a schedule

智能体现在可以按计划定时运行，自动完成日常工作。定时部署为智能体设定一个 cron 计划表。每次计划触发时，智能体会启动一个新会话并完成任务，你无需自行构建或托管调度器。

> 🌏︎ Agents can now run on a schedule, completing routine work automatically. A scheduled deployment gives an agent a cron schedule. Each time the schedule fires, the agent starts a new session and completes its task, with no scheduler for you to build or host.

可用于周期性工作，例如每晚数据同步、每周合规扫描或每日摘要。部署上线后，你可以随时暂停、恢复或归档，也可以按需触发额外的运行。

> 🌏︎ Use it for recurring work like a nightly data sync, a weekly compliance scan, or a daily digest. Once a deployment is live, you can pause, resume, or archive it at any time, or trigger additional runs on demand.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a2704ab5b6bc1de3bb952fc_Claude-Console-Scheduled-Deployments.png)

已有团队使用定时部署来自动化周期性工作：

> 🌏︎ Teams are already using scheduled deployments to automate recurring work:

- 乐天（Rakuten）使用定时部署分析电子表格数据，并按每周或每月的计划生成报告和演示文稿。团队还会监控生产日志和指标，让产品经理无需创建仪表盘即可了解应用的健康状况。
- Actively AI 使用托管智能体（Managed Agents）为销售团队提供跨账户的智能体搜索能力。定时部署会定期刷新答案，通过替换团队最初自行构建的调度基础设施，简化了他们的技术栈。‍
- Ando 使用定时部署让招聘和销售团队保持高效运转。智能体自主监控频道以获取建议的后续步骤，在到期时进行跟进，并发送会议提醒。

> 🌏︎ • Rakuten uses scheduled deployments to analyze spreadsheet data and produce reports and decks on a weekly or monthly schedule. Teams also monitor production logs and metrics, allowing product managers to see application health without creating a dashboard.

> • Actively AI uses Managed Agents to power cross-account agentic search for sales teams. Scheduled deployments refresh answers regularly, simplifying their stack by replacing scheduling infrastructure the team initially built themselves. ‍

> • Ando uses scheduled deployments to keep hiring and sales teams moving. Agents autonomously watch channels for proposed next steps, follow up when they're due, and send meeting reminders.

### 将环境变量存储在保险库（vault）中，用于对命令行工具（CLI）及其他工具进行身份验证

> Store environment variables in vaults to authenticate CLIs and other tools

智能体（agent）通过直接 API 调用、命令行工具（CLI）和 MCP 连接外部系统。现在我们将保险库扩展为支持环境变量，使 CLI 和其他工具能够发起经过身份验证的请求。CLI 让智能体可以直接通过 shell 驱动现有的命令行工具，成为一种快速、轻量的集成方式。只需用环境变量名称和它可访问的域名注册一个 API 密钥，安装在智能体沙盒中的 CLI 就能用它发起经过身份验证的 API 调用。

> 🌏︎ Agents connect to external systems through direct API calls, CLIs, and MCP. Now we're extending vaults to support environment variables, so CLIs and other tools can make authenticated requests. CLIs let agents drive existing command-line tools directly through a shell, making them a fast, lightweight integration path. Register an API key with an environment variable name and the domains it can reach, and the CLIs installed in an agent's sandbox can use it to make authenticated API calls.

智能体永远看不到你的密钥，因为沙盒中只保存一个占位符。真实密钥在网络边界处附加，且仅附加到你允许的域名的请求上，因此它只会发往你已批准的地方。要更换密钥，只需在保险库中更新它，正在运行的会话会在下一次调用时获取新值。大多数在 HTTP 请求中发送密钥的 CLI 都以这种方式工作，包括 Browserbase、KERNEL、Notion、Ramp 和 Sentry 的 CLI。Browserbase 和 KERNEL 首次为托管智能体（Managed Agents）提供了浏览器能力，使智能体能够在其他工具之外浏览网页并与之交互。

> 🌏︎ The agent never sees your key because the sandbox only holds a placeholder. The real key is attached at the network boundary, and only on requests to domains you allow, so it only goes where you’ve approved. To change a key, update it in the vault, and running sessions will pick up the new value on their next call. Most CLIs that send their key in an HTTP request work this way, including the Browserbase, KERNEL, Notion, Ramp, and Sentry CLIs. Browserbase and KERNEL give Managed Agents browser capabilities for the first time, so agents can navigate and interact with the web alongside their other tools.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a27074e40b19ba74e79b134_Claude-Managed-Agents-CLI-credential-vaults-diagram%20(1).png)

各团队正在使用保险库中的环境变量，为智能体提供对经过身份验证工具的安全访问：

> 🌏︎ Teams are using environment variables in vaults to give agents secure access to authenticated tools:

- Notion 使用保险库中的环境变量，将其 CLI 与 MCP 工具一同推出，为其智能体增加文件上传能力，同时从不将 API 令牌交给模型。
- Browserbase 使用通过保险库进行身份验证的 browse CLI 构建了其公开的浏览器技能目录。一个定时部署会周期性地验证该目录，以保持其准确性。
- KERNEL 使用保险库中的环境变量，将智能体安全地连接到其追踪使用情况和客户对话的数据库。智能体会在使用量激增发生时及时标记，使团队能够与客户确认该活动是否符合预期。
- Milana 使用保险库中的环境变量，将其 AI 产品工程师安全地连接到客户的代码库。智能体会自动查找并修复漏洞，大规模数据分析也比以往运行得更快。

> 🌏︎ • Notion uses environment variables in vaults to roll out its CLI alongside MCP tools, adding file-upload capabilities to its agents without API tokens ever being handed to the model.

> • Browserbase built its public catalog of browser skills using the browse CLI , authenticated through vaults. A scheduled deployment periodically validates the catalog to keep it accurate.

> • KERNEL uses environment variables in vaults to securely connect agents to the databases where it tracks usage and customer conversations. The agent flags usage surges as they happen, so the team can confirm with customers if the activity is intended. ‍

> • Milana uses environment variables in vaults to securely connect its AI product engineer to a customer's codebase. The agent finds and fixes bugs automatically, with large-scale data analysis running faster than before.

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
