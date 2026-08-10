# 在生产环境中运行自动模式

> Running auto mode in production

> 来源：Claude Blog / Anthropic，2026-08-07
> 原文链接：https://claude.com/blog/auto-mode-in-production
> 分类：AI 工程 / 智能体编码实践

## 核心要点

- 自动模式已成为 Claude Code 的默认设置，由分类器逐一评估代理拟执行的操作并拦截其中看起来可能有害的部分，取代逐条人工批准。
- 智能体编码长期面临速度与安全的取舍：逐条审核会在长会话和并行会话中成为瓶颈，而完全跳过权限检查则容易引发提示注入、范围漂移和误删生产资源。
- 内部评估显示该分类器捕获的危险操作多于开发者手动点击权限提示时捕获的数量，并在第三方红队测试下保持稳健；由于中断减少，Claude 在两次中断之间的工作时长达到此前默认设置的 9 倍。
- Nuro 的资深工程师 Kai Zhou 在自动模式发布前曾自行原型化一个把操作交给小模型判断、敏感操作转发 Slack 审核的钩子，自动模式发布后他搁置了该项目，如今全部编程工作都在自动模式下进行，并常同时开启三四个会话。
- Nuro 在设置中直接禁止递归删除等最危险的命令，分类器在这些防护栏之内做判断；涉及其他团队的工作（如代为审查 Pull Request）时，工程师会切回交互模式逐一审阅。
- Nuro 用自动模式驱动长时间运行的研究智能体去攀升自动驾驶技术栈的评估指标，例如通宵研究评估套件标记的假阴性、起草方案、跑实验并迭代，一次夜间运行在早上交付了三个 PR；另一支团队用同样方法压缩某二进制文件的内存占用。
- Gusto 的 Martin Emde 自去年 12 月以来启动了 2,425 个 Claude Code 会话并以自动模式为主力，跨仓库工作和汇编每日笔记等无人值守任务得以不间断运行；团队分析显示 2026 年 5 月中旬以来约 10% 的会话记录出现过一次自动模式拒绝。
- Gusto 云工程团队的 Chad Kunsman 以二十分钟短促爆发的方式工作，看重自动模式对提示注入的防护及其对操作与请求是否一致的检查；在触及 Terraform、AWS 和线上 API 直接 POST 调用等生产基础设施时，他改用接受编辑模式并手动核验每次工具调用。
- Gusto 通过一个具备工具防护和提示检查功能的受治理代理层路由 MCP 流量，使智能体在自动模式介入前就已处于严格限定的权限范围内。
- Garner Health 于二月向全部 550 名员工推广 Claude Code 并接入 Salesforce、Zendesk、Snowflake 等核心系统，平台工程经理 Evan Magnussen 以标准化技能插件构建了包含上下文探索、对抗性研究与实现阶段的软件开发生命周期。
- Evan 对分类器的唯一调整是不批准代表本人与他人沟通的操作（如发送 Slack 消息或邮件），这与 Kai 在 Nuro 的做法一致；从事核心知识产权工作的团队则学会调整分类器注入的提示词以调节宽松程度。
- Evan 对其他推广企业的建议是积极投入并建立恰当管控，强调遥测数据和相对标准化的工作流是信心的来源，缺乏遥测的自由搭建工作流非常危险。

## 正文

