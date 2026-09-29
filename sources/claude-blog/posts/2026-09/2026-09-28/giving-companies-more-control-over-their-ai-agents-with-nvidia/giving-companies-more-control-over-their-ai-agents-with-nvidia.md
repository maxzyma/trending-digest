# 携手 NVIDIA，让企业更好地掌控其 AI 智能体

> Giving companies more control over their AI agents, with NVIDIA

> 来源：Claude Blog / Anthropic，2026-09-28
> 原文链接：https://claude.com/blog/giving-companies-more-control-over-their-ai-agents-with-nvidia
> 分类：人工智能 / 智能体安全

## 核心要点

- NVIDIA 发布了开放软件平台和参考系统设计 Open Agent Safety Platform，Anthropic 与其合作为智能体技术栈增加更多层级的安全防护与控制能力。
- 随着企业从用 AI 回答问题转向部署能代表用户采取行动的智能体，智能体获得的访问权限越大，企业就越需要控制和核查其行为。
- 防护从模型内部的安全机制开始，Managed Agents 与 OpenShell 在模型之外增加作用于智能体行为的限制，各层独立执行且采用模块化设计。
- Claude Managed Agents 将智能体循环运行在与沙箱分离的服务器上，并把凭据存放在单独的保险库中，使智能体永远无法看到凭据。
- Managed Agents 提供记录每项智能体操作的审计追踪，可与企业现有访问控制系统集成，并允许企业自行选择沙箱的运行位置和方式。
- NVIDIA OpenShell 是开源安全运行时，默认阻止一切未经规则明确允许的操作，在智能体外部对工具、文件、网络连接和数据执行策略并记录每项决定。
- 团队可从较窄权限起步、审查日志并借助 Claude 收紧规则趋近最小权限，再由 OpenShell 的策略证明器通过数学证明确认智能体在规则下可访问的范围。
- Managed Agents 提供生产级智能体基础设施、可持续数小时的长时会话、多智能体编排以及包含作用域权限和执行追踪的可信治理能力。
- Notion、Rakuten 和 Asana 等企业已使用 Managed Agents 实现并行任务处理、跨部门专业智能体的快速部署以及与人协同的 AI Teammates。
- Managed Agents 现已推出并可在客户掌控的沙箱中运行，OpenShell 以 Apache 2.0 许可证开源并可在 GitHub 和 NVIDIA 开发者资源页面获取。

## 正文

