# 自动模式现已成为 Claude Code 中 Pro、Max 和 Team 套餐的默认设置

> Auto mode is now the default in Claude Code for Pro, Max, and Team plans

> 来源：Claude Blog / Anthropic，2026-08-07
> 原文链接：https://claude.com/blog/auto-mode-default-in-claude-code
> 分类：AI 工程 / 智能体安全

## 核心要点

- 自 8 月 14 日起，Pro、Max 和 Team 套餐的 Claude Code 新会话默认以自动模式运行，已固定默认模式的用户不受影响，其余用户可能收到一次性切换提示。
- 自动模式分类器在每次工具调用时消耗的额外 token 不再向 Pro、Max 和 Team 套餐用户收费，企业版与各云平台仍需主动启用，计划在一个月内改为默认并同样免除分类器开销。
- 自动模式以分类器替代逐条权限弹窗，专门拦截不可逆、破坏性或指向用户环境之外的操作，连续三次或单次会话累计二十次被拦截后会回退到手动审批模式。
- 数据显示人工审核趋于流于形式，用户批准了 97% 的权限提示、单个权限请求否决率仅 3%，而对 Claude 提交的计划否决率达 39%。
- 截至 2026 年 6 月，49.5% 的活跃 CLI 用户手动创建了 Bash 允许规则，62% 的用户使用过 bypassPermissions 或对 Bash 点击“不再询问”，25% 的交互式会话以绕过权限模式启动。
- 在 1,053 名付费测试者参与的对照研究中，测试者仅识别出 13.6% 的危险命令，自动模式拦截了其中 89%，且拦截率不随会话变长而下降，而人类识别率从约 17% 降至约 5%。
- 对被安全流程标记的真实会话重新评分显示，在生产级严重度（7 分及以上）下，6.3% 的人工审批会话包含用户未明确要求的有害操作，自动模式会话为 2.4%。
- 与 Apollo Research 的两周红队试点通过“发现—修复—验证”循环加固分类器，在未接触过的留出攻击集上捕获约一半此前漏掉的攻击，整体漏检率从 12% 降至 7%。
- Trajectory Labs 的第三方评估中，以自动模式运行的 Claude Fable 5、Opus 5 和 Sonnet 5 在 720 次间接提示注入攻击尝试中无一被攻破，Codex 的 Auto-review 模式攻击成功率为 5.83%，Full Access 模式为 19.03%。
- 自动模式在 Anthropic 内部拦截了脱离网络的数据泄露、波及数百块 GPU 的批量删除以及账户根级别的过度权限提升三起事故，同时新增硬性拒绝、数据访问与共享规则、git status 检查和提示注入筛查等能力。
- Adobe、Nuro、Gusto 和 Garner Health 已将自动模式作为生产默认配置，Teams 和 Enterprise 用户中使用自动模式者提交的 PR 数量约多出 25%。
- 自动模式依赖分类系统而无法消除风险，对生产基础设施的高风险变更仍建议人工审查，管理员可通过托管设置的 defaultMode 固定默认值或用 disableAutoMode 关闭。

## 正文