[自动模式现已成为 Claude Code 的默认](http://claude.com/blog/auto-mode-default-in-claude-code)设置。它不再要求你逐条批准代理想要执行的命令，而是由一个分类器评估每个操作，并拦截那些看起来可能有害的操作。

> [Auto mode is now the default](http://claude.com/blog/auto-mode-default-in-claude-code) setting in Claude Code. Instead of asking you to approve every command an agent wants to run, a classifier evaluates each action and blocks ones that look potentially harmful. 

自动模式的设计解决了智能体编码中一个常见的取舍难题：速度与安全。审核每一条命令能让人始终参与其中，但一旦会话延续数小时，或者并行会话成倍增加，这种监督就会成为瓶颈。完全跳过权限检查确实更快——而这也正是提示注入、范围漂移以及偶尔删除生产资源等问题得以发生的原因。

> Auto mode’s design resolves a common agentic coding tradeoff: speed vs. safety. Reviewing every command keeps a human in the loop, but once sessions stretch to hours or multiply in parallel, that oversight becomes the bottleneck. Skipping permission checks entirely is faster—and it’s also how prompt injection, scope drift, and the occasional deleted production resource get through. 

自动模式弥合了其中的大部分差距。在内部评估中，该分类器捕获的危险操作比开发者手动点击权限提示时捕获的更多，而且它的表现在第三方红队测试下依然稳健。此外，由于会话中断的次数减少，Claude 在两次中断之间的工作时长达到此前默认设置的 9 倍——这一点在所有 Claude Code 使用场景中均成立。

> Auto mode closes most of that gap. In internal evaluations, the classifier caught more dangerous actions than developers did when clicking through permission prompts by hand, and its performance held up under third-party red-teaming.  And because sessions pause less often, Claude works 9x longer between interruptions than under the previous default—across all Claude Code usage. 

为了了解自动模式在生产环境中的表现，我们与 Nuro、Gusto 和 Garner Health 的团队进行了交流，探讨他们如何以及为何将自动模式作为日常主力工具，从而在生产环境中兼顾速度与安全。

> To see how auto mode holds up in production, we spoke with teams at Nuro, Gusto, and Garner Health about how and why they use auto mode as their daily driver to balance speed with safety in their production environments. 

##### 为 Nuro 支持运行时间更长的自主智能体

> Powering longer running autonomous agents at Nuro

Nuro 是一家开发通用 L4 级自动驾驶技术的实体人工智能公司，该公司于 2025 年末引入了 Claude Code，到今年 3 月，它已成为公司内最受欢迎的代理式编程工具。

> Nuro, the physical AI company developing universal Level 4 autonomous driving technology, adopted Claude Code in late 2025, and by March it was the most popular agentic coding tool at the company. 

在自动模式发布之前，资深软件工程师 Kai Zhou 就已经开始为一个内部替代方案做原型：一个钩子，把每个待执行的操作发送给一个小模型，其中 90% 的常规操作自动批准，任何敏感操作则转发到 Slack 交由人工审核。这个原型回应了一个真实存在的矛盾：工程师们讨厌一直盯着审批提示，但从公司安全和法务的角度看，直接跳过权限检查又太危险，无法获得许可。当自动模式发布后，Kai 就搁置了这个业余项目。

> Before auto mode shipped, staff software engineer Kai Zhou had already started prototyping an internal stand-in: a hook that sent each pending action to a small model, auto-approved the routine 90 percent of the time, and routed anything sensitive to Slack for a human to review. The prototype answered a real tension: engineers hated babysitting approval prompts, but from a company security and legal standpoint, skipping permissions outright was too dangerous to sanction. When auto mode shipped, Kai shelved the side project. 

如今，Kai 写任何东西都会运行自动模式。

> Today, Kai runs auto mode for everything he writes. 

"我不想坐在那儿一直点同意，"Kai 说。"我 100% 的编程工作都用自动模式。大多数时候，我会同时打开三四个跑着自动模式的会话，需要的时候才去看一眼。"

> "I don't want to sit there and click approve all the time," said Kai. "I use auto mode for 100 percent of my coding work. Most of the time, I open three or four sessions running auto mode in parallel and just check in when I need to.”

例外情况是那些会影响到其他团队的工作。例如，当 Claude Code 代为审查一个 Pull Request 时，Kai 会切换回交互模式，在其发出之前逐一进行审阅。

> The exception is work that touches other teams. For instance, when Claude Code reviews a Pull Request on his behalf, Kai switches back to interactive mode and reviews each one before it goes out.

自动模式也并非毫无约束地运行。Nuro 在很大程度上依赖[技能](https://agentskills.io/home)，而工程师们会在设置中直接禁止最危险的命令，比如递归删除。分类器是在这些防护栏之内做出判断的。

> Auto mode doesn’t run unconstrained, either. Nuro leans heavily on [skills](https://agentskills.io/home), and engineers deny the most dangerous commands, like recursive deletes, outright in their settings. The classifier makes its judgment calls inside those guardrails.

不过，自动模式带来的更大突破，是能够启动那些在工程师下班后仍持续运行的工作。具体来说，Kai 的团队用自动模式驱动长时间运行的研究智能体，让它们不断攀升其自动驾驶技术栈背后的评估指标：这类任务有着清晰、可量化的信号，智能体可以据此自主迭代。

> The bigger auto mode unlock, however, has been the ability to kick off work that keeps running after engineers are done for the day. Specifically, Kai’s team uses auto mode to power long-running research agents that hill-climb the evaluation metrics behind its autonomous-driving stack: tasks with a clear, measurable signal an agent can iterate against on its own. 

在一夜之间，智能体可以研究评估套件标记出的假阴性，起草一份方案，运行实验，并持续对结果进行迭代。这种方法可以推广到任何具有明确评估方式的任务上——Nuro 的另一个团队用它来压缩某个特定二进制文件的内存占用——因为指标本身就会告诉智能体它是在改进还是在退步。

> Overnight, an agent can study false negatives flagged by the evaluation suite, draft a proposal, run experiments, and keep iterating on the results. The approach extends to any task with a clear evaluation method—another team at Nuro uses it to shrink the memory footprint of a specific binary—because the metric itself tells the agent whether it’s improving or regressing.

"前几天，我在晚上 10 点启动了一个 agent，它一直运行到凌晨 5 点——早上给了我三个 PR，"Kai 说。"我觉得这相当令人印象深刻。只有 auto 模式才能支撑这种工作量。"

> "The other day, I kicked off an agent at 10 p.m. and it kept running until 5 a.m.—and it gave me three PRs in the morning," Kai said. "I think it's pretty impressive. Only auto mode enables this kind of workload."

##### 在 Gusto 更快、更安全地交付 PR

> Shipping PRs faster and safer at Gusto

在领先的中小企业技术公司 Gusto，转向自动模式最初是一次主动的安全升级。

> At Gusto, a leading SMB technology company, the move to auto mode started as a proactive security upgrade.

在该公司 AI Dev Tools 团队工作的 Martin Emde 曾目睹权限疲劳拖慢了团队的速度。自动模式在不牺牲控制力和安全性的前提下,让他们获得了同样的速度;而且自从工程团队普遍采用以来,整体的权限负担已明显下降。

> Martin Emde, who works on the company's AI Dev Tools team, had watched permission fatigue slow the team down. Auto mode gave them the same velocity without sacrificing control or security, and since adoption took hold across engineering, the overall permissions burden has noticeably declined.

自去年 12 月以来，Martin 已经启动了 2,425 个 Claude Code 会话，自动模式是他的日常主力。过去那些会卡在文件夹访问授权上的跨仓库工作，现在可以不受打断地跑完；而像从 GitHub、Slack 和 Jira 汇编每日笔记这类无人值守的任务，也能自行运行。在他所在团队自己的分析中，2026 年 5 月中旬以来约有 10% 的会话记录出现过一次自动模式拒绝，这说明分类器确实在发挥作用，同时又没有拖累正当任务。

> Martin has kicked off 2,425 Claude Code sessions since December, with auto mode as his daily driver. Cross-repo work that used to stall on folder-access approvals now runs uninterrupted, and unattended jobs, like compiling daily notes from GitHub, Slack, and Jira, run on their own. In his team’s own analysis, roughly 10% of session transcripts since mid-May 2026 included an auto mode denial, evidence the classifier is doing real work without dragging on legitimate tasks. 

“自动模式让我们在速度与控制之间取得了更安全的平衡，”Martin 说。“我们得以去掉重复的提示确认，在不牺牲安全性的前提下提升了生产力。我们可以看到自动模式会在恰当的时机拦截，这让我们有信心快速推进。”

> “Auto mode gave us a safer balance between speed and control," Martin said. "We were able to remove the repeated prompts and increase productivity without compromising safety. We can see that auto mode blocks at the right time, which gives us the confidence to move quickly."

Gusto AIT 云工程团队成员 Chad Kunsman 从另一个方向得出了相同的结论。他的工作——端点调查、日志审计、连接器管理、跨一组 MCP 服务器的文档摄取——是以二十分钟的短促爆发方式进行的，而不是通宵的马拉松。他并不是在寻求更长的运行时间；他想要的是绕过权限所带来的那种放手不管的节奏，同时又不必承担一个糟糕的提示词、或者一次提示词注入蒙混过关所带来的风险。

> Chad Kunsman, a member of Gusto’s AIT Cloud Engineering team, came to the same conclusion from the other direction. His work—endpoint investigations, log audits, connector management, doc ingestion across a stack of MCP servers—runs in short, twenty-minute bursts rather than overnight marathons. He wasn't looking for longer runs; he wanted the hands-off pace of bypass permissions without the exposure of a bad prompt, or a prompt injection, slipping through.

“考虑到它对提示注入的防护，以及它会检查你正在做的事情是否真的与你所要求的一致，它比绕过权限更好，也比权限提示快得多，”Chad 说。

> "Given the protection against prompt injection, and the way it checks that what you're doing actually lines up with what you asked for, it's the better choice than bypass permissions and far faster than permission prompts," said Chad.

在分类器偶尔介入的少数情况下，Chad 说它判断得很准。“当它拦下我时，那是有道理的，而且它解释了原因。当时确实偏离了我最初问的内容，于是它来确认了一下。它一点都没搞错。”

> On the rare occasions the classifier does step in, Chad says it's on the mark. "When it stopped me, it made sense and explained why. It was drifting from what I'd originally asked, and it checked in. It wasn't off base at all."

在最敏感的工作上，Chad 仍然会退出自动模式。当某个会话深入到生产基础设施时——Terraform、AWS、对线上 API 的直接 POST 调用——他会切换到接受编辑模式，并手动核验每一次工具调用。“你必须权衡自己节省下来的时间，与它可能合理犯下的错误，以及那个错误会有多么灾难性，”他说。“归根结底，发生的一切仍然由你负责。”

> Chad still steps out of auto mode for his most sensitive work. When a session has its teeth into production infrastructure—Terraform, AWS, direct POST calls against live APIs—he switches to accept edits and verifies each tool call by hand. “You have to weigh the amount of time you’re saving against what it could reasonably make a mistake on, and how catastrophic that would be,” he said. “Ultimately, you’re still responsible for what happens.”

这一判断是在更宽泛的纵深防御体系内运作的：Gusto 通过一个受治理的代理层来路由其 MCP 流量，该层具备工具防护和提示检查功能，因此在自动模式介入之前，智能体就已经在严格限定的权限范围内工作。

> That judgment operates inside a broader defense-in-depth setup: Gusto routes its MCP traffic through a governed proxy layer with tool guards and prompt inspection, so agents work with tightly scoped permissions before auto mode ever weighs in. 

##### 加速 Garner Health 的软件开发生命周期（SDLC）

> Accelerating the software development lifecycle (SDLC) at Garner Health

医疗健康技术公司 Garner Health 于二月向全部 550 名员工推广了 Claude Code，覆盖各个职能部门。该工具已接入所有核心系统，包括 Salesforce、Zendesk 和 Snowflake，公司鼓励员工每周花大约两小时，把工作中最具重复性的部分自动化。

> Garner Health, the healthcare technology company, rolled out Claude Code in February to all 550 employees across every function. The tool is wired into all the core systems including Salesforce, Zendesk, and Snowflake, and employees are encouraged to spend about two hours a week automating the most repeatable  parts of their job.

在自动模式出现之前，这种规模是有代价的。Garner 的平台工程经理 Evan Magnussen 将权限管理描述为一个繁琐的循环：手工整理获批命令清单，然后眼看着管道命令被拒绝。

> Before auto mode, that scale came with overhead. Evan Magnussen, Garner's platform engineering manager, describes permission management as a tedious cycle of hand-curating approved command lists and watching piped commands get rejected.

如今，Evan 和他的大多数同事在每个会话中都使用自动模式，从研究代码库到通过 MCP 管理外部集成。

> Today, Evan and most of his colleagues use auto mode in every session, from researching the codebase to managing external integrations through MCP.

“我们为整个工程组织构建了一套标准化的软件开发生命周期，而这真的只有依靠自动模式才可能实现，”Evan 说。“员工们把它视为卸下了肩上的重担。他们再也不必连续几个小时盯着自己的智能体了。"

> “We've built out a standardized software development lifecycle for the entire engineering organization that is really only possible because of auto mode,” Evan said. “Employees view it as a weight off their shoulders. They don’t have to monitor their agents for hours on end anymore."

这套生命周期以标准化技能插件的形式运行。智能体接下任务，探索它有权访问的上下文，将上下文文件提交到仓库，运行 Evan 称之为“对抗性研究”的流程来对自己的假设进行压力测试，然后进入实现阶段——只有在需要自己无法找到的上下文时才暂停下来求助于人类。Evan 指出，这些研究密集的阶段在 auto 模式出现之前是无法实现的。

> That lifecycle runs as a plugin of standardized skills. An agent picks up a task, explores the context it has access to, commits context files to the repository, runs what Evan calls “antagonistic research” to pressure-test its own assumptions, and then moves on to implementation—pausing for a human only when it needs context it can’t find on its own. The research-heavy stages, Evan notes, weren’t possible before auto mode.

开箱即用的分类器几乎不需要调整。Evan 做的唯一一处调整与 Kai 在 Nuro 所做的如出一辙：他将自动模式配置为不批准与他人进行沟通的操作，比如发送 Slack 消息或邮件。

> Out of the box, the classifier has needed little tuning. Evan’s one adjustment mirrors Kai’s at Nuro: he configured auto mode not to approve actions that communicate with other people, like sending Slack messages or emails. 

“我个人不喜欢 Claude 在我与他人沟通时直接代表我行事，”他说。那些从事核心知识产权工作的团队——在自动模式出现之前，他们对跳过权限确认最为存疑——学会了调整分类器注入的提示词，使其对自己的工作或多或少更宽松一些。

> “I personally don’t like Claude to just act on my behalf when I’m communicating with another person,” he said. Teams working on core intellectual property—the most skeptical of skipping permissions before auto mode—learned to tune the classifier’s injected prompts to be more or less permissive for their work.

他对其他正在推广落地的企业有何建议？积极投入，并建立恰当的管控措施，从而在赋能工程师的同时确保安全部署。“如果我们说，大家都去搭建自己的工作流，而我们没有任何遥测数据，那将非常危险，”Evan 说。“正因为我们有遥测数据，正因为我们搭建了相对标准化的工作流，我们才有了更强的信心。”

> His advice for other enterprises rolling it out? Lean in and build the right controls so that you can empower engineers while ensuring safe deployment. “If we were to say, everyone go build your own workflows, and we have no telemetry, that would be very dangerous,” Evan said. “Because we have the telemetry, because we’ve built out workflows that are relatively standard, we have much more confidence.”

***开始使用 ***[自动模式 ](https://code.claude.com/docs/en/auto-mode-config)**，在 Claude Code 中。**

> ***Get started with ***[auto mode ](https://code.claude.com/docs/en/auto-mode-config)**in Claude Code.**

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| auto mode | 自动模式 | Claude Code 中由分类器自动评估并放行或拦截代理操作的运行模式。 |
| agentic coding | 智能体编码 | 由 AI 代理自主执行多步骤编程任务的开发方式。 |
| classifier | 分类器 | 对每个待执行操作判定是否有害并决定放行或拦截的模型组件。 |
| prompt injection | 提示注入 | 通过外部输入植入恶意指令、诱使模型偏离原始任务的攻击手法。 |
| scope drift | 范围漂移 | 代理执行过程中逐渐偏离用户最初请求边界的现象。 |
| red teaming | 红队测试 | 由独立团队模拟攻击者对系统防护能力进行对抗性检验。 |
| hook | 钩子 | 在代理执行流程的特定环节插入自定义逻辑的扩展机制。 |
| MCP (Model Context Protocol) | 模型上下文协议 | 让模型以标准化方式连接外部工具与数据源的协议。 |
| pull request | 拉取请求 | 版本控制中提交代码变更并请求合并与评审的流程单元。 |
| false negative | 假阴性 | 评估或检测中本应被标记为问题却被判为正常的样本。 |
| eval suite | 评估套件 | 用于量化衡量系统表现的一组标准化测试与指标集合。 |
| defense in depth | 纵深防御 | 通过多层相互独立的防护措施降低单点失效风险的安全策略。 |
| SDLC (Software Development Life Cycle) | 软件开发生命周期 | 从需求到交付维护的软件开发各阶段的标准化流程框架。 |
| telemetry | 遥测数据 | 系统运行过程中自动采集的使用与行为数据，用于监控和评估。 |
| guardrails | 防护栏 | 预先设定的硬性限制，划定代理不得逾越的操作边界。 |
| accept edits mode | 接受编辑模式 | 仅自动放行文件编辑、其余工具调用仍需人工核验的运行模式。 |
