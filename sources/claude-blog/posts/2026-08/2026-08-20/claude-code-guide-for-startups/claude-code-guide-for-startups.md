# 面向初创公司的 Claude Code 指南

> The Claude Code guide for startups

> 来源：Claude Blog / Anthropic，2026-08-20
> 原文链接：https://claude.com/blog/claude-code-guide-for-startups
> 分类：AI 工程 / 智能体编码实践

## 核心要点

- 智能体编码降低了构建门槛，使非技术岗位的员工也能完成从想法到可运行原型的第一步，而工程、设计等专业分工在后续环节依然保留。
- 把理解问题的人直接接入代码提交环节，压缩了「想法经产品经理、设计师层层转述给工程师」的传话链条，缩短了从构想到发布的时间。
- 让非技术员工真正参与贡献的关键在于把工具接入他们日常熟悉的系统，并通过季度评审、Slack 展示频道等机制让原型有机会进入正式路线图。
- 技能（skills）与 CLAUDE.md 文件把团队标准和上下文沉淀为可复用指令，既保证产出一致性，也让新人和非技术员工快速上手。
- 多家公司让智能体承担软件开发生命周期中机械性的约八成工作，包括入职环境搭建、代码审查、测试、CI 与运维，工程师集中处理需要判断力的情形。
- ClickHouse 把几乎每个开发生命周期阶段变成自主闭环，修复不稳定测试和补齐测试覆盖的两个智能体成为其仓库第二和第三大贡献者。
- 自动化的前提是可靠的监控与验证手段，团队通过写下架构不变量、部署确定性校验、维护评估黄金集与回溯测试来防止智能体偏离架构或产生回归。
- Cainex 的医疗编码流程坚持「修正原则，而不是修正个例」，由领域专家审查模型推理并把指导反馈进带版本管理的指令，避免把具体案例硬编码成补丁。
- 由于模型能力持续演进，这些团队把重写视为常态，用 git worktrees 并行验证新旧版本、用计划模式规划复杂重构，并把功能开关清理等迁移工作交给智能体批量处理。
- 用 Claude Code 构建内部智能体、先内部试用再借助 API、SDK 或托管智能体产品化，形成了「用 AI 构建 AI 产品」的飞轮，同时便于区分模型行为问题与 harness 问题。

## 正文

**本指南同时提供下载版** —— 同样的五条规则、创始人洞见和检查清单，便于离线阅读或与团队分享。

> **This guide is also available for download** — the same five rules, founder insights, and checklist, laid out for reading offline or sharing with your team.

#### 工作在前沿领域的 AI 原住民

> AI natives working at the frontier

如果你想一窥工作的未来，那就去问问初创公司如今是怎么运作的。于是我们这么做了。

> If you want to take a peek at the future of work, ask startups how they are operating today. So we did.

我们与十几家快速成长的初创公司聊了聊，了解他们如何使用智能体编码工具来构建产品、扩张公司。这些初创公司正在改写规则：谁有资格去构建、什么该被丢弃，以及如何在你的构建方式与构建内容之间打造一个飞轮。

> We spoke with more than a dozen fast-growing startups about how they use agentic coding tools to build products and scale their companies. These startups are changing the rules of who gets to build, what gets scrapped, and how to create a flywheel between how you build and what you build.

而他们的交付速度堪比规模是其十倍的组织。

> And they are shipping like organizations ten times their size.

在本指南中，我们将深入剖析这些组织独特的部署方式，了解它们遵循哪些规则来快速交付并保持自身的竞争优势。

> In this guide, we'll dive into the unique deployments of these organizations to learn the rules they follow to ship fast and maintain their competitive advantage.

在此过程中，我们也将开始窥见这样一个问题的答案：如果一个组织从零开始、围绕 Claude Code 来构建自己的产品开发生命周期，那会是什么样子？

> In doing so we'll also start to glean an answer to the question: what would it look like if an organization built their product development lifecycle with Claude Code from the ground up?

五条规则

> The five rules