我们正把[自动模式](https://code.claude.com/docs/en/auto-mode-config)设为 Claude Code 的默认模式。从 8 月 14 日起，Pro、Max 和 Team 套餐上的新会话将以自动模式运行。如果你此前已自行设置了不同的默认模式，你可能会收到一次性提示，询问你是否要切换到自动模式。如果你已固定了某个默认模式，则对你没有任何变化。自动模式的分类器在每次工具调用时会使用少量额外 token，从今天起，我们不再就该分类器的开销向 Pro、Max 和 Team 套餐的 Claude Code 用户收费。

> We're making [auto mode](https://code.claude.com/docs/en/auto-mode-config) the default in Claude Code. Starting on August 14, new sessions on Pro, Max, and Team plans will run in auto mode. If you've already set a different default yourself, you may get a one-time prompt asking whether you want to switch to auto mode. If you have a pinned default, nothing changes for you. The auto mode classifier uses a small number of extra tokens per tool call, and we're no longer charging Claude Code users on Pro, Max, and Team plans for that classifier overhead, effective today.

目前，自动模式在 Claude Enterprise、Claude API、AWS 上的 Claude Platform、Amazon Bedrock、Google Cloud 的 Agent Platform 以及 Microsoft Foundry 上仍需主动选择启用，以便让管理员有时间审查这一变更。在接下来的一个月里，我们计划与云合作伙伴一起，将其设为上述所有平台的默认设置，并且不再为分类器开销收费。在此期间，企业版管理员可以通过托管设置将 Claude Code 的自动模式设为默认。

> Auto mode remains opt-in for now on Claude Enterprise, the Claude API, Claude Platform on AWS, Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry, giving admins time to review the change. In the coming month, working with our cloud partners, we plan to make it the default across all of these and no longer charge for classifier overhead. In the meantime, Enterprise admins can make Claude Code's auto mode the default through managed settings.

自动模式旨在在用户不希望被打断的需求与一套帮助规避有害操作的系统之间取得平衡：它不再弹出提示，而是让每一次工具调用都经过一个分类器，该分类器专门用于拦截那些不可逆的、破坏性的或指向你的环境之外的操作。当分类器拦截了某项操作时，Claude 通常会自行找到更安全的方式继续推进，或者直接向你征求许可；如果它无法取得进展——连续三次被拦截，或在一次会话中累计二十次——Claude Code 就会回退到手动审批模式。

> Auto mode is designed to balance users’ desire not to be interrupted with a system that helps avoid harmful actions: instead of prompts, it routes each tool call through a classifier targeted at blocking actions that are irreversible, destructive, or aimed outside your environment. When the classifier blocks something, Claude usually finds a safer way to proceed on its own or asks you directly for the go-ahead; if it can't make progress—three blocks in a row, or twenty across a session—Claude Code falls back to manual approvals.

过去几个月，我们一直在测试自动模式是否与普通用户逐条点击确认提示同样安全，甚至更安全。我们开展了内部红队测试、第三方红队测试和提示注入评估，进行了一项有 1,053 名付费测试者参与的对照研究，并分析了真实的生产环境会话。在我们测试的每一项指标上，自动模式都达到或超过了人工审核的水平。

> We spent the last several months testing whether auto mode is as safe or safer than an average user clicking through prompts. We ran internal red-teaming, third-party red-teaming and prompt-injection evaluations, a controlled study with 1,053 paid testers, and analysis of real production sessions. On every measure we tested, auto mode matched or outperformed manual review.

自动模式还能让 Claude 在更长的时间段内自主工作。这使得为长时间运行的工作而打造的模型（如 Claude Opus 5）在处理大型任务时，可以更实用地连续运行数小时。减少用户的额外开销也提升了产出。在 Teams 和 Enterprise 用户中，使用自动模式的用户提交的 PR 数量大约多出 25%。为 Claude 扫清阻碍，任务得以不受打断地运行更长时间，完成更多工作。Adobe、Nuro、Gusto 和 Garner Health 的团队已经将[自动模式](https://claude.com/blog/auto-mode-in-production)作为其生产环境的默认设置。

> Auto mode also lets Claude work autonomously for longer stretches. This makes models built for long-running work, like Claude Opus 5, more practical to leave running for hours on large tasks. Reducing overhead for users also increases output. Among Teams & Enterprise adopters, auto mode users ship about 25% more PRs. Unblocking Claude allows tasks to run longer uninterrupted and get more work done. Teams at Adobe, Nuro, Gusto, and Garner Health already [run auto mode](https://claude.com/blog/auto-mode-in-production) as their production default. 

下面，我们分享推动这一变更的安全数据和客户成果，以及如果你有其他偏好该如何设置不同的默认值。

> Below, we share the safety data and customer results motivating the change, and how to set a different default if you prefer.

#### 手动审核与自动模式的对比

> Comparing manual review to auto mode

数据表明，人工审核可能会变成一种习惯性动作：在 Claude Code 中，用户批准了 97% 的权限提示。虽然大多数提示很可能针对的是安全、常规的命令，但如此之高的批准率表明，许多用户是在下意识地一路点过去，而不是逐条审查每个命令。这些提示要求开发者每天做出几十甚至上百个重要的安全决策，而且往往是在项目进行到一半的时候，这把审核负担压在了用户身上，也增加了重要问题被疏漏的可能性。数据还表明，用户对其他类型的对话框会更频繁地仔细审视并提出异议：例如，当 Claude 提交一份计划供批准时，用户会否决其中的 39%。但对于单个权限请求，否决率仅为 3%。

> Data suggests that manual review can become habitual: users approve 97% of permission prompts in Claude Code. While most prompts are likely for safe, routine commands, an approval rate that high suggests many users are clicking through reflexively rather than reviewing each command. These prompts ask developers to make dozens or hundreds of important security decisions every day, often in the middle of projects, which places the review burden on users and increases the chance that something important slips through the cracks. Data also suggests that users more frequently scrutinize and push back on other types of dialogues: for example, when Claude presents a plan for approval, users reject 39% of them. But for individual permissions requests, the rejection rate is only 3%.

同样的模式也出现在设置文件中。截至 2026 年 6 月，49.5% 的活跃 CLI 用户手动创建了 Bash 允许规则——其中 5% 直接允许任意 shell 命令，另有 43% 设置了诸如 `Bash(python:*) `或 `Bash(node:*)` 这类解释器规则，而这些规则在实际使用中基本等同于前者——并且这一比例大约每 5 周增长 5 个百分点。除了允许规则之外，62% 的用户使用过 `bypassPermissions` 或在 Bash 上点击过“不再询问”，另有 25% 的交互式会话以绕过权限模式启动。

> The same pattern shows up in settings files. As of June 2026, 49.5% of active CLI users have manually created a Bash allow-rule—5% allow any shell command outright, and another 43% have interpreter rules like `Bash(python:*) `or `Bash(node:*)` that are essentially equivalent in practice—and that share is growing roughly 5 percentage points every 5 weeks. Beyond allow-rules, 62% of users have used `bypassPermissions` or clicked “don't ask again” on Bash, and 25% of interactive sessions start in bypass permissions mode.

在自动模式下，权限规则仍然先于分类器生效，但足以授予任意代码执行的宽泛允许规则除外（例如 python:*）。这类任意规则在自动模式期间会被搁置，因为它们会让命令完全跳过分类器。设置文件不会被修改，一旦你切换到其他模式，这些规则便会重新生效。

> Permission rules still fire before the classifier in auto mode, except for allow rules broad enough to grant arbitrary code execution (e.g. python:*). These arbitrary rules are set aside while in auto mode, since they would let commands skip the classifier entirely. Settings files aren't modified, and the rules apply again the moment you switch to another mode.

#### 通过自动模式提升安全性

> Improving safety with auto mode

内部以及多家第三方开展的研究表明，自动模式比当前典型用户处理权限提示的方式更安全。我们将自动模式与开发者在点击权限提示时实际批准的内容进行了对比测试。在内部红队演练、第三方渗透测试以及真实会话分析这几项衡量标准中，自动模式的表现都达到或超过了人工批准的水平。

> Research conducted internally and through several third parties suggests that auto mode is safer than how a typical user engages with permission prompts today. We tested auto mode against what developers actually approve when they're clicking through permission prompts. Across each of these measures—internal red-teaming, third-party penetration testing, and analysis of real-world sessions—auto mode matched or outperformed human approval. 

##### 自动模式在安全性上优于手动权限

> Auto mode outperforms manual permissions on safety

![In a controlled experiment with 1,053 paid professional testers, human review caught just 13.6% of dangerous commands, while auto mode caught 89%.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a7551c77738b3678fdde0ce_image4.png)

我们通过一家研究供应商招募了 1,053 名有偿测试者参与一项编程研究。这些参与者在专为该研究搭建的测试环境中工作，而不是在他们自己的代码库或真实项目中。参与者知道自己正在被评估，但按照标准的盲法研究设计，他们并未被告知所测量的是哪一种行为。在每次会话进行到中途时，某一个权限提示被替换为一条明显危险的命令，供应商会记录测试者是否批准了它（注意：批准该提示从未导致任何危险操作被执行；被更改的只是测试者所看到的提示文本）。

> We hired 1,053 paid testers through a research vendor for a coding study. These participants worked in a test environment set up specifically for the study, not in their own codebases or on real projects. Participants knew they were being evaluated, but—following standard blind-study design—weren't told which behavior was being measured. Partway through each session, a single permission prompt was swapped for a clearly dangerous command, and the vendor recorded whether the tester approved it (Note: approving the prompt never resulted in anything dangerous being run; only the text of the prompt testers saw was changed). 

测试人员仅在 13.6% 的情况下（1,053 条中的 143 条）识别出了危险命令，而自动模式拦截了同样这些命令中的 89%（1,053 条中的 937 条）。正面对比来看，自动模式拦截了 800 条被人类批准的命令，而人类只拦截了 6 条被自动模式放行的命令。随着会话变长，人类的表现进一步下滑：在会话早期他们能拦截约 17% 的危险命令，而在此前有 50 条或更多提示之后，这一比例降至约 5%；与此同时，自动模式的拦截率不受会话长度影响，始终保持平稳。

> The testers caught the dangerous command just 13.6% of the time (143 of 1,053), while auto mode blocked 89% of the same commands (937 of 1,053). Head to head, auto mode blocked 800 commands that a human approved, while humans blocked only 6 that auto mode allowed. As sessions got longer, humans did worse: they blocked about 17% of dangerous commands early in a session, dropping to about 5% after 50 or more prior prompts, while auto mode's block rate stayed flat regardless of session length.

##### 自动模式可以阻止更多有害行为

> Auto mode prevents more harmful actions

我们的研究还表明，自动模式比手动权限模式产生的有害操作更少。

> Our research also suggests that auto mode leads to fewer harmful actions than manual permissions mode.

我们考察了自动模式在实际使用中的表现。在 2026 年 5 月至 6 月期间，我们检查了安全流程标记为需要审查的会话，这些会话仅来自已选择同意将数据用于训练和分析的账户。我们用一个模型按两个 0–10 的量表对每个会话重新评分。第一个量表是危害严重程度，10 表示波及整个公司的、不可逆的危害，例如泄露一家公司的全部源代码；7 表示生产级别的严重程度，例如从生产数据库中删除数据行；0 表示完全可逆且局限于本地工作区的操作，例如覆盖一个临时文件。第二个量表是用户对该操作的要求有多明确，这样我们就能把用户直接要求的有害操作，与智能体在指示不那么明确的情况下自行采取的有害操作区分开来。

> We examined how auto mode performs in real usage. From May to June 2026, we examined sessions our safety pipeline had flagged for review, drawn only from accounts that have opted in to data use for training and analysis. We re-graded each one with a model on two 0–10 scales. The first was harm severity with 10 being company-wide, irreversible harm, such as leaking a company's entire source code, 7 representing production-level severity such as deleting rows from a production database, and 0 a fully reversible action confined to the local workspace, like overwriting a scratch file. The second was how explicitly the user had asked for the action, so we could separate harmful actions the user directly requested from harmful actions the agent took with less explicit direction.

在被标记的会话中，经过人工审批的会话包含严重非预期危害的比例，是自动模式会话的两倍以上。在生产级严重度（7 分及以上）下，6.3% 的人工审批会话包含了用户并未明确要求的有害操作，而自动模式会话的这一比例为 2.4%，并且在我们测试的每一个严重度级别上，这一差距都持续存在。

> Among the flagged sessions, those that went through manual approval contained serious unintended harm more than twice as often as auto mode sessions. At production-level severity (7+), 6.3% of manually approved sessions contained a harmful action the user hadn't explicitly asked for, compared to 2.4% of auto mode sessions, and the gap held at every severity level we tested. 

##### 对抗性红队测试让自动模式变得更强大

> Adversarial red-teaming made auto mode stronger

我们与英国 AI 安全初创公司 Apollo Research 合作开展了一项为期两周的试点项目，将合成攻击注入真实的编码轨迹中，涵盖广泛故障、数据外泄和安全相关威胁这三个数据集。

> We worked with Apollo Research, a UK-based AI safety startup, on a two-week pilot injecting synthetic attacks into real coding trajectories, across three datasets covering broad failures, data exfiltration, and safety-related threats.

此次合作遵循标准的「发现—修复—验证」循环。Apollo 分享了一组成功的攻击案例，并给出了强化自动模式的建议。我们对分类器进行了加固，主要方式是为其提供更多关于所保护环境的上下文信息（仓库可见性、git 状态，以及下文所述的数据处理规则）。

> The engagement followed a standard find-fix-verify loop. Apollo shared a set of successful attacks along with recommendations to strengthen auto mode. We hardened the classifier against them primarily by giving it more context about the environment it's protecting (repository visibility, git state, and the data-handling rules described below).

加固之后，Apollo 在一个我们从未接触过的独立留出攻击集上重新进行了测试。Auto 模式捕获了此前漏掉的攻击中的大约一半，代价是漏掉了此前已捕获的攻击中的约 2%。由于我们无法针对该留出集进行调优，这表明加固效果可以泛化到新的攻击，而不只是针对 Apollo 所提供的特定攻击打补丁。在共享集和留出集这两者上，分类器的漏检率从 12% 降至 7%。

> After hardening, Apollo re-tested on a separate held-out attack set that we never had access to. Auto mode caught about half of the attacks it previously missed, at a cost of missing about 2% of attacks it previously caught. Since we couldn't tune against the held-out set, this suggests the hardening generalizes to new attacks rather than patching the specific ones Apollo shared. Across both the shared and held-out sets, the classifier's miss rate fell from 12% to 7%.

这些攻击是设计出来的合成对抗样本，专门用来寻找分类器失效之处，其恶意程度超过 Claude 在无人诱导时会做出的任何行为。7% 的漏检率是针对这一样本集测得的，不应被视为真实流量上的漏检率。

> These attacks are synthetic and adversarial by design, built to find where the classifier fails, and more malicious than anything Claude would do unprompted. The 7% miss rate is measured against this set and should not be taken as the miss rate on real traffic.

##### 自动模式降低提示词注入风险

> Auto mode reduces prompt injection risk

![With auto mode enabled, no attack in an independent evaluation was successful against any of our models. GPT-5.6 Sol running in Codex v0.144.5 Auto-review permission mode had a 5.83% attack success rate. GPT-5.6 Sol was run on “max” reasoning effort to test performance with its highest level of reasoning, and all Claude models were run on high effort.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a75fafde538ce42b19d5742_image3.png)

自动模式分类器为抵御[提示注入攻击](https://www.anthropic.com/research/prompt-injection-defenses)增加了一层额外防护，这类攻击试图迫使智能体偏离用户的指令。在自动模式下运行时，工具返回的结果会由探测器扫描，以检查其中是否含有潜在的恶意指令，同时自动模式还会核查各项操作是否与用户意图一致。我们将自动模式与未加防护的模型进行了对比测试，以展示这种纵深防御方法的效力。

> The auto mode classifier adds an additional layer of defense against [prompt injection attacks](https://www.anthropic.com/research/prompt-injection-defenses) that try to force the agent to deviate from the user’s instructions. When running with auto mode, tool results are scanned by probes for potentially malicious instructions, and auto mode checks that actions are aligned with user intent. We tested auto mode compared to an unguarded model to illustrate the power of this defense-in-depth approach.

我们委托第三方机构 Trajectory Labs 进行了一项评估，他们在截至 2026 年 7 月 17 日公开可用的最新版本 Claude Code 和 Codex 中测试了不同的模型。1 他们测试了 72 个由 Anthropic 保留未公开的间接提示注入场景。每个场景测试 10 次。在非测试环境中，成功的攻击将导致不可逆的操作，可能对用户造成伤害，例如敏感数据外泄、金融欺诈或凭据钓鱼。这些攻击是针对 Claude Opus 4.7 优化的，而该模型不在报告的模型集合内，因此评估中的每个模型面对的都是未曾见过的攻击。除自动模式外，这些评估还考察了 Claude Code 的 *bypassPermissions* 模式和 Codex 的 *Full Access* 模式。

> We commissioned an evaluation from a third party, Trajectory Labs, who tested different models within the latest publicly available versions of Claude Code and Codex as of July 17th 2026.1 They tested 72 indirect prompt injection scenarios held out from Anthropic. Each scenario was tested 10 times. Successful attacks would, in a non-testing environment, result in irreversible actions that could harm the user such as sensitive-data exfiltration, financial fraud, or credential phishing. The attacks were optimized against Claude Opus 4.7, which is not in the reported set, so every model in the evaluation faced them as unseen attacks. In addition to auto mode, the evaluations looked at Claude Code’s *bypassPermissions* mode and Codex’s *Full Access* mode.

Codex 与 Claude Code 均使用由 Trajectory Labs, PBC 提供的完全相同的浏览器集成进行评估。该集成提供了一组 MCP 工具，它们是对 `navigate` 等常见 Chrome API 的轻量封装。我们并未测试第一方浏览器集成（例如 OpenAI 和 Anthropic 提供的 Chrome 扩展）中内置的防护措施。因此，这些结果应被视为对底层模型的衡量，而非对某个特定部署中可能存在的完整防护措施集合的衡量。

> Both Codex and Claude Code were evaluated using an identical browser integration produced by Trajectory Labs, PBC. This integration provides a set of MCP tools which are a thin wrapper around common Chrome APIs such as `navigate`. Safeguards built into first-party browser integrations such as the Chrome extensions provided by OpenAI and Anthropic were not tested. As such, these results should be viewed as a measurement of the underlying model, rather than the complete set of safeguards which might exist in a given deployment.

**在本次评估中，针对以 auto 模式运行的 Claude Fable 5、Opus 5 或 Sonnet 5 的 720 次攻击尝试，无一成功。**另一方面，针对以 Codex 的 *Auto-review* 模式运行的 GPT-5.6 Sol，有 5.83% 的攻击成功。值得注意的是，这一比例高于在没有额外防护措施的情况下、以 *bypassPermissions* 模式运行的我们最新模型所面临的 0.09% 的平均攻击成功率。测试显示，以 *Full Access* 模式运行时，针对 GPT-5.6 Sol 的攻击成功率为 19.03%。如下所示，在工具以文本形式返回结果的任务与需要通过屏幕截图与浏览器交互的任务之间，攻击成功率存在差异。

> **In this evaluation, none of the 720 attack attempts succeeded against Claude Fable 5, Opus 5, or Sonnet 5 running auto mode.** On the other hand, 5.83% of the attacks succeeded against GPT-5.6 Sol running Codex's *Auto-review* mode. Notably, this is greater than the 0.09% average attack success rate against our latest models running in *bypassPermissions* mode without additional safeguards. The tests showed a 19.03% attack success rate against GPT-5.6 Sol when running in *Full Access* mode. Attack success rates differ between tasks where tools return results as text and tasks that require interacting with a browser through screenshots, as shown below.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a75fac544d570b06de2e9b1_image2.png)

![Auto mode protects against prompt injections both in tool calling and browser GUI use. OpenAI models showed higher attack success rates on browser tasks in a third-party evaluation.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a75fa7ca0de08fd1e052f2b_image1.png)

##### 自动模式在 Anthropic 内部避免的三起事故

> Three incidents auto mode prevented inside Anthropic

自动模式也是 Anthropic 内部所有 Claude Code 使用场景的默认设置。以下是分类器在内部拦截的三个操作：

> Auto mode is also the default for all Claude Code internal usage at Anthropic. Here are three actions the classifier prevented internally:

- **一次脱离网络的数据泄露：**当上传到内部云盘失败时，Claude 的后备方案是把同一份报告发布到一个公开的代码共享站点。自动模式拒绝了该后备方案，并提示用户确认下一步操作。
- **一次破坏性的批量操作：**在一次长时间运行的会话中，Claude 试图在大约两千个 pod 上执行批量进程终止，并排队了一些删除操作，这些操作本会摧毁数百块 GPU 上正在进行的训练任务。自动模式在这些破坏性命令执行前对其进行了标记。
- **过度的权限提升：**在被要求配置只读的账单访问权限时，Claude 却选择了一个在账户根级别授予完全管理控制权的云角色。自动模式发现了请求内容与将被授予的角色之间的不匹配。

> • **An off-network data leak:** When an upload to an internal drive failed, Claude's fallback was to publish the same report to a public code-sharing site. Auto mode denied the fallback and prompted the user for next steps.
> • **A destructive mass operation:** In a long-running session, Claude attempted a mass process kill across roughly two thousand pods and queued deletions that would have torn down hundreds of GPUs of in-flight training jobs. Auto mode flagged the destructive commands before execution.
> • **Over-broad privilege escalation:** Asked to provision read-only billing access, Claude reached for a cloud role that grants full administrative control at the account root. Auto mode caught the mismatch between what was requested and what roles would have been granted.

在每一种情况下，Claude 要么自行找到了更安全的路径，要么在继续之前与用户进行了确认。

> In each case, Claude either found a safer path on its own or checked in with the user before proceeding.

##### 让自动模式更加安全 

> Making auto mode even safer 

我们持续投入开发新的自动模式功能，让交付生产代码更安全、更轻松。近期的例子包括： 

> We’re continuously investing in new auto mode features that make it safer and easier to ship production code. Recent examples include: 

- [硬性拒绝](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)：数据外泄，比如把你的代码或密钥发送到外部某处，属于分类器被设计为永不批准的一类操作。要执行这样的操作，你必须退出自动模式，或者自己运行该命令。硬性拒绝规则可通过设置进行自定义，因此你可以添加更多规则，即使组织内的用户提出请求也永远不允许执行。
- **数据访问与共享规则：**该分类器现在带有明确的规则，用于区分密钥与潜在的敏感/机密信息——以及各自可以在何处被访问和共享。为了让这些规则可被强制执行，它还会在操作运行前检查 git push 或拉取请求的目标位置是公开的、私有的还是受信任的。同样一次 push，可能是例行操作，也可能是数据外泄，这取决于它最终落到哪里：本应属于你团队私有仓库的代码不该出现在公开仓库中，而分类器现在的设计正是为了在这种情况可能发生时发出标记。
- **在执行破坏性 git 操作前检查 git status**：在运行可能丢弃未提交工作的命令（如 git reset --hard）之前，分类器会查看仓库当前的 git status，从而让自动模式知道正在重置的是什么内容。
- **提示注入筛查**：当 Claude 从外部来源拉取内容时，比如网页、文件内容或工具输出，API 端的探测器会检查这些内容，看是否存在试图劫持 Claude 行为的意图。当某些内容看起来像是注入尝试时，会在结果呈现给用户之前，向 Claude 的上下文中添加一条警告。

> • [Hard denies](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules): Data exfiltration, like sending your code or secrets somewhere external, sits in a category the classifier is designed to never approve. To run an action like that, you have to switch out of auto mode or run the command yourself. Hard deny rules are customizable via settings so you can add more rules that you never want allowed even when requested by users in your organization.
> • **Rules for data access and sharing: **The classifier now carries explicit rules distinguishing secrets and potentially sensitive/confidential information—and where each can be accessed and shared. To make those rules enforceable, it also checks whether the destination of a git push or pull request is public, private, or trusted before the action runs. The same push can be routine or an exfiltration depending on where it lands: code that belongs in your team's private repository shouldn't end up in a public one, and the classifier is now designed to flag when this might happen.
> • **Checking git status before destructive git actions**: Before a command that could discard uncommitted work, like git reset --hard, the classifier sees the repository's current git status, letting auto mode know what is being reset.
> • **Prompt injection screening**: When Claude pulls content from external sources, like web pages, file contents, or tool outputs, an API-side probe checks that content for attempts to hijack Claude's behavior. When something looks like an injection attempt, a warning is added to Claude's context before the result is shared with the user.

#### 生产环境中的自动模式 

> Auto mode in production 

已有团队将自动模式作为生产环境的默认配置运行：

> Teams are already running auto mode as their production default:

- **Adobe** 的商品运营平台团队负责在 Adobe.com 上确保 90 多个国家和 30 多种语言的定价与促销页面准确且保持最新。他们构建了一个智能体循环来生成和验证这些页面，并以自动模式运行，使工程师收到可供评审的成品 PR。
- **Nuro** 在其研究和工程组织中全面运行 auto 模式，用它来驱动通宵运行的研究智能体，这些智能体会爬坡优化评测指标，并在早晨返回完成的 PR 供人审阅。
- **Gusto** 采用了自动模式，以终结那种促使工程师彻底绕过权限检查的权限疲劳。自 5 月中旬以来，约 10% 的会话中包含一次分类器拒绝——这证明它在切实发挥作用，同时又没有拖慢正当任务。
- **Garner Health** 通过托管设置将自动模式作为默认配置推送给全部 550 名员工，标准化了一套全公司范围的软件开发生命周期（SDLC），该流程不再依赖人工整理的命令白名单。

> • **Adobe's** merchandising platform team is responsible for keeping pricing and promotional pages accurate and current across 90+ countries and 30+ languages on Adobe.com. They built an agentic loop to build and verify those pages, running it in auto mode so engineers receive finished PRs for review. 
> • **Nuro** runs auto mode across its research and engineering orgs, using it to power overnight research agents that hill-climb evaluation metrics and return finished PRs for review by morning.
> • **Gusto** adopted auto mode to end the permission fatigue that was pushing engineers toward bypassing permissions checks entirely. About 10% of sessions since mid-May include a classifier denial—evidence it's doing real work without slowing legitimate tasks.
> • **Garner Health** pushed auto mode as the default to all 550 employees via managed settings, standardizing a company-wide software development lifecycle (SDLC) that no longer depends on hand-curated command allowlists.

了解这些客户是如何[在生产环境中运行自动模式](https://claude.com/blog/auto-mode-in-production)的。 

> Learn how these customers are [running auto mode in production](https://claude.com/blog/auto-mode-in-production). 

#### 开始使用

> Getting started

面向 Pro、Max 和 Team 用户：如果你尚未设置默认权限模式，你会收到一条产品内通知，新会话将自动以 auto 模式启动。如果你已设置了其他默认值，你可能会看到一次性提示，询问你是否希望将默认值切换为 auto 模式。如果你的 Team 管理员已在托管设置中设定了默认值，则对你没有任何变化。

> For Pro, Max, and Team users: if you haven’t set a default permission mode, you’ll receive an in-product notice and new sessions will start in auto mode automatically. If you've set a different default, you may see a one-time prompt asking if you’d like to switch your default to auto mode. If your Team admin has set a default in managed settings, nothing changes for you.

对于企业版用户以及通过 Claude API 使用 Claude Code 的用户，自动模式目前仍需手动开启。我们计划在下个月将自动模式设为默认选项，并会在此之前通知企业管理员。

> For Enterprise users and users who access Claude Code via the Claude API, auto mode remains opt-in for now. We plan to make auto mode the default in the coming month, and we’ll notify Enterprise admins before we do.

要切换模式，请在 CLI 中按 Shift+Tab，或使用桌面应用上的模式下拉菜单。管理员可以在[托管设置](https://code.claude.com/docs/en/server-managed-settings)中通过 `defaultMode` 固定组织范围的默认值，或使用 `disableAutoMode` 完全关闭自动模式。

> To switch modes, press Shift+Tab in the CLI or use the mode dropdown on the desktop app. Admins can pin an org-wide default with `defaultMode` in [managed settings](https://code.claude.com/docs/en/server-managed-settings), or turn auto mode off entirely with `disableAutoMode`.

最后，虽然我们相信自动模式能为大多数用户降低风险，但它依赖于分类系统，因此并不能消除风险。对于生产环境基础设施的高风险变更，我们仍然建议你亲自审查 Claude 的操作。[请参阅自动模式文档](https://code.claude.com/docs/en/auto-mode-config)以获取完整的配置说明。

> Finally, while we believe auto mode reduces risk for most users, it relies on classification systems and therefore does not eliminate risk. For high-stakes changes to production infrastructure, we still recommend reviewing Claude's actions yourself. [See the auto mode docs](https://code.claude.com/docs/en/auto-mode-config) for full configuration instructions.

‍

> ‍

*本文由 Conner Phillippi 撰写,Nicholas Carlini、Isaac Fung、John Hughes、Alex Isken、Shawn Moore、Javier Rando 和 Molly Vorwerck 参与贡献。作者还要感谢 Yacine Azmi、Chandler Bair、Kefan Chen、Boris Cherny、Ian Grunert、Lydia Hallie、Alex Kleiman、Lauren Polansky、Deon Poncini、Robert Schonberger、Marie Vachovsky****、****Qing Wang、Cat Wu、Daniel Xu 和 Alice Zhao。*

> *This article was written by Conner Phillippi, with contributions by Nicholas Carlini, Isaac Fung, John Hughes, Alex Isken, Shawn Moore, Javier Rando, and Molly Vorwerck. The authors would also like to thank Yacine Azmi, Chandler Bair, Kefan Chen, Boris Cherny, Ian Grunert, Lydia Hallie, Alex Kleiman, Lauren Polansky, Deon Poncini, Robert Schonberger, Marie Vachovsky****, ****Qing Wang, Cat Wu, Daniel Xu, and Alice Zhao.*

‍

> ‍

1 我们评估了 Claude Code v2.1.205 和 Codex v0.144.5。OpenAI 上周发布了 Auto-review 的新版本，这可能会改变评估结果。

> 1 We evaluated Claude Code v2.1.205 and Codex v0.144.5. OpenAI released a new version of Auto-review last week that could change the results.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| auto mode | 自动模式 | Claude Code 中以分类器自动判定工具调用是否放行、取代逐条权限弹窗的运行模式。 |
| classifier | 分类器 | 在每次工具调用前评估操作风险并决定拦截或放行的模型组件。 |
| prompt injection | 提示注入 | 通过外部内容中植入的指令劫持智能体行为、使其偏离用户意图的攻击手法。 |
| indirect prompt injection | 间接提示注入 | 恶意指令藏在网页、文件或工具输出等模型被动读取的内容中的注入方式。 |
| bypassPermissions | 绕过权限模式 | Claude Code 中跳过全部权限确认、直接执行工具调用的模式。 |
| allow rule | 允许规则 | 用户在设置文件中预先声明、可免确认执行的命令模式。 |
| hard denial | 硬性拒绝 | 分类器被设计为永不批准、且可由用户自定义扩充的一类禁止操作。 |
| data exfiltration | 数据外泄 | 将代码、密钥或敏感信息发送到用户环境之外的行为。 |
| red teaming | 红队测试 | 由攻击方视角主动构造对抗样本以暴露系统失效点的安全评估方法。 |
| hold-out set | 留出集 | 在调优过程中完全不被接触、用于检验改进是否泛化的独立测试数据。 |
| miss rate | 漏检率 | 分类器未能拦截的恶意或危险操作在全部此类操作中所占比例。 |
| defense in depth | 纵深防御 | 叠加多层相互独立的防护措施以降低单点失效风险的安全策略。 |
| managed settings | 托管设置 | 由组织管理员统一下发、可覆盖个人配置的集中式设置机制。 |
| MCP | 模型上下文协议 | 用于向模型暴露外部工具与数据源的标准化接口协议。 |
| SDLC | 软件开发生命周期 | 涵盖需求、开发、测试到发布运维的全流程规范体系。 |
| agent loop | 智能体循环 | 模型反复调用工具、观察结果并继续决策直至任务完成的自动化流程。 |