NVIDIA 今日发布了 [Open Agent Safety Platform](https://nvidianews.nvidia.com/news/open-agent-safety-platform)，这是一个用于增强 AI 安全性的开放软件平台和参考系统设计。Anthropic 与 NVIDIA 展开合作，为智能体技术栈带来更多层级的安全防护与控制能力。

> NVIDIA today announced the [Open Agent Safety Platform](https://nvidianews.nvidia.com/news/open-agent-safety-platform), an open software platform and reference system design for strengthening AI security. Anthropic has collaborated with NVIDIA to bring additional layers of security and control to the agent stack. 

Claude Managed Agents 是一套可组合的 API，用于大规模构建和部署生产级智能体。它将智能体所需的凭据保存在保险库（vault）中，使智能体始终无法看到这些凭据。开源的 NVIDIA OpenShell 软件旨在控制智能体在工作过程中可以执行的操作和可以访问的资源。将 Managed Agents 与 OpenShell 结合使用的客户，可以限制智能体能做什么、审查智能体做了什么，并确认这些限制已经生效。

> Claude Managed Agents, a suite of composable APIs for building and deploying production-grade agents at scale, holds the credentials an agent needs in a vault so the agent never sees them. Open source NVIDIA OpenShell software is designed to control what the agent can execute and reach while it works. Customers who are using Managed Agents with OpenShell can limit what an agent can do, review what the agent did and confirm that the limits are in place. 

企业正在从使用 AI 回答问题，转向部署能够跨业务部门处理复杂工作、使用专有数据并代表用户采取行动的智能体。随着模型不断进步，智能体的用途越来越多，获得的访问权限也越来越大。智能体拥有的访问权限越多，其所在企业就越需要控制和核查它的行为。

> Companies are moving from using AI to answer questions to deploying agents that handle complex work across business units, use proprietary data and take actions on behalf of users. As models improve, agents find more uses and get more access. The more access an agent has, the more its company needs to control and check what it does. 

#### **分层防护 **

> **Protection in layers **

防护始于模型内部的安全机制。Managed Agents 和 NVIDIA Open Shell 在模型之外增加了限制，作用于智能体的行为。每一层都旨在独立执行其限制，因此防护不依赖于任何单一层。这些层采用模块化设计，企业可以根据自身配置选用适合的层。

> Protection starts with safeguards inside the model. Managed Agents and NVIDIA Open Shell add limits that sit outside the model and apply to what the agent does. Each layer is designed to enforce its limits independently, so protection doesn't depend on any single layer. The layers are modular, so companies can adopt the ones that fit their setup. 

#### **由 Claude Managed Agents 执行工作并持有凭据**

> **Claude Managed Agents does the work and holds the credentials **

借助 Managed Agents，智能体循环运行在与沙箱（即执行工作的隔离环境）分离的服务器上。凭据（即密码和访问密钥）存放在单独的保险库中，因此智能体永远无法看到它们。

> With Managed Agents, the agent loop runs on a separate server from the sandbox, the isolated environment where the work happens. Credentials, meaning passwords and access keys, are held in a separate vault, so the agent never sees them. 

Managed Agents 还提供审计追踪功能，记录每个智能体执行的操作，并可与公司现有的访问控制系统集成。公司可以使用自己的沙箱环境，并自行选择其运行位置和运行方式。

> Managed Agents also provides audit trails, which record what each agent did, and integration with a company's existing access controls. Companies can bring their own sandbox setup and choose where and how it runs. 

#### **NVIDIA OpenShell 设定智能体可访问的范围 **

> **NVIDIA OpenShell sets what an agent can reach **

[OpenShell](https://www.nvidia.com/en-us/ai/openshell/) 是 NVIDIA 推出的开源安全运行时软件。它治理并监控 AI 智能体的所有行为，并对每一项操作执行策略。除非有规则明确允许，否则 OpenShell 会阻止一切操作。它会检查智能体尝试使用的每个工具，并对智能体访问的文件、网络连接和数据应用规则。这些规则在智能体外部执行，且 OpenShell 会记录其允许或阻止的每一项决定。

> [OpenShell](https://www.nvidia.com/en-us/ai/openshell/) is open source secure runtime software from NVIDIA. It governs and monitors all AI agent behavior and enforces policies for every action. OpenShell blocks everything unless a rule allows it. It checks each tool an agent tries to use and applies rules to the files, network connections and data the agent accesses. The rules are enforced outside the agent, and OpenShell logs every decision it allows or blocks. 

团队可以从较窄的权限起步，审查日志，并借助 Claude 收紧规则，使其趋近任务所需的最小访问权限。随后，OpenShell 的策略证明器会通过数学证明，确认在团队编写的规则下智能体能够访问哪些内容。

> Teams can start with narrow permissions, review the log, and use Claude to tighten the rules toward the least access a task needs. OpenShell's policy prover then uses mathematical proof to confirm what the agent can reach under the rules the team wrote. 

#### **Claude Managed Agents 包含哪些内容 **

> **What Claude Managed Agents includes **

- 生产级智能体，安全沙箱、身份验证和工具执行均已为你处理妥当。 
- 可自主运行数小时的长时会话，即使连接中断，进度和输出也会保留。 
- 多智能体编排：智能体可以启动并指挥其他智能体，将复杂工作并行处理。
- 可信治理：让智能体在内置作用域权限、身份管理和执行追踪的前提下访问真实系统。

> • Production-grade agents with secure sandboxing, authentication, and tool execution handled for you. 
> • Long-running sessions that operate autonomously for hours, with progress and outputs that persist even through disconnections. 
> • Multi-agent orchestration, where agents can spin up and direct other agents to parallelize complex work. 
> • Trusted governance, giving agents access to real systems with scoped permissions, identity management, and execution tracing built in. 

#### **团队如何使用 Managed Agents **

> **How teams use Managed Agents **

- [Notion](https://claude.com/customers/notion-qa) 让团队可以在自己的工作区内把工作交给 Claude。工程师用它来交付代码，其他员工则用它来制作网站和演示文稿。数十项任务可以并行运行，与此同时团队成员一起协作处理产出的结果。
- [Rakuten](https://claude.com/customers/rakuten-qa) 在工程、产品、销售、市场营销和财务等领域运行专业智能体，每个智能体都在一周内完成部署。
- [Asana](https://claude.com/customers/asana-qa) 打造了 AI Teammates：这些智能体在 Asana 项目中与人协同工作，承担任务并起草交付成果。借助 Managed Agents，团队添加高级功能的速度比不使用它时更快。

> • [Notion](https://claude.com/customers/notion-qa) lets teams hand work to Claude inside their workspace. Engineers use it to ship code, and other employees use it to produce websites and presentations. Dozens of tasks can run in parallel while the team works on the results together. 
> • [Rakuten](https://claude.com/customers/rakuten-qa) runs specialist agents across engineering, product, sales, marketing, and finance, each deployed within a week. 
> • [Asana](https://claude.com/customers/asana-qa) built AI Teammates, agents that work alongside people in Asana projects, take on tasks and draft deliverables. Using Managed Agents, the team added advanced features faster than it could have otherwise. 

#### **可用性 **

> **Availability **

Managed Agents 现已推出。它可以在你掌控的沙箱中运行，该沙箱既可以部署在你自己的基础设施上，也可以由托管服务商提供。NVIDIA OpenShell 以 Apache 2.0 许可证开源，可在 [GitHub](https://github.com/NVIDIA/OpenShell) 和 NVIDIA 的[开发者资源页面](https://docs.nvidia.com/openshell/latest/about/overview)上获取。

> Managed Agents is available today. It can operate in a sandbox you control either running on your own infrastructure, or with a managed provider. NVIDIA OpenShell is open source under the Apache 2.0 license and available on [GitHub](https://github.com/NVIDIA/OpenShell) and NVIDIA's [developer resources page](https://docs.nvidia.com/openshell/latest/about/overview). 

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| AI Agent | AI 智能体 | 能够自主执行多步任务并代表用户采取行动的 AI 系统。 |
| Managed Agents | 托管智能体 | Anthropic 提供的一套可组合 API，用于大规模构建和部署生产级智能体。 |
| OpenShell | OpenShell | NVIDIA 推出的开源安全运行时，用于治理、监控智能体行为并对每项操作执行策略。 |
| Vault | 保险库 | 独立存放密码、访问密钥等凭据的安全存储，使智能体无法直接看到凭据。 |
| Credentials | 凭据 | 用于身份验证和授权访问的密码、访问密钥等信息。 |
| Sandbox | 沙箱 | 智能体执行工作所在的隔离环境。 |
| Agent Loop | 智能体循环 | 智能体反复进行推理、调用工具并处理结果的核心运行过程。 |
| Audit Trail | 审计追踪 | 对智能体执行的每项操作进行记录以便事后审查的功能。 |
| Access Control | 访问控制 | 规定哪些主体可以访问哪些资源及执行哪些操作的机制。 |
| Runtime | 运行时 | 程序或智能体实际执行时所处并受其管控的软件环境。 |
| Default Deny | 默认拒绝 | 除非有规则明确允许，否则阻止一切操作的安全策略原则。 |
| Least Privilege | 最小权限 | 仅授予完成任务所必需的最低访问权限的安全原则。 |
| Policy Prover | 策略证明器 | 通过数学证明确认在给定规则下智能体可访问范围的工具。 |
| Multi-agent Orchestration | 多智能体编排 | 由一个智能体启动并指挥其他智能体以并行处理复杂工作的机制。 |
| Scoped Permissions | 作用域权限 | 限定在特定资源或操作范围内的访问权限。 |