1. [每个人都在发布](https://claude.com/blog/claude-code-guide-for-startups#rule-1)
2. [让繁琐工作自动化](https://claude.com/blog/claude-code-guide-for-startups#rule-2)
3. [信任，但要验证](https://claude.com/blog/claude-code-guide-for-startups#rule-3)
4. [为重建而构建](https://claude.com/blog/claude-code-guide-for-startups#rule-4)
5. [原型开发、内部试用、产品化](https://claude.com/blog/claude-code-guide-for-startups#rule-5)

> 1\. [Everyone ships](https://claude.com/blog/claude-code-guide-for-startups#rule-1)
> 2\. [Automate the tedium](https://claude.com/blog/claude-code-guide-for-startups#rule-2)
> 3\. [Trust, but verify](https://claude.com/blog/claude-code-guide-for-startups#rule-3)
> 4\. [Build for rebuilding](https://claude.com/blog/claude-code-guide-for-startups#rule-4)
> 5\. [Prototype, dogfood, productionize](https://claude.com/blog/claude-code-guide-for-startups#rule-5)

特别收录来自以下人士的创始人洞见

> Featuring founder insights from

**提示：**只想了解实际的后续操作步骤？我们在[本指南末尾提供了一份清单](https://claude.com/blog/claude-code-guide-for-startups#checklist)，汇总了各章中包含的关键技术提示。

> **Tip:** Only interested in the practical next steps? We've put a [checklist at the end of this guide](https://claude.com/blog/claude-code-guide-for-startups#checklist) that consolidates the key technical tips contained in each chapter.

#### 每个人都在发布

> Everyone ships

智能体编程降低了入门门槛，因此理解问题的人可以交付修复方案的第一个版本。

> Agentic coding lowers the barrier to entry, so the person who understands the problem can ship the first version of the fix.

智能体编程降低了非技术员工构建产品的门槛。有了 Claude Code，你无需精通某种编程语言或熟悉 IDE 的使用方法，也能创建可用的功能。

> Agentic coding lowers the barrier to entry for non-technical employees to build products. With Claude Code, you can create functional features without being fluent in a coding language or how to use an IDE.

![Mads Lunau Liechti](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb96afe3f55f3c73f16_1716034051392.jpeg)

> "不仅工程师的交付量大幅提升，连（像我这样的）非技术人员也突然开始交付 UI 改动和其他产品改进了。"**[Mads Lunau Liechti](https://www.linkedin.com/in/mads-lunau-liechti/)** · 联合创始人，[Parahelp](https://www.parahelp.com/)

> "Not only were engineers shipping much more, but non-technical people (like me) were also suddenly shipping UI changes and other product improvements."**[Mads Lunau Liechti](https://www.linkedin.com/in/mads-lunau-liechti/)** · co-founder, [Parahelp](https://www.parahelp.com/)

对创业公司的创始人来说，这具有显而易见的优势。首先，他们没有大型竞争对手那样的人员编制，所以只能"全员上阵"。但创始人所追求的不仅仅是纯粹的人力——这些非技术团队成员同样带来了领域专业知识。

> For startup founders this has obvious advantages. For one, they don't have the headcount of their larger competitors so it's "all hands on deck." But it's not just raw capacity that founders are after–these non-technical members of the team bring domain expertise as well.

![Ryan Daniels](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb9a794cf3b05d104b2_1759928398629.jpeg)

> "Claude Code 改变了在 Crosby 做律师的意义。律师们拥有最好的产品洞察，因为他们就是使用者。看着他们大展身手实在令人惊叹。"**[Ryan Daniels](https://www.linkedin.com/in/crosbyryan/)** · 联合创始人兼首席执行官，[Crosby](https://crosby.ai/)

> "Claude Code changed what it meant to be a lawyer at Crosby. The lawyers have the best product insights, because they are the users. It's been amazing to watch them cook."**[Ryan Daniels](https://www.linkedin.com/in/crosbyryan/)** · co-founder and CEO, [Crosby](https://crosby.ai/)

我们从 Heidi 的联合创始人兼首席执行官 Thomas Kelly 博士那里听到了同样的说法。

> We heard the same thing from Dr. Thomas Kelly, co-founder and CEO of Heidi.

![Dr. Thomas Kelly](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a860761e110c43cd72b4b36_thomas-kelly.jpg)

> "对我们来说，Claude Code 解决了「传话游戏」的问题。过去，一个新想法在团队中流转的方式是：有想法的人告诉产品经理，产品经理告诉设计师，设计师再告诉工程师……而想法的精髓不可避免地在这条链条中丢失了。等到东西真正发布出来时，往往已经不像那个人最初设想的样子了。而且这要花上好几周。Claude Code 压缩了这条链条。真正理解问题的人可以直接提交一个 PR，只在需要设计师和工程师专业能力的环节把他们请进来。"**[Dr. Thomas Kelly](https://www.linkedin.com/in/tomkeykong/)** · 联合创始人兼首席执行官，[Heidi](https://www.heidihealth.com/)

> "For us, Claude Code solved the broken telephone problem. The way a new idea used to move through a team was the person with the idea tells a PM, who tells a designer, who then tells an engineer… and inevitably the essence of the idea gets lost in that chain. By the time something shipped, it often didn't resemble what the person had in mind. And it took weeks. Claude Code collapses that chain. The person who actually understands the problem can ship a PR bringing in designers and engineers for the parts where their expertise matters."**[Dr. Thomas Kelly](https://www.linkedin.com/in/tomkeykong/)** · co-founder and CEO, [Heidi](https://www.heidihealth.com/)

把「人人都能发布代码」挂在嘴上，能写出一篇漂亮的 LinkedIn 帖子，但实际上这要怎么运作？难道市场团队来审批拉取请求？难道法务团队去钻研二分定位不稳定测试的种种细节？

> Saying "everyone ships" makes for a great LinkedIn post, but how does that work in reality? Is the marketing team approving pull requests? Is the legal team working through the intricacies of bisecting flaky tests?

我们得到的答案是，分工依然存在。市场人员仍然专注于市场营销，开发者仍然专注于开发。但把一个想法变成可运行原型这至关重要的第一步，也就是从 0 到 1 的过程，如今对所有人都是开放的。

> The answer we got is that there is still a division of labor. Marketers still focus on marketing and developers still focus on developing. But the all important first step of getting an idea to working prototype, of going from 0 to 1, is open to everyone.

我们还看到，最高效的初创公司会建立机制，让这些贡献成为系统化的常态，而不是任其偶然发生或依赖个人的雄心。

> We also saw the most effective startups create mechanisms to make these contributions systemic rather than leaving it to chance or individual ambition.

##### 建立连接

> Create connections

要求员工使用 AI 是一回事，让他们真正用上 Claude Code 以及所需的工具则是另一回事。

> It's one thing to create expectations for employees to use AI, it's another to give them access to Claude Code and the tools they need.

![Kareem Amin](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85f1033623355a8a430864_Kareem-clay.webp)

> “我们其实并没有在逃避[让非技术员工参与贡献]，而是在朝这个方向前进。我们的看法是，每一个岗位都正在变成工程岗位，因为你可以为它构建软件……所以我们招聘那些爱折腾、对构建东西感兴趣的人”**[Kareem Amin](https://www.linkedin.com/in/kareemamin/)** · 联合创始人兼首席执行官，[Clay](https://www.clay.com/)

> "We're actually not running away from [having non-technical employees contribute], we're going towards it. Our take is every role is becoming an engineering role because you can build software for it… so we hire people who are tinkerers, who are interested in building"**[Kareem Amin](https://www.linkedin.com/in/kareemamin/)** · co-founder and CEO, [Clay](https://www.clay.com/)

在 Crosby，团队并没有把律师带到 Claude Code 面前，而是通过将 Claude Code 接入律师们熟悉并每天使用的工具和操作系统，把 Claude Code 带到了律师身边。

> At Crosby, the team didn't bring lawyers to Claude Code, they brought Claude Code to the lawyers by connecting it to the tools and operating systems they were familiar with and worked in every day.

![MCP Connector Directory in Claude Code desktop.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a85f6614d1e747fe4f0b524_fca89ab9.png)

##### 站会展示

> Standup showcases

在某个阶段，想法需要获得被优先排序的机会，这样组织资源才能帮助将它们推向市场。对于产品经理来说，这条路是清晰的——毕竟这是他们的工作——但对于非技术岗位的员工而言，就不那么清晰了。

> At some point, ideas need to be given the opportunity to be prioritized so that organizational resources can help bring them to market. That road is clear for product managers—it's their job after all—but not as clear for non-technical employees.

Clay 设立了季度评审，在评审中对原型进行评估，原型可以由此进入正式的路线图。正是通过这种方式，Clay 的一位市场进入团队成员构建了一个自主智能体，它会访问你的网站、填写你的潜客获取表单、计算响应所需的时长、对体验进行评分，并生成一份效果报告。

> Clay creates quarterly reviews where prototypes are considered and can enter the formal roadmap. This is how a go-to-market team member at Clay built an autonomous agent that visits your websites, fills out your lead-capture forms, times how long it takes to respond, rates the experience, and generates a performance report.

Omni 有一个专门的 Slack 频道，用于展示由 Claude 生成的原型，包括资深技术人员在内的每个人都会在其中贡献内容。他们还实践着「每个人都要交付」的推论，也就是「每个人都要与客户交流」。

> Omni has a dedicated Slack channel for Claude generated prototypes with contributions from everyone including senior technical staff. They also practice the corollary of "everyone ships," which is "everyone talks with customers."

![Chris Merrick](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb9b23e4794dee49b44_1772096288397.jpeg)

> 尽管工程师天生并不倾向于参与客户通话，Omni 还是有意让他们直面客户，因为这能更快地闭合反馈循环。**[Chris Merrick](https://www.linkedin.com/in/merrickchristopher/)** · [Omni](https://omni.co/) 联合创始人兼 CTO

> Even though engineers don't naturally gravitate toward customer calls, Omni deliberately puts them in front of customers because it closes the feedback loop faster.**[Chris Merrick](https://www.linkedin.com/in/merrickchristopher/)** · co-founder and CTO, [Omni](https://omni.co/)

##### 共享技能

> Share skills

 “人人都能发布”和“零敲碎打”之间的界线可能非常模糊。功能原型无论出自谁手，仍然需要被整合进一个感觉浑然一体的产品之中。这正是技能（skills）——那些编码了团队标准与上下文的可复用指令文件——能够发挥作用的地方，它们有助于确保开发工作在流程日益民主化的同时仍保持一致。

>  The line between "everyone ships" and "piecemeal" can be a thin one. Feature prototypes, whoever they come from, still need to be integrated into a product that feels like a cohesive whole. This is where skills, reusable instruction files that encode your team's standards and context, can help ensure development stays aligned even as the process becomes increasingly democratized.

"团队中的任何人都可以用 Claude Code、以我们的设计系统为参照，起草产品组件、营销素材或演示文稿材料。凡是接触产品的 AI 都必须达到高得多的标准，而 Claude Code 帮助我们更精准地满足这一标准，"Heidi 的 Thomas Kelly 博士说。

> "Anyone on the team can draft product components, marketing collateral or deck material from Claude Code using our design system as reference. AI that touches the product must clear a much higher bar, which Claude Code helps us meet with more precision," said Dr. Thomas Kelly, Heidi.

它们还能让新入职的开发者和非技术员工快速上手并投入工作。

> They can also get new developers and non-technical employees onboarded and up and running quickly.

![Mukund Jha](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb78347c9db82e1a2f7_1769085036393.png)

> "……我们还有一个 Claude Code skills 的 GitHub 仓库，它作为一个共享知识库，可以快速用已知的 Emergent 细节来引导一个 Claude Code 会话，比如数据库[和数据仓库]的位置、一些 schema[信息]、公司的整体背景……与其追求在这方面做到完美，只要 agent 能够快速核实并纠正方向，容忍上下文文件稍微过时是没问题的。"**[Mukund Jha](https://www.linkedin.com/in/mukund-jha-a1596413/)** · 联合创始人兼 CEO，[Emergent](https://emergent.sh/)

> "...we also have a GitHub repo of Claude Code skills which works as a shared knowledge base to quickly bootstrap a Claude Code session with known Emergent details like database [and data warehouse] location, some schema [information], overall company context….instead of trying to be perfect here, it is ok to live with slightly outdated context files as long as the agent can quickly verify and course correct."**[Mukund Jha](https://www.linkedin.com/in/mukund-jha-a1596413/)** · co-founder and CEO, [Emergent](https://emergent.sh/)

![Jack O'Hara](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb9f09c093edabf6943_1733849104342.jpeg)

> "我们的工程师使用 Claude Code 搭建了一个内部专用智能体市场，按角色组织，因此工程、交付和销售团队各自都能获得契合其实际工作方式的工具。"**[Jack O'Hara](https://www.linkedin.com/in/jack-o-hara-/)** · 创始人兼首席执行官，[Translucent](https://www.translucent.co/)

> "Our engineers use Claude Code to spin up an in-house marketplace of specialized internal agents, organized by role, so engineering, delivery, and sales each get tools built for how they actually work."**[Jack O'Hara](https://www.linkedin.com/in/jack-o-hara-/)** · founder and CEO, [Translucent](https://www.translucent.co/)

**提示：**技能[可以通过目录在公司内部共享](https://code.claude.com/docs/en/plugin-marketplaces)，因此一位员工的最佳实践可以即时传递给另一位员工。在代码仓库的每个子目录中使用 `CLAUDE.md` 文件，来记录该子目录特有的、每次都适用的编码规范。技能则用于按需触发的流程化工作流。欲了解更多信息，请阅读：[引导 Claude Code：何时使用 CLAUDE.md、技能、钩子和子代理](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)。

> **Tip:** Skills [can be shared across the company using a directory](https://code.claude.com/docs/en/plugin-marketplaces) so one employee's best practice can be instantly transferred to another. Use `CLAUDE.md` files in each subdirectory of your repo for coding conventions specific to that subdirectory that apply every time. Use skills for on-demand procedural workflows. For more information, read: [Steering Claude Code: when to use CLAUDE.md, skills, hooks, and subagents](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more).

#### 让繁琐的工作自动化

> Automate the tedium

智能体承担生命周期中机械性的 80% 工作，让工程师把时间花在真正需要判断力的情况上。

> Agents own the mechanical 80% of the lifecycle so engineers spend their time on the cases that actually need judgment.

自工业革命之初以来，所有公司都在寻求通过技术提高效率，但这些初创公司凭借其采用技术的速度和深度而与众不同。

> All companies have sought to gain efficiencies through technology since the dawn of the industrial revolution, but these startups separated themselves by the speed and depth of their adoption.

这些创始人认为，AI 是其使命中不可或缺的组成部分。许多人明确表示，由智能体承担那 80% 的机械性工作，从而让工程师把时间花在真正需要判断力的场景上。

> These founders believe AI is an essential component of their mission. Many are explicit that agents own the mechanical 80% so engineers spend their time on the cases that actually need judgment.

![Shachar Hirshberg](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb924b99c1b701066b9_1783109987447.png)

> “每个人都在竞相打造 AI 产品，而真正重构公司运作方式的人要少得多。后者才是更大的突破口。Artemis Security 是作为一家 AI 原生公司在运转，而不是一家恰好用了 AI 的公司。这大幅提升了我们的速度，让我们能够帮助客户以机器速度阻止攻击。”**[Shachar Hirshberg](https://www.linkedin.com/in/shachar-hirshberg/)** · 联合创始人兼首席执行官，[Artemis Security](https://artemissecurity.com/)

> "Everyone's racing to build AI products. Far fewer are rebuilding how their company actually runs. The second one is the bigger unlock. Artemis Security runs as an AI-native company, not a company that happens to use AI. This supercharges our velocity and allows us to help customers stop attacks at machine speed."**[Shachar Hirshberg](https://www.linkedin.com/in/shachar-hirshberg/)** · co-founder and CEO, [Artemis Security](https://artemissecurity.com/)

具体来说，我们看到他们在 SDLC 各个阶段对 AI 的集成比其他团队更为紧密，同时也有更多专门构建的智能体被设计用来端到端地处理重复性任务。下面我们来看这两方面的几个例子。

> Specifically, we saw AI more tightly integrated across their SDLC stages than others as well as more purpose built agents designed to take recurring tasks end-to-end. Let's look at a couple examples of both.

##### AI 原生的软件开发生命周期

> AI-native SDLCs

这些入选的初创公司中，许多都实施了加速团队融入其智能体编码流程的方法。例如在 Emergent，Mukund 告诉我们：“入职第一天，新员工只需把 Claude 指向正确的 markdown 文件，就能引导搭建起整套开发环境。如果 Claude 在入职过程中遇到任何损坏或过时的内容，它会更新那个文件。”

> Many of these featured startups have implemented means of accelerating their teams' onboarding into their agentic coding processes. For example, at Emergent, Mukund told us, "on day one, a new hire bootstraps their entire dev setup by pointing Claude at the right markdown file. If Claude hits anything broken or out of date during onboarding, it updates that file."

**提示：**[Code Review](https://code.claude.com/docs/en/code-review)（研究预览版）是 Claude Code 中的一项托管式多智能体服务。它会对你启用的代码仓库中的 PR 运行一次自动化审查。你可以手动修复发现的问题并推送，也可以通过在该发现下评论 `@Claude` 来闭环处理（前提是你已设置并配置好 GitHub Actions）。

> **Tip:** [Code Review](https://code.claude.com/docs/en/code-review) (research preview) is a managed multi-agent service in Claude Code. It runs an automated review pass on PRs in the repos you enable. You can manually fix the finding and push, or close the loop by commenting `@Claude` on the finding (if you've set up and configured GitHub Actions).

![Code Review tags each finding with a severity level.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a85fadd2e4ee0c9bc09260c_f0ed4c96.png)

这些工程师需要快速完成入职，因为这些团队交付速度极快。

> These engineers need to be onboarded quickly because these teams ship fast.

![Tanay Tandon](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efba858ba52aeb268f5b_1765628872241.png)

> “这里的工程师在编排智能体舰队，在发现生产数据问题的当天就交付修复，并同时推进多个 PR。一位工程师用并行的 Claude 子智能体推进了一个约 13 张工单的项目，每个子智能体负责一张工单及其 PR。”**[Tanay Tandon](https://www.linkedin.com/in/tanaytandon/)** · [Commure](https://www.commure.com/) CEO 兼创始人

> "Engineers here are orchestrating agent fleets, shipping fixes to production data problems the same day they're found, and running multiple PRs in flight simultaneously. One engineer ran a ~13-ticket initiative with Claude subagents in parallel, each owning a ticket and its PR."**[Tanay Tandon](https://www.linkedin.com/in/tanaytandon/)** · CEO and founder, [Commure](https://www.commure.com/)

在这些组织中，Claude Code 不仅帮助生成代码，还会对代码进行审查。Heidi 的 Kelly 博士说：“我们依照经过审核的技术与合规框架运行自动化代码审查，在任何内容上线前标记出关键问题，并把建议的改动路由给合适的审查者。”

> At these organizations, Claude Code not only helps generate code, but reviews it too. "We run automated code reviews against our vetted technical and compliance frameworks, flagging critical issues and routing suggested changes to the right reviewers before anything ships," said Dr. Kelly of Heidi.

其中一些组织还为代码审查、测试和 CI 构建了自定义智能体。这些初创公司把相当多的注意力放在[构建闭环](https://claude.com/blog/getting-started-with-loops)上，而不只是部署代码。

> Some of these organizations have also built custom agents for code review, testing, and CI. These startups have placed considerable attention on [building loops](https://claude.com/blog/getting-started-with-loops) vs just deploying code.

Translucent 创始人 Jack 说：“我最喜欢的[智能体]是‘Translucent 代码审查员’，它会在一次变更上扇出展开，从多个角度进行审查，并像我们的一位资深工程师那样综合结果，但比任何单个人都要快。”

> "My favorite [agent] is the "Translucent code reviewer," which fans out across a change, reviews it from multiple angles, and synthesizes the results the way one of our senior engineers would but faster than any one person could," said Translucent founder Jack.

Kareem 说，Clay“……构建了一个智能体，负责处理……缺陷分诊，从初步筛查到建议用于修复的代码改动”。

> Clay "...built an agent that handles…bug triage, from first pass to suggesting code changes for fixes," said Kareem.

![Claude Tag picks up an on-call thread in Slack and reports progress in-channel.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a85fb2fd93d3b5e91d50ec3_1891dfb7.png)

‍

> ‍

![Alexey Milovidov](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb9491bc622d12a7ad2_1632147780689.jpeg)

> 这一点在 [ClickHouse](https://clickhouse.com/) 表现得最为突出，**联合创始人兼 CTO Alexey Milovidov 报告称**，这家数据库公司已把几乎每个软件开发生命周期阶段都变成了自主闭环。两个专门用于修复不稳定测试和查找缺失测试覆盖的智能体，如今是 ClickHouse 仓库的第 2 和第 3 大贡献者。另有一组智能体负责运维，团队还使用 Claude Code 来构建和迭代这些智能体本身。

> This was most pronounced at [ClickHouse](https://clickhouse.com/), where **co-founder and CTO Alexey Milovidov reported** the database company had turned nearly every SDLC stage into an autonomous loop. Two purpose-built agents designed to fix flaky tests and find missing test coverage are now the #2 and #3 contributors to the ClickHouse repo. A separate family of agents handles operations, and the team uses Claude Code to build and iterate on those agents themselves.

##### 用智能体加速流程

> Accelerating processes with agents

另一个一致的模式是，这些初创公司不仅在 Claude Code 中使用智能体闭环来加速开发工作，还创建智能体来加速那些重复且往往枯燥的流程。

> Another consistent pattern was that these startups were not only using agentic loops in Claude Code to accelerate their development efforts, but they were also creating agents to accelerate recurring and often tedious processes.

这些通常是例行工作，如此一来就能把更多注意力集中在自身的竞争优势、客户关系和营收增长上。我们看到被 Claude 加速的最常见流程之一是自助式数据分析。

> This was often routine work so that more attention could be focused on their competitive advantage, customer relationships, and on top-line growth. One of the most common processes we saw accelerated by Claude was self-service data analytics.

几乎每一家公司都建立了某种流程，以便能基于新鲜数据（包括非结构化数据）快速做出决策，而这些数据正是支撑初创公司生命中至关重要的转型调整的燃料。

>  Nearly every one of these companies had some process in place so they could make quick decisions with fresh data, including unstructured data, that fuels the pivoting so essential in the life of a startup.

例如，Clay 构建了一个内部分析智能体，而 Heidi 使用 Claude Code 将客户和临床医生的反馈与使用数据一起归类，以浮现出对产品洞察真正重要的信号。

> For example, Clay built an internal analytics agent and Heidi uses Claude Code to categorize customer and clinician feedback alongside usage data to surface signals that matter for product insights.

ClickHouse 和 Omni 都交付了将此类 AI 数据分析内置其中的产品，全部由 Claude 驱动。

> Both ClickHouse and Omni ship products that package this type of AI data analysis within them, all powered by Claude.

其他例子包括用子智能体总结数千份法律文档（Crosby）、扫描理赔数据以标记跨站点的异常（Commure），以及持续挖掘医院财务数据以发现任何分析师团队都无法及时捕捉的预警信号（Translucent）。

> Other examples include summarizing thousands of legal documents with subagents (Crosby), sweeping claims data to flag anomalies across sites (Commure), and continuously mining hospital financial data for warning signs no analyst team could catch in time (Translucent).

**提示：**[动态工作流](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code)可用于扇出多个子智能体来并行分析大量数据，或对另一个智能体的工作进行对抗性审查。在使用 Claude Opus 或 Claude Fable 这类模型时，可以说“扇出多个子智能体”或“使用一个工作流”。

> **Tip:** [Dynamic workflows](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code) can be used to fan multiple subagents to analyze large amounts of data in parallel or to conduct an adversarial review of another agent's work. When using a model like Claude Opus or Claude Fable say "fan out multiple subagents," or "use a workflow."

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a8600cd57a9407076b2e246_4bd02c85.png)

#### 信任，但要验证

> Trust, but verify

除非你有可靠的手段来监控和验证结果，否则无法将一个流程自动化。

> You can't automate a process unless you have a reliable means of monitoring and verifying the outcome.

这条规则是规则 2「自动化繁琐工作」的必然推论。除非你有可靠的手段来监控和验证结果，否则你无法将一个流程自动化。

> This rule is the necessary corollary to Rule 2: Automate the tedium. You can't automate a process, unless you have a reliable means of monitoring and verifying the outcome.

![Dan Shiebler](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a86fc9ddbdb6a1fb6d61375_dan-shiebler.jpg)

> Artemis Security 联合创始人 Dan Shiebler 表示，他们之所以能提升部署速度，只是因为……“我们在测试基础设施、代码库组织方式以及团队知识系统上进行了深度投入，这些让智能体能够端到端地交付。这就是我们借助 Claude 打造的飞轮：以正确的方式组织你的代码库、知识库和团队，那么每一次贡献都会产生复利。”**[Dan Shiebler](https://www.linkedin.com/in/dan-shiebler-10219b42/)** · 联合创始人，[Artemis Security](https://artemissecurity.com/)

> Artemis Security co-founder Dan Shiebler said their increased deployment speed only works…"because we've invested deeply in testing infrastructure, codebase organization, and team knowledge systems that let agents ship end to end. This is the flywheel we've built with Claude: structure your codebase, knowledge base, and team the right way, and every contribution compounds."**[Dan Shiebler](https://www.linkedin.com/in/dan-shiebler-10219b42/)** · co-founder, [Artemis Security](https://artemissecurity.com/)

![Victor Hunt](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85f1ef3623355a8a439148_Victor%20Hunt.jpg)

> "早期我们给了 Claude 完全的自主权，而它做了 AI 会做的事。它飞快地交付了看似合理的代码。问题在于，它以一种看上去正确、实则不然的方式偏离了我们的架构。所以我们……把每一条不变量都写了下来。我们如何界定问题。无论如何都必须成立的是什么。如何证明某样东西确实可行，而不是去信任一个自信的答案。567 行，写的是这个团队如何思考。"**[Victor Hunt](https://www.linkedin.com/in/victor-c-hunt)** · 联合创始人兼 CEO，[Zingage](https://zingage.com/)

> "Early on we gave Claude full autonomy and it did what AI does. It shipped plausible code fast. The problem was it drifted from our architecture in ways that looked right but weren't. So we…wrote down every invariant. How we frame problems. What has to be true no matter what. How to prove something works instead of trusting a confident answer. 567 lines of how this team thinks."**[Victor Hunt](https://www.linkedin.com/in/victor-c-hunt)** · co-founder and CEO, [Zingage](https://zingage.com/)

**提示：**把不能改变的内容放在仓库根目录的 `CLAUDE.md` 中。Claude 会在每次会话开始时读取它，因此你的架构规则、安全边界和不可妥协的约定会伴随每一次会话。

> **Tip:** Put what can't change in `CLAUDE.md` at the root of your repo. Claude reads it at the start of every session, so your architecture rules, security boundaries, and non-negotiables travel with every session.

需要明确的是，这些初创公司里没有一家是让智能体直接合并到 main 分支然后祈祷一切顺利的。它们中的许多身处高度监管的行业，需要强有力的治理框架。Cainex 是一个格外具有说明性的例子，它将智能体与确定性校验结合起来，用于读取病历并生成指导医院计费的编码。

> To be clear, none of these startups are having agents merge to main and hoping for the best. Many of them operate in highly regulated industries and require strong governance frameworks. Cainex is a particularly illustrative example of combining agents with deterministic checks to read medical records and generate codes that direct hospital billing.

![Uriah Israel](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85e97524b99c1b700c5b18_uriah.webp)

> 「在医疗编码领域，错误的编码不是笔误，而是一次计费与合规事件。这一个事实决定了我们的构建方式。」**[Uriah Israel](https://www.linkedin.com/in/uriah-israel/)** · 联合创始人兼首席技术官，[Cainex](https://www.cainex.com/)

> "In medical coding, a wrong code isn't a typo. It's a billing and compliance event. That one fact governs how we build."**[Uriah Israel](https://www.linkedin.com/in/uriah-israel/)** · co-founder and CTO, [Cainex](https://www.cainex.com/)

 “这就是 Claude Code 为我们运行的循环。我们用一个 agent 处理一批数据，我们的审核人员在内部应用中审查输出。他们看到的不只是代码。他们能看到模型的推理过程，并对两者都作出评论……一切都有版本记录，可供审计。”他说。

>  "Here's the loop Claude Code runs for us. We process a batch with an agent, and our auditors review the output in an internal app. They don't just see the codes. They see the model's reasoning, and they comment on both….Everything is versioned and auditable," he said.

"然后 Claude Code 接手。它直接从数据库中读取原始预测结果，以及每一条更正和评论。每条更正都按所涉及的编码类型进行了标记，因此 Claude Code 知道自己面对的是诊断问题、操作问题还是其他类别，并且可以直接查阅管辖该特定编码类型的指南。

> "Then Claude Code takes over. It reads the original predictions, along with every correction and comment, straight from the database. Each correction is tagged by the kind of code involved, so Claude Code knows whether it's looking at a diagnosis issue, a procedure issue, or another category, and it can go straight to the guidance that governs that specific kind of coding.

由此出发，它会找出智能体指令中导致该错误的那部分并加以修改，或者在案例确实是全新的情况下编写新的指导。每一次改动都是针对一套带版本管理的指令进行的，并用那些失败的记录来测试。我们坚持的规则是：修正原则，而不是修正个例。”他继续说道。

> From there, it finds the part of the agent's instructions that produced the mistake and revises it, or writes new guidance when the case is genuinely new. Every change is made against a versioned set of instructions and tested against the records that failed. The rule we enforce: fix the principle, not the example," he continued.

“然后是回溯测试。一条记录可以有多种可接受的编码方式，所以这不是字符串匹配。这项检查把针对我们认可集合的语义匹配，与一位提出'这究竟是真正的错误，还是只是另一条同样有效的路径'的评判者结合起来，而 Claude Code 还会在此之上加入它自己的比较。

> "Then the back-test. A record can have more than one acceptable coding, so it's not a string match. The check combines semantic matching against our accepted sets with a judge that asks, 'Is this a real error or just a different valid path,' and Claude Code adds its own comparisons on top.

 它会在一个黄金集加上随机样本上运行候选变更，并在任何东西上线之前暴露出所有回归问题。返回的是一份简短的清单：建议的修改、它无法解决的记录，以及它希望得到解答的问题。工程师们把时间花在真正的疑难情况上，而不是那机械性的 80%，”他说。

>  It runs the candidate change across a golden set plus random samples and surfaces any regressions before anything ships. What comes back is a short list: suggested edits, the records it couldn't resolve, and the questions it wants answered. Engineers spend their time on genuinely hard cases rather than the mechanical 80%," he said.

创始人可以从这个医疗账单专用工作流中提炼出许多具有普遍意义的经验。

> There are many generalized takeaways that founders can glean from this healthcare billing specific workflow.

例如，Cainex 让领域专家定期审查并引导 Claude 的推理过程，并确保这些指导意见成为自我改进循环的一部分。不过，这些专家的职责并不是逐个案例地修补问题，他们的指导会被用作自我改进循环的一部分。正如 Uriah 所说：“修正原则，而不是修正个例。”

> For example, Cainex uses subject matter experts to routinely review and guide Claude's reasoning, and ensure that guidance becomes part of a self-improvement loop. However, those experts aren't there to fix example by example, their guidance is used as part of a self-improvement loop. As Uriah puts it "fix the principle, not the example."

![Loops repeat cycles of work until a stop condition is met.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a43eb603762e725a739d98f_c6fa9ae5.png)

‍

> ‍

另一个要点是，团队非常勤勉地维护了一套强有力的评估"黄金集"，即一组经过验证的问答对，团队用它来验证智能体的准确性。每家初创公司都应该为其关键用例维护多套评估集，并定期更新，这样才能防止漂移并评估未来的模型。

> The other takeaway is the diligence placed on maintaining a strong evaluation "golden set," or group of verified question answer pairs the team uses to verify the agent's accuracy. Every startup should maintain multiple sets of evals for their key use cases, and update them regularly, so they can prevent drift and evaluate future models.

![Alex Mashrabov](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85f11c728d6a4b5ce8da6d_alexhiggsfield.webp)

> "[Claude Code] 还改变了我们管理模型迭代速度的方式。新的视频和图像模型层出不穷。每一个在部署前都需要新的技能、评估、路由逻辑和生产环境测试。Claude Code 把这个周期从几天压缩到了几小时，让我们能够在生产环境中发现问题，并在同一次会话中部署修复……当你要与人手是你 10 倍的公司竞争时，这种杠杆效应会改变一切。"**[Alex Mashrabov](https://www.linkedin.com/in/amashrabov)** · 联合创始人兼首席执行官，[Higgsfield](https://higgsfield.ai/)

> "[Claude Code has] also transformed how we manage model velocity. New video and image models arrive constantly. Each requires new skills, evaluations, routing logic, and production testing before deployment. Claude Code has compressed that cycle from days to hours, allowing us to identify issues in production and deploy fixes in the same session….When you're competing against companies with 10x the headcount, that kind of leverage changes everything."**[Alex Mashrabov](https://www.linkedin.com/in/amashrabov)** · co-founder and CEO, [Higgsfield](https://higgsfield.ai/)

**提示：**团队刚开始构建智能体时，仅靠手动测试、内部试用（dogfooding）和直觉，往往就能走得出乎意料地远。转折点通常出现在用户反馈说改动之后智能体的表现变差了，而团队却「盲飞」，除了猜测和试错之外没有任何验证手段。团队无法区分真实的性能退化和噪声，无法在发布前针对数百个场景自动测试改动，也无法衡量改进的效果。欲了解更多信息，请阅读：[揭开 AI 智能体评估的神秘面纱](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)。

> **Tip:** When teams first start building agents, they can get surprisingly far through a combination of manual testing, dogfooding, and intuition. The breaking point often comes when users report the agent feels worse after changes, and the team is "flying blind" with no way to verify except to guess and check. Teams can't distinguish real regressions from noise, automatically test changes against hundreds of scenarios before shipping, or measure improvements. For more information read: [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents).

Uriah 提出的最后一点是，这个过程可能需要一些努力。"最开始它并不这么干净。我们的第一个版本过拟合了。它会通过把具体案例编码进去来'修复'问题，于是我们积累的是补丁，而不是变得更聪明。我们改变了方法，强制提炼通用原则，并且从根本上限制一次改动中能进入多少具体细节。"

> The final point Uriah makes is that this process can take some work. "It didn't start this clean. Our first version overfitted. It would 'fix' things by encoding the specific case, and we were accumulating patches instead of getting smarter. We changed the approach to force general principles and to cap how many specifics can enter a change at all."

#### 为重建而构建

> Build for rebuilding

模型能力在这些团队脚下不断变化，因此几乎没有什么被视为永久不变的。

> Model capability keeps shifting underneath these teams, so very little is treated as permanent.

这些 AI 原生初创公司中的许多都处于不断重塑自我的状态。

> Many of these AI-native startups are in a state of constant reinvention.

AI 往往既是他们所构建之物的核心，也是他们构建方式的核心。由于模型能力在持续演进，那些突破性的功能和关键的脚手架代码一旦变成沉没成本，就会被立刻弃用。许多这样的组织把这种不断重建的过程视为自身竞争优势的一部分。

> AI is often at the heart of what they are building as well as how they are building it. Since model capability continuously evolves, groundbreaking features and critical scaffolding were discarded the minute they became sunk costs. Many of these organizations saw this constant rebuilding as part of their competitive advantage.

“我们在 Clay 的做法是，你先把它做出来，然后再做一遍，然后再做一遍。等到你第四次做的时候，你就知道了所有需要知道的东西，也就做对了。所以我们并不一定会把东西扔掉。我们只是重建它：而这一次带着更清晰的认知，”Kareem 说。

> "What we do at Clay is you build it and then you build it again and then you build it again. And then the fourth time you build it, you know everything that's needed and you get it right. And so we don't necessarily throw away things. We just rebuild it: and this time with more clarity," said Kareem.

「重构不是在新路径上线时就完成了，而是在旧路径被彻底移除时才算完成。以往在排优先级时，拆除旧代码总是输的一方：它琐碎繁杂，又交付不了任何新功能。」Commure 联合创始人 Tanay 说，「现在，Commure 的某位工程师只需调用一个 Claude skill，大意是『对于每一个已经向所有人发布的功能开关，提交一个 PR 删除它以及相关代码』，然后工程师再审阅返回的结果。过去要耗掉大量开发周期的迁移工作，如今只是一份计划加一次并行分发，几个小时就搞定了。」

> "A rebuild isn't done when the new path ships. It's done when the old path is gone. Teardown always lost the prioritization fight before: it's tedious and it ships no features," said Commure co-founder Tanay. "Now one of Commure's engineers just invokes a Claude skill to the tune of 'for every feature flag already released to everyone, open a PR removing it and the associated code,' then the engineer reviews what comes back. Migrations that used to eat a lot of dev cycles are now a plan and a fan out, done in a couple of hours."

**提示：**使用 [git worktrees](https://code.claude.com/docs/en/worktrees) 可以在仓库的一个隔离副本中执行重建，同时当前版本保持不受影响。Claude Code 可以帮你创建一个 —— 你会得到与 v1 并存运行的 v2，针对两者运行你的评估，只有在新版本胜出时才进行合并。正是这一点让“构建四次”变得成本低廉。

> **Tip:** Use [git worktrees](https://code.claude.com/docs/en/worktrees) to run a rebuild in an isolated copy of the repo while the current version stays untouched. Claude Code can spin one up for you — you get v2 running next to v1, run your evals against both, and only merge when the new one wins. This is what makes "build it four times" cheap.

![One repository, one object store — three checkouts you can work in simultaneously, each on its own branch.](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a86014c09a6e237c1ac273c_ccb97885.png)

每个链接工作树都是一个普通目录，拥有自己检出的分支；这三者共享 acme-web 内部的同一个 .git 对象存储。

> Each linked worktree is an ordinary directory with its own checked-out branch; all three share the single .git object store inside acme-web.

Kareem 还提到，Clay 护城河的一部分在于能够持续重建、演进，并创造自我改进的循环。

> Kareem also described part of Clay's moat as the ability to constantly rebuild, evolve, and create self-improvement loops.

"我认为当下任何一家公司的护城河，在于它必须能够自我改进。所以 Clay 是一个自我学习的收入引擎。你用得越多，我们就越了解谁是你最好的客户、你应该说什么、什么奏效了、什么没有奏效，而这些都在随时间变化，"他说。"这场竞赛的关键在于，谁能最快触达渠道分发……这样你就能帮助每一个[客户]，从而实现自我改进。"

> "I think the moat for any company right now is that it needs to be self-improving. So Clay is a self-learning revenue engine. So the more you use this, the more we know who your best customers are, what should you say, what's worked, what hasn't and that's changing over time," he said. "The race is really, whoever can get to the distribution fastest… so you can help each [customer] so that you can self-improve."

在 [2026 年 5 月的 Code with Claude 活动](https://www.youtube.com/live/OFDm3T7pVlc?si=Z_RENcJSqm8H79aj)上，Harvey 应用 AI 负责人 Niko Grupen 谈到，模型能力的每一次新浪潮——涌现式推理、智能体自动化、规划与编排——都要求对平台进行一次彻底的重新架构。

> At a [May 2026 Code with Claude event](https://www.youtube.com/live/OFDm3T7pVlc?si=Z_RENcJSqm8H79aj), Niko Grupen, Harvey's Head of Applied AI spoke about how each new wave of model capabilities — emergent reasoning, agentic automation, planning and orchestration — required a full re-architecture of the platform.

![Niko Grupen](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85f137a1aa7f601c74989a_1b877ceecea22945f9acd75a60692d9c7b488058-1600x1600.webp)

> “如果你在六个月前问我我们的架构是什么样子，我给出的答案会和今天的样子有着根本性的不同。如果我们当时不愿意说‘嘿，我们需要把这套东西推翻，转向智能体原生’，那我们现在的平台根本不可能拥有这些能力。”**[Niko Grupen](https://www.linkedin.com/in/nikogrupen)** · 应用 AI 负责人，[Harvey](https://www.harvey.ai/)

> "If you asked me six months ago what our architecture looks like, I'd give a fundamentally different answer from what it looks like today. If we hadn't been willing to say 'Hey, we need to scrap this and go agent native' we simply could not have these capabilities in our platform right now."**[Niko Grupen](https://www.linkedin.com/in/nikogrupen)** · Head of Applied AI, [Harvey](https://www.harvey.ai/)

在同一场活动上，Cognition 联合创始人 Walden Yan 表示：

> At the same event, Cognition co-founder Walden Yan said:

![Walden Yan](https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a85efb993c65fad88a4e0b3_1699725986976.jpeg)

> “当下构建 AI 的生存方式，就是接受你今天做出来的东西极有可能在六个月到一年内被推翻重来……[Devin] 用我们两年前拥有的那套模型是完全做不出来的，[但当时的赌注是] 这件事今天或许行不通，但很快就会行得通。”**[Walden Yan](https://www.linkedin.com/in/waldenyan)** · 联合创始人，[Cognition](https://cognition.ai/)

> "The way of life of building AI right now is accepting that the thing you build today is very likely going to be scrapped in six months to a year.... [Devin] was very much not possible with the set of models we had two years ago, [but the bet was] this may not work today, but it will soon."**[Walden Yan](https://www.linkedin.com/in/waldenyan)** · co-founder, [Cognition](https://cognition.ai/)

**提示：**对于比较复杂的重写，请在[计划模式](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode)下启动 Claude Code（`--plan` 或按 Shift+Tab）。Claude 会先探索代码库并提出重建方案，然后才开始写代码——你可以批准或调整方向。这是发现重建即将偏离你的架构的最低成本环节。

> **Tip:** For non-trivial rewrites, start Claude Code in [plan mode](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode) (`--plan` or hit Shift+Tab). Claude will explore the codebase and propose the rebuild approach before writing any code — you approve or redirect. It's the cheapest place to catch a rebuild that's about to drift from your architecture.

#### 原型开发、内部试用、投入生产

> Prototype, dogfood, productionize

借助 AI 进行开发，帮助这些初创公司打造具有颠覆性的 AI 产品——这正是其流程核心的飞轮。

> Building with AI helps these startups create disruptive products with AI — the flywheel at the heart of their process.

这些初创公司中的许多家，在其开发流程的核心都有一个关键的飞轮。用 AI 来构建，帮助它们打造出具有颠覆性的 AI 产品。

> Many of these startups have a key flywheel at the heart of their development process. Building with AI helps them create disruptive products with AI.

当开发者提升自己的智能体编码实践水平时，他们会更深入地掌握模型的能力，并洞察到前沿的 harness 设计是如何演进的。随后，他们就能把这些启发运用到自己的智能体和产品中。

> When developers advance their agentic coding practices, they have a stronger grasp on the model's capabilities and insights into how harness design evolves at the frontier. They can then use this inspiration in their own agents and products.

“我们从 [Anthropic 的] 文件与嵌入方案中获得了启发，这让我们有信心在自己的产品中保持简洁。我们避开了搭建 RAG 流水线本会带来的大量复杂性，”Omni 的 Chris 说。“我们还看到 Claude Code 的 harness 是如何让用户并行处理多项任务的，并把其中一些理念改造进了我们自己的 UI。”

> "We took inspiration from [Anthropic's] file vs embedding approach, which emboldened us to keep things simple in our own product. We avoided a lot of complexity that would have come from a RAG pipeline," said Chris, Omni. "We also saw how Claude Code's harness was enabling users to do things in parallel and adapted some of those concepts into our own UI."

 这也有助于他们持续关注自身产品的表现。

>  It also helps them stay attuned to their own product performance.

"因为我们的应用构建器背后同样使用 Anthropic 的模型，所以如果我们在产品上发现某种行为……我们可以通过 Claude Code 在本地快速调试，判断它是模型行为还是 harness 的问题。这极大地帮助我们改进了问题分流的周期，"Emergent 的 Mukund 说道。

> "Because our app builder also uses Anthropic models behind the scenes, if we ever see a behavior on our product… we can quickly debug locally via Claude Code to tell whether it's model behavior or a harness issue. This has tremendously helped improve our triage cycles," said Mukund, Emergent.

我们反复听到的模式是：用 Claude Code 构建一个内部智能体，先在内部使用（吃自己的狗粮），然后根据反馈情况，将其提升为面向客户的产品，通常会使用 Claude API、SDK 或 Claude Managed Agents。

> The pattern we heard repeatedly was build an internal agent with Claude Code, use internally (dogfood), and depending on the response, promote to a customer facing product often using the Claude API, SDK, or Claude Managed Agents.

“我们在自己的产品中构建了供团队直接交互的 AI 智能体，包括 SQL 控制台里的智能体和一个 AI SRE。我们使用 Claude Code 来构建并迭代这些智能体本身。为客户的 AI 体验提供支持的工具链，某种程度上就是用 AI 构建的，”ClickHouse 的 Alexey 说。

> "We built our own AI agents [in our product] that teams interact with directly, including an agent in the SQL console and an AI SRE. We use Claude Code to build and iterate on these agents themselves. The tooling that powers our customers' AI experiences is, in part, built with AI," said Alexey, ClickHouse.

#### 清单

> The Checklist

本指南涵盖了大量内容。以下是整合在一页上的关键要点：

> This guide covered a lot of ground. Here are the key tips consolidated on one page:

###### 第 1 章：人人都能交付

> Chapter 1: Everyone ships

###### 第 2 章：自动化繁琐工作

> Chapter 2: Automate Tedium

###### 第 3 章：信任，但要验证

> Chapter 3: Trust, but verify

###### 第 4 章：为重建而构建

> Chapter 4: Build for rebuilding

#### 前沿领域的初创公司在前沿之上构建

> Startups on the frontier build at the frontier

这些洞见来自正在前沿领域进行构建的同行们，我们希望你觉得它们实用且可落地。Claude 创业社区始终是灵感、最佳实践和建议的源泉。你可以通过以下方式加入这个社区：

> These insights come from your peers building at the frontier and we hope you found them practical and actionable. The Claude startup community is a constant source of inspiration, best practices, and advice. You can join this community by:

- [订阅 Startup Newsletter 并加入创业者计划](https://claude.com/programs/startups)。
- [收藏即将举行的 Claude Code 网络研讨会](https://academy.claude.com/code/webinars)。
- [参加你附近的活动](https://luma.com/claudecommunity)
- 在 [Reddit](https://www.reddit.com/r/ClaudeAI/) 和 [Discord](https://discord.com/invite/6PPFFzqPDZ) 上贡献。
- 初创阶段的公司还可以申请 [Claude for Startups 计划](https://claude.com/programs/startups)，以获取额度和支持。

> • [Subscribing to the Startup Newsletter and joining the startup program](https://claude.com/programs/startups).
> • [Bookmarking upcoming Claude Code webinars](https://academy.claude.com/code/webinars).
> • [Attending an event near you](https://luma.com/claudecommunity)
> • Contributing on [Reddit](https://www.reddit.com/r/ClaudeAI/) and [Discord](https://discord.com/invite/6PPFFzqPDZ).
> • Early-stage companies can also apply to the [Claude for Startups program](https://claude.com/programs/startups) for credits and support.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| agentic coding | 智能体编码 | 由 AI 智能体自主执行代码编写、修改与验证的开发方式。 |
| SDLC (Software Development Life Cycle) | 软件开发生命周期 | 从需求、开发、测试到部署运维的完整软件交付流程。 |
| PR (pull request) | 拉取请求 | 向代码仓库提交变更并请求审查合并的协作机制。 |
| skills | 技能 | 编码了团队标准与上下文、可按需触发的可复用指令文件。 |
| CLAUDE.md | CLAUDE.md 配置文件 | 放在仓库目录中、每次会话自动加载的常驻规范与约束文件。 |
| subagent | 子智能体 | 由主智能体派生、并行承担独立子任务的下级智能体。 |
| fan out | 扇出 | 把一项任务同时分发给多个智能体并行处理的模式。 |
| harness | 运行框架 / 脚手架 | 包裹模型、提供工具调用与上下文管理的外层执行系统。 |
| eval / golden set | 评估集 / 黄金集 | 一组经人工验证的问答对，用于衡量智能体准确性与检测退化。 |
| flaky test | 不稳定测试 | 在代码未变动的情况下时而通过时而失败的测试用例。 |
| git worktree | Git 工作树 | 共享同一对象存储、可并行检出多个分支的独立工作目录。 |
| feature flag | 功能开关 | 在运行时控制功能是否对用户可见的配置开关。 |
| dogfooding | 内部试用 | 团队先在内部使用自家产品以发现问题的实践。 |
| RAG pipeline | 检索增强生成流水线 | 通过检索外部资料再交由模型生成答案的架构。 |
| backtesting | 回溯测试 | 用历史数据检验候选变更效果、暴露回归问题的验证方法。 |
