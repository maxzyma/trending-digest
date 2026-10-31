# 用 Manus 重建 Manus：哪些变了，哪些出了问题，以及我们现在如何工作

> Rebuilding Manus with Manus: What changed, what broke, and how we work now

> 来源：Manus Blog / Manus，2026-10-30
> 原文链接：https://manus.im/blog/rebuilding-manus-with-manus
> 分类：人工智能 / 人机协作

## 核心要点

- Manus 的实践显示，单独叠加 AI 工具不足以改变工作方式，贯通需求、执行与验证的闭环才开始带来整体变化。
- 内部工具 Mono 通过统一入口、仓库说明、业务上下文和架构决策记录，让智能体按需获取跨仓库信息，并逐步支持本地验证、生产问题诊断、发布和端到端测试。
- 用户报告的 bug 由不同智能体分别负责调查分诊、代码修改和独立验证，工程师决定是否修复，合并与发布仍需获得人员明确批准。
- 团队通过让智能体参与讨论、运行真实用户流程和接受代码审查来建立信任，同时对支付、模型调用和成本相关变更设置额外规则。
- 一次自主循环在周末产生了两百多个待决事项，使团队认识到自主运行需要可检验的成功条件，而产品改动是否值得做仍须由人判断并负责。
- 工程提速后，高质量产品需求成为新的瓶颈，Mono 帮助部分产品经理直接交付功能，也使人的职责更多转向制定规则、监督执行和判断结果。
- 营销团队的 AI 队友在限定权限内连接合作流程中的多个系统，处理状态更新、任务分派、上下文学习和跨团队核实，重要决策仍由人作出。
- 共享智能体会话、先向智能体查询信息以及集中呈现待决事项减少了同事之间的打断，但并行任务增多也带来了注意力分散、信息碎片化和整体责任归属问题。
- 团队将 AI 支出用于换取时间与注意力、探索模型能力边界和发现产品中的资源浪费，并预期成本会下降，但尚未将这一预期视为承诺。
- Manus 计划继续探索共享会话、跨设备与人员接续工作以及主动提出方案的智能体，同时将定义问题、判断质量、决定取舍和承担结果保留为人的核心职责。

## 正文

*作者：Tao Zhang，Manus 联合创始人兼首席产品官*

> *By Tao Zhang, Co-founder and Chief Product Officer, Manus*

9 月下旬，在 Manus 2.0 最后冲刺阶段，我在 Slack 上给我们的一位工程师发了几条功能需求和 bug 报告。后来我去看看他进展如何。他的屏幕上开着一排 agent 会话，有的在 Manus 里，有的在 Codex 里。我点开其中一个，发现提示词正是我那条 Slack 消息，一字不差地粘贴了进去。

> In late September, during the final push on Manus 2.0, I sent one of our engineers a few feature requests and bug reports on Slack. Later I went to check how he was getting on. His screen had a row of open agent sessions, some in Manus and some in Codex. I clicked into one. The prompt was my Slack message, pasted word for word.

一年前，他会先读我的消息，弄清我的意思，然后再写代码。现在，由智能体读取请求、找到相关代码并提出修改方案。工程师的工作是指挥这项工作、检查结果，并对最终成果负责。大多数时候，请求都在运行中，而不是在等他。如今在我们这里，一名工程师同时推进 10 到 20 个请求是很常见的事。

> A year ago, he would have read my message, worked out what I meant, and then written the code. Now an agent reads the request, finds the relevant code, and proposes a change. The engineer's job is to direct the work, check it, and own the result. Most of the time a request is running, not waiting on him. Today, it's common here for one engineer to have 10 to 20 requests moving at once.

我为团队如此迅速地适应而感到自豪，但我也感到不安。这样的节奏对吗？还有什么是我们尚未察觉的？

> I'm proud of how quickly our team has adapted. I'm also uneasy. Is this pace right? What haven't we noticed yet?

我们在 Manus 构建智能体，因此给自己定下两条规矩：一是用我们自己的产品做真正的工作；二是不断寻找 AI 失灵的地方。

> We build agents at Manus, so we hold ourselves to two rules. We use our own product for real work. And we keep looking for the places where AI stops working.

我想记录下，当人与智能体默认并肩工作时，公司内部会发生什么。本文涵盖工程、产品和市场三个团队，也包括那些没有奏效的做法。这是一份关于一项仍在进行中的实验的报告，而不是对“AI 原生组织”的定义。

> I'd like to document what happens inside a company when people and agents work side by side by default. This post covers three teams — engineering, product, and marketing — and it includes what hasn't worked. It's a report of an experiment in progress, not a definition of an "AI-native organization."

**目前我们已了解到：**

> **What we've learned so far:**

- 没有中间状态可言。在旧的工作方式上叠加 AI，有时只是徒增噪音。只有当闭环真正形成时，情况才开始改变。
- 智能体需要掌握全局。对我们来说，更好的上下文比更好的提示词作用更大。
- 信任来自测试和上下文，而不仅仅取决于模型质量。
- 自主需要一条终点线。只有当成功与否可以被检验时，智能体才能自行运行。在其他所有情况下，都由人来做决定。
- 瓶颈会转移。当工程变得更快之后，决定要构建什么就成了新的制约因素。
- 人的作用并没有减弱，而是更加聚焦于影响更大的事情。

> • There's no halfway point. Adding AI to old ways of working sometimes added noise. Things changed only when the loop closed.
> • Agents need the whole picture. Better context did more for us than better prompts.
> • Trust comes from tests and context, not from model quality alone.
> • Autonomy needs a finish line. Agents can run on their own only when success can be checked. Everywhere else, a person decides.
> • The bottleneck moves. When engineering got faster, deciding what to build became the constraint.
> • The role of people hasn't diminished. It has become more focused on higher-impact things.

#### 1. 没有中间地带

> 1. There's no halfway point

2026 年之前，我们的做法和大多数公司一样：把 AI 加进我们原有的工作方式里。这意味着支持团队会附上 AI 摘要来标记问题，工程师使用编码助手，机器人在频道里发布分析。每个部分单独来看都有用，但它们彼此之间很少相互连通。在这个闭环真正打通之前，我们其实只是沿用老一套的工作方式，只不过多了许多 AI 在那里各说各话。

> Before 2026, we did what most companies did: we added AI to the way we already worked. This meant support would flag issues with an AI summary, engineers used coding assistants, and bots posted analysis in channels. Every piece was useful on its own, but not many of the pieces were connected to one another. Until the loop actually closed, we were simply working the same old way but with a lot of AI talking over each other.

有一句话我们常常回过头来提起：软件工程是程序设计在时间上的积分。写代码容易衡量，而让一个复杂产品多年保持健康却不然。AI 编写的代码占比很高，可能意味着真正的进步，也可能意味着在堆积垃圾代码，日后总得有人来收拾。

> There's a line that we often come back to: software engineering is programming integrated over time. Writing code is easy to measure; keeping a complex product healthy for years is not. A high percentage of AI-written code can mean real progress, or it can mean piling up slop that someone will have to clean up later.

我们真正关心的检验要难得多。Manus 是一款已上线一年多的复杂产品。在新的工作方式下，它能否在不崩溃的前提下持续改进，同时让每个人完成更多工作？到目前为止，答案是肯定的。

> The test we care about is harder. Manus is a complex product that has been live for more than a year. Can it keep improving under new ways of working without collapsing, while each person gets more done? So far the answer is yes.

#### 2. 向智能体提供完整的全局信息

> 2. Give the agent the whole picture

和大多数科技公司一样，我们在交接环节损失的时间最多。前端工程师和后端工程师会各自理解一个需求，商定一个接口，然后花上好几天修复两边对不上的地方。两个人对同一个需求的理解很少完全一致。

> Like most tech companies, we lost the most time at handoffs. A frontend engineer and a backend engineer would each interpret a request, agree on an interface, and then spend days fixing the mismatches. Two people rarely understand a requirement the same way.

如果 AI 能够编写全栈代码，那么能否由一个人端到端地负责一个需求？障碍在于上下文。我们的代码分散在各自独立的代码仓库中，因此没有任何一个智能体能同时看到整个系统。

> If AI can write code across the stack, could one person own a request end to end? The obstacle was context. Our code lived in separate repositories, so no agent could see the whole system at once.

我们对此的回答始于一次内部实验。我们想看看，在尽可能少的人工参与、几乎不手写代码的情况下，AI 在构建产品方面能走多远。在此过程中我们摸索出的方法，最终成为了我们现在称为 Manus-mono（简称 Mono）的内部工具。

> Our answer to that began with an internal experiment. We wanted to see how far AI could go in building a product with as little human input as possible and almost no hand-written code. The method we developed along the way became the internal tool we now call Manus-mono, or Mono.

Mono 并不会合并我们的代码仓库。它是一个统一入口，外加一份专门为智能体编写的手册：说明每个仓库的用途、它们如何相互配合，以及我们的工作方式。智能体会按需拉取所需的内容。我们还维护着一个架构决策记录库，因此每次智能体会话开始时，掌握的不只是代码，还有以往决策背后的思路。无论谁与智能体协作，这个智能体都拥有此前所有人留下的上下文。

> Mono doesn't merge our repositories. It's a single entry point plus a manual written for the agent: what each repository does, how they fit together, and how we work. The agent pulls in whatever it needs. We also keep a library of architecture decision records, so every agent session starts with the reasoning behind past decisions, not just the code. When anyone works with an agent, that agent has the context of everyone who came before.

Mono 是逐步发展起来的，每一步都解决了上一步暴露出的瓶颈：

> Mono grew in steps, and each step fixed the bottleneck the previous one exposed:

1. 纵观整个系统。我们补充了任何单个代码仓库都不具备的业务上下文，并借助 Git worktree 实现并行工作。
2. 在本地验证。过去推送到测试环境需要 5 到 10 分钟。现在完整的 Manus 技术栈可以在笔记本电脑上运行，检查只需几秒钟。
3. 调试生产环境问题。在权限受限的范围内，Mono 可以读取诊断生产环境 bug 所需的日志、配置和错误报告。
4. 端到端运行发布流程。过去工作常常卡住的发布步骤，现在由 Mono 来处理。审批决策仍由人来做。
5. 端到端测试。当验证成为拖慢进度的环节时，Mono 开始使用测试账号，在浏览器和移动端模拟器中运行真实的用户流程。

> 1\. See the whole system. We added the business context that no single repository contains, and used Git worktrees for parallel work.
> 2\. Verify locally. A push to the test environment used to take 5 to 10 minutes. Now the full Manus stack runs on a laptop, and checks take seconds.
> 3\. Debug production issues. With scoped permissions, Mono can read the logs, configuration, and error reports it needs to diagnose bugs in production.
> 4\. Run releases end to end. Mono now handles the release steps where work used to stall. People still make the approval decisions.
> 5\. Test end to end. When verification became the slow part, Mono started running real user flows with test accounts, in a browser and in a mobile simulator.

[视频](https://files.manuscdn.com/assets/dashboard/materials/2026/10/30/b6fca5b3fbf94f09b98a375823a30b8de3db11abb4d67f2a2670eaec54771f0d.mp4)

> [Video](https://files.manuscdn.com/assets/dashboard/materials/2026/10/30/b6fca5b3fbf94f09b98a375823a30b8de3db11abb4d67f2a2670eaec54771f0d.mp4)

（介绍 Mono 的工作原理及其演进历程。由一位队友使用 Manus 制作。）

> (How Mono works and how it evolved. Made by a teammate with Manus.)

常有人问 Mono 是不是一个代码 wiki。文档只是其中一部分，其余则是围绕代码的一切：我们如何测试、如何发布、我们做出了哪些决定以及为什么，还有智能体可以碰什么、不可以碰什么。

> People sometimes ask whether Mono is a code wiki. Documentation is one part of it, but the rest is everything around the code: how we test, how we release, what we decide and why, and what the agent is and isn't allowed to touch.

随着时间推移，Mono 已成为一个共享知识库，大家不断往里补充内容，它也越来越好用。例如，我们的运维工程师厌倦了总被人找去帮忙发版，于是他把发布流程写进了 Mono。现在任何人都能执行发布，智能体也可以，但审批权仍掌握在拥有发布权限的人手中。我很喜欢团队的这种工作方式：一个人解决了自己的烦恼，结果让整个公司都快了一点。

> Over time, Mono has become a shared knowledge base that gets better as people add to it. For example, our ops engineer got tired of being asked to help with releases, so he wrote the release process into Mono. Now anyone can run a release, and so can the agent, but approval still sits with people who have release rights. I love how the team works: one person fixed his own frustration, which led to the whole company getting a little faster.

团队现在默认一个人就能在所有平台上交付一个需求。我们的移动团队自始至终只有七个人。他们维护着两款产品的四个应用，并且始终跟上 Web 端的节奏。

> The team now assumes that one person can ship a request on every platform. Our mobile team has been seven people this whole time. They maintain four apps across two products and keep pace with web.

Mono 在没有任何自上而下强制要求的情况下推广到了全公司。我认为，这既要归功于工具本身，也同样要归功于文化。探索 AI 的极限是我们存在的意义之一，而且我们的组织是扁平化的。一个工具能走多远，取决于组织允许它走多远。

> Mono spread across the company with no top-down mandate. I think culture explains that as much as the tool does. Testing AI's limits is part of why we exist, and our organization is flat. A tool goes only as far as the organization lets it.

#### 3. 闭环：从用户的 bug 报告到经过验证的修复

> 3. Close the loop: from a user's bug report to a verified fix

Mono 让任何人都能参与产品的任何部分。这只是其中一半。另一半是让智能体自行发现问题。

> Mono let anyone work on any part of the product. That was half of it. The other half was letting agents find problems on their own.

在大多数互联网公司，用户提交的 bug 报告要先经过客服、产品和分诊环节，才能到达能够修复它的工程师手中。

> At most internet companies, a user's bug report passes through support, product, and triage before it reaches an engineer who can fix it.

在我们这里，现在由一个内部 agent 先调查报告，并将问题追溯到引发它的那次变更。然后它会在 Slack 上发帖，并标记负责该变更的工程师。工程师判断这个问题是否该由自己修复，再把它交给自己的 agent。另一个独立的 agent 会通过运行关键的测试和流程来验证修复。

> For us, an internal agent now investigates the report first and traces the issue back to the change that caused it. Then it posts in Slack and tags the engineer who owns that change. The engineer decides whether it's theirs to fix and hands it to their own agent. A separate agent checks the fix by running the tests and flows that matter.

三个智能体，三种角色：一个负责分诊，一个负责干活，一个负责检查。居中的那个人负责拍板。如今，我们越来越多的工程工作都是这样开始的：由智能体把问题带给人。

> Three agents, three roles: one triages, one does the work, one checks it. The person in the middle makes the calls. A growing share of our engineering work now starts this way, with an agent bringing a problem to a person.

这个循环有明确的边界。负责阅读用户报告的智能体无法修改代码，它只能进行调查并向我们汇报。代码修改由工程师自己的智能体完成，且须在工程师做出决定之后进行。未经拥有发布权限的人员批准，任何内容都不会发布。

> This loop has clear limits. The agent that reads user reports can't change code. It can only investigate and report back to us. Changes come from the engineer's own agent, after the engineer decides. Nothing ships without approval from a person with release rights.

#### 4. 我们如何学会信任智能体编写的代码

> 4. How we learned to trust agent-written code

很长一段时间里，所有合入主分支的变更都需要两位资深工程师中的一位签字批准。我们对 AI 的信任还不足以跳过这一步。随着智能体产出的代码越来越多，这个评审环节成了瓶颈。

> For a long time, every change that went into our main branch needed sign-off from one of two senior engineers. We didn't trust AI enough to skip that step. As agents produced more code, that review step became the bottleneck.

就纯粹的编码能力而言，模型已经很强了。我们意识到，差距归结为两点。第一，人知道如何测试自己的工作成果。第二，人参与过上下游的讨论，因此知道对业务而言什么才算“对”。正确的代码不等于正确的产品。

> On pure coding ability, the models were already strong. We recognized the difference came down to two things. First, people know how to test their work. Second, people have been part of the discussions upstream and downstream, so they know what "right" means for the business. Correct code isn't the same as the correct product.

我们对这两点都做了处理：

> We addressed both:

- 让智能体加入讨论。现在，每位工程师的智能体都会待在它被拉入的 Slack 讨论串中，并跟进上下文。当终于有人说出“开始”时，智能体已经知道团队做出了什么决定以及原因。
- 让智能体进行端到端测试。我们与后端团队合作，让智能体能够在每次改动后于 Manus 中运行真实流程和回归测试。随着测试覆盖率的提升，我们的信任也随之增长。

> • Let agents join the discussion. Each engineer's agent now sits in the Slack threads it has been added to, and follows the context. When someone finally says "Go," the agent already knows what the team decided and why.
> • Let agents test end to end. Working with our backend team, we gave agents the ability to run real flows and regression tests in Manus after each change. As test coverage grew, our trust grew with it.

如今，每一项变更都要经过这一验证，并由运行当前最强模型的代码审查机器人进行审查，对支付等敏感领域还设有额外规则。机器人取代的是排队等待，而不是人的决策。智能体可以发起拉取请求，但未经人员明确批准，无法合并到我们的主分支。决定构建什么、由谁发布的，仍然是人。

> Today, every change goes through that verification and through a code review bot running the strongest model available, with extra rules for sensitive areas such as payments. The bot replaced the queue, not the human decision. An agent can open a pull request, but it can't merge into our main branch without explicit approval from a person. People still decide what gets built and who can release.

#### 5. 自主性需要一个最终目标

> 5. Autonomy needs an end goal

信任是有限度的，这一点我们是吃了苦头才明白的。

> Trust has limits, and we found this out the hard way.

曾有一段时间，大家都对完全自主的智能体循环（agent loop）充满热情，于是我们也试了一次。一个智能体从我们的内部反馈渠道收集反馈，并为每一条反馈创建一个项目。一位同事让它在周末持续运行。到了周一早上，已有 200 多个事项在等他做决定。

> At one point, everyone was excited about fully autonomous agent loops, so we tried one. An agent collected feedback from our internal feedback channels and started a project for each item. A teammate let it run over a weekend. On Monday morning, more than 200 items were waiting for his decision.

为什么不让智能体也来做这些决定呢？只有当系统能够检验目标是否达成时，自主循环才行得通。测试要么通过，要么失败；页面要么能加载，要么不能。而大多数实际工作并没有这样的检验手段。必须由人来判断它是否已经完成，以及它究竟是否值得去做。

> Why not let the agent make those decisions too? Autonomous loops work when the system can check whether the goal has been met. Tests pass or fail; a page loads or it doesn't. Most real work has no such check. A person has to judge whether it's done, and whether it was worth doing at all.

那个周末给了我们两点教训。第一，人做决策的速度，赶不上一个不受约束的循环制造决策的速度。第二，如果没有人决定某件事该不该做，就没有人对结果负责。第 3 节中的 bug 修复循环之所以奏效，是因为测试定义了什么算成功。产品决策没有测试，所以在 Manus，每一项产品改动仍然始于由一个人来决定它是否值得做。

> We took two lessons from that weekend. First, people can't make decisions as fast as an unchecked loop creates them. Second, if no one decides whether something should be done, no one owns the result. The bug-fixing loop in section 3 works because tests define success. Product decisions don't have tests, so every product change at Manus still starts with a person deciding whether it's worth doing.

#### 6. 当工程变得更快，产品就成了瓶颈

> 6. When engineering got faster, product became the bottleneck

传统的产品流程有许多交接环节，每经过一次交接，优先级就会偏移一点。随着编码智能体让工程师的效率越来越高，一个新问题出现了：没有足够的产品经理来撰写高质量的需求。这是第一次，工程不再是瓶颈。

> A traditional product process has many handoffs, and priorities drift a little at each one. As coding agents made engineers faster, a new problem appeared: there weren't enough product managers to write good requirements. For the first time, engineering wasn't the constraint.

在 Manus，我们最初的解决办法是让几位工程师成为“builder”，负责一个问题从发现到上线的全过程。但同时具备技术判断力和产品判断力的人寥寥无几。接下来，我们让产品经理改代码。这同样陷入了停滞。交接环节依然存在，而且由于缺乏工程师的直觉，产品经理能改文案和交互，却改不了底层逻辑。

> At Manus, our first fix was to ask a few engineers to become "builders" who own a problem from discovery to launch. Few people had both the technical and product judgment. Next we let PMs change code. That stalled too. The handoffs were still there, and without an engineer's instincts, PMs could change copy and interactions but not the underlying logic.

Mono 解决了这两个问题，因为它自带规则：

> Mono solved both problems because it carries the rules with it:

- 任何涉及模型调用或成本的改动，都必须在编写代码之前获得负责人的签字批准。
- 每一项变更都要经过与工程师所做变更相同的审查和测试。
- Mono 可以使用测试账号走完注册和支付流程，并记录每一个步骤，让产品经理能够准确指出问题出现的那一刻。

> • Any change that touches model calls or cost needs the owner's sign-off before code is written.
> • Every change goes through the same review and testing as an engineer's change.
> • Mono can walk through sign-up and payment with test accounts and record each step, so a PM can point to the exact moment something breaks.

下面是实际中的样子。一位负责语音转文字的产品经理让 Manus 对 10 多个模型进行了基准测试，然后选定了其中一个。她通过 Mono 拉取了前端代码，用我们的设计系统搭建了一个演示，并让 Manus 把每个用户场景渲染成图片供她审阅。她把这个演示做成了一段视频。整个方案足够清晰，于是她亲自构建了这个功能，包括网页端和桌面端的 UI。

> Here's what that looks like in practice. A PM working on speech-to-text had Manus benchmark more than 10 models, then chose one. She pulled the frontend code through Mono, built a demo in our design system, and had Manus render each user scenario as an image for her to review. She turned the demo into a video. The plan was clear enough that she built the feature herself, including the web and desktop UI.

在这个过程中，人做了三个决定。她选择了模型。产品和设计团队评审了演示。一位拥有发布权限的工程师审查了代码。一年前，这一切都还不可能实现。

> People made three decisions along the way. She chose the model. Product and design reviewed the demo. An engineer with release rights reviewed the code. A year ago, none of this would have been possible.

我们将其描述为从“人在回路中”（human in the loop）转向“人在回路*之上*”（human on the loop）。过去，AI 完成一项任务的 70%–80%，剩下的由人来补足。如今，人负责制定规则、监督多个智能体、在关键节点检查方法与结果、在必要时介入，并对最终结果负责。

> We describe this as moving from human in the loop to human *on* the loop. AI used to do 70-80% of a task and people filled in the rest. Now people set the rules, supervise several agents, check methods and results at key points, step in when needed, and own the outcome.

现在，一些产品经理在交接时不再提供书面规格说明或设计稿，而是一段简短的视频。短短几分钟里，视频就能展示用例、每个界面、每次点击会触发什么、边界情况如何表现，以及底层是如何运作的。对我们来说，设计、工程和 QA 能更快地就“完成”的含义达成一致，而产品经理只需讲解一次。

> Some PMs now hand off a short video instead of a written spec or mockups. In a few minutes, it shows the use case, each screen, what each click does, how edge cases behave, and how it all works underneath. For us, design, engineering, and QA agree on what "done" means faster, and the PM explains it once.

[视频](https://files.manuscdn.com/assets/dashboard/materials/2026/10/30/1903e1ee8271507ca42546ece60e872cc1707e9d05b22251b7e949f628b6ab87.mp4)

> [Video](https://files.manuscdn.com/assets/dashboard/materials/2026/10/30/1903e1ee8271507ca42546ece60e872cc1707e9d05b22251b7e949f628b6ab87.mp4)

（语音输入的产品需求视频）

> (Product requirement video for voice input)

如今，我们大约一半的产品经理能独立交付功能，而且每位产品经理都提交过代码。设计师们也开始这样做了。一位产品经理用 Manus 2.0 编写了 Manus Studio 的大部分界面，另一位编写了 Video Editor。这些成果的背后，都是有人花了数月时间，不断突破自己角色原本的边界。这是我最引以为傲的。

> Today about half of our PMs ship features on their own, and every PM has committed code. Designers have started too. One PM wrote most of the Manus Studio interface in Manus 2.0. Another wrote the Video Editor. Behind each of these is someone who spent months pushing past what their role used to cover. That's what I'm proudest of.

这并不意味着每个人都必须成为构建者。当公司里任何人都能动手构建时，人们可能会发布一些本不该存在的东西。我们的产品团队经常问一个问题：“如果这件事只需一秒钟、不花任何成本，你会发布它吗？”有时答案是否定的。我们仍然需要模块负责人来决定构建什么、不构建什么，以及用户最终会看到什么。我们也需要有人来维护像 Mono 这样的基础设施。当构建变得容易时，决定构建什么就变得更加重要。

> This doesn't mean everyone has to be a builder. When anyone in a company can build, people may ship things that shouldn't exist. Our product team often asks one question: "If this took one second and cost nothing, would you ship it?" Sometimes the answer is no. We still need module owners who decide what gets built, what doesn't, and what users finally see. We also need people who maintain infrastructure like Mono. When building gets easy, deciding what to build matters more.

#### 7. 营销工作流中的 AI 队友

> 7. An AI teammate inside the marketing workflow

一次营销合作要经历脚本审核、定价、签约、审批、付款、上线和效果复盘等环节。这些环节分散在电子邮件、合同工具、审批系统、电子表格和广告平台中。过去，这项工作的大部分时间都花在了在这些系统之间搬运信息上，留给需要判断力的创意工作的时间所剩无几。

> A marketing partnership moves through script review, pricing, contracts, approvals, payment, launch, and results review. Those steps live in email, contract tools, approval systems, spreadsheets, and ad platforms. Much of the job used to be moving information between them, which left little time for the creative work that requires judgment.

我们最初只是想解决一个小问题：合作方内容或广告上线时，我们常常很晚才得知。于是我们让 AI 写了一个脚本，用来检测内容何时发布。接着，我们想要效果数据。然后是对过往合作的复盘。再后来，整个内部工作流都打通了：合同一签署或审批一通过，智能体就会更新状态，并通知负责下一步的人。

> We started with one small problem: when partner content or an ad went live, we often heard about it late. So we had AI write a script that detects when content is published. Then we wanted performance data. Then a review of past partnerships. Then the whole internal workflow connected: when a contract is signed or an approval clears, the agent updates the status and notifies whoever owns the next step.

Manus 把这一切都构建进了一个内部站点。对人来说，它是仪表盘和日历；对智能体来说，它是一组工具。在我们的工作流中使用这些工具的智能体，就是我们所说的 AI 队友。它只在团队为其接入的频道和系统中工作，访问权限也仅限于这一工作流。

> Manus built all of this into an internal site. For people, it's dashboards and a calendar. For the agent, it's a set of tools. The agent that uses those tools inside our workflow is what we call an AI teammate. It works only in the channels and systems the team has connected it to, with access scoped to this workflow.

它的作用如下：

> Here's what it does:

- 它自行管理自己的消息队列。许多人会同时给它发消息，因此它在一个“前台”会话中与所有人交谈，并把任务分派给并行的会话。它会先判断一条消息是否与自己相关，再决定是打断当前工作还是稍后处理。这些规则是它在开发过程中自己提出的，我们审核之后才予以保留。
- 它能从转发的上下文中学习。过去，调整策略意味着要开一次会、写一份简报。现在，我们的市场负责人只需把讨论内容转发过去，说一句：“学一下这个。”
- 它会持续关注长期目标。有一次，在一个它被拉入的 Slack 讨论串中，团队成员都记不清某个项目进展到了哪一步。它在没有被提及的情况下主动回复道："B 还在测试中。我们是否应该等 A 的结果出来后再看 B？"
- 它会与其他团队核实事实。在我们推出 3D 模型绑定功能后，它向产品团队询问了具体支持哪些内容。它了解到绑定功能涵盖七个类别，包括鱼类、蛇类和四足动物，因此我们的描述始终保持准确。

> • It manages its own queue. Many people message it at once, so it talks to everyone in one "front desk" session and hands tasks to parallel sessions. It decides whether a message is relevant to it, then whether to interrupt current work or wait. It proposed these rules itself during development, and we reviewed them before keeping them.
> • It learns from forwarded context. A strategy change used to mean a meeting and a written brief. Now our marketing lead forwards the discussion and says, "Learn this."
> • It keeps long-running goals in view. On one occasion, teammates in a Slack thread it had been added to couldn't recall where a project stood. Without being tagged, it replied: "B is still in testing. Should we wait for A's results before looking at B?"
> • It checks facts with other teams. After we launched 3D model rigging, it asked the product team what was supported. It learned that rigging covers seven categories, including fish, snakes, and quadrupeds, so our descriptions stayed accurate.

现在，同事们会把它带进脚本评审和报价评审，因为它读过我们过往的合作记录。最终拍板的仍然是人。

> Teammates now bring it into script and pricing reviews, because it has read our past partnership records. People still make the call.

内部站点也可以借助自身用户（包括智能体）的反馈不断改进。当智能体遇到阻碍时，它会通过一个反馈端点提交请求。该请求会借助 Manus 2.0 中的 Automations 功能在 Manus 中创建一个开发任务，并由工程师在变更上线前进行审核。这一机制已运行了大约一周。在真正依赖它之前，我们还需要更多案例。

> The internal site can also improve from its own users, including the agent. When the agent hits friction, it files a request through a feedback endpoint. That opens a development task in Manus through Automations in Manus 2.0, and an engineer reviews the change before it ships. It has run for about a week. We need many more cases before we rely on it.

那么，团队里的人做什么呢？有三件事仍由他们负责。他们做出并负责每一个重要决策。他们处理智能体未曾遇到过的情况，并教会它该怎么做或该去问谁。每当它的分析指向一个新的角度时，他们也会为它调整方向。

> So what do the people on the team do? Three things stay with them. They make and own every important decision. They handle cases the agent hasn't seen, and teach it what to do or whom to ask. And they redirect it whenever its analysis points to a new angle.

#### 8. 减少相互打断

> 8. Interrupt each other less

在所有这些团队中，许多问题已经不再需要打扰别人。

> Across all these teams, many questions no longer require interrupting someone.

先问 agent。一位同事在 Mono 上搭建了一个 Slack 机器人，它运行在云端计算机上，并在消息串中回复。用得最多的是非工程师。这个功能是怎么工作的？这个字符串在哪里？这个已经上线了吗？他们不再需要先去找负责人了。

> Ask the agent first. A teammate built a Slack bot on Mono that runs on a cloud computer and replies in the thread. Non-engineers use it most. How does this feature work? Where is this string? Has this shipped? They no longer need to find the owner first.

直接打开会话，而不是询问进展。过去，工程师的进展只存在于其本人的 AI 对话中，一旦下线，别人便无从得知。因此我们开发了一项内部功能，让同一项目的成员可以查看彼此的会话，并申请加入。工程师可能借助智能体完成某个功能的大部分开发，随后产品经理加入同一个会话，调整间距、样式和文案。在他人的会话中发言需要获得会话所有者的批准，我们仍在完善相关权限设计。

> Open the session instead of asking for a status update. An engineer's progress used to live in their own AI chats, invisible once they logged off. So we built an internal feature that lets members of a project see each other's sessions and ask to join. An engineer might build most of a feature with the agent, and then a PM joins the same session to adjust spacing, styles, and copy. Posting in someone else's session requires their approval, and we're still working out the permissions.

![How an engineer, a PM, and a designer work in one session](https://files.manuscdn.com/assets/dashboard/materials/2026/10/30/555809c7e478f1452de193557b3e53d840e1dba6804d42452b258d0fa94ba160.webp)

（示例说明：工程师、产品经理和设计师如何在同一个会话中协作。并非真实的定价变更。）

> (Illustrative example: how an engineer, a PM, and a designer work in one session. Not a real pricing change.)

重点不是减少彼此之间的交流，而是减少彼此之间的打断。

> The point isn't to talk to each other less. It's to interrupt each other less.

只决定需要决定的事。我们使用 AI 最多的用户只保留一个主会话，它只有一项任务：列出需要他做决定的事项，并为每一项给出建议。Slack 上消息繁忙时，他不去参与，而是问：“我现在需要决定什么？”

> Decide only what needs deciding. Our heaviest AI user keeps one main session with a single job: list what needs his decision, with a recommendation for each. When Slack gets busy, he stays out of it and asks, "What do I need to decide right now?"

我也有类似的做法。我每天有 20 多项待办，而且正如我公开分享过的，我有 ADHD。对我来说，最难的是开始。现在，每一项待办都会进入一个专门的 Manus 项目，由它把每一项分别转成独立的任务。能先动手的，它就先动手。拿不准的时候，它会向我询问背景信息，以及应该由哪位 PM 来负责。然后，借助我授予它的我本人的 Slack、Gmail 和 Notion 访问权限，它会收集相关上下文，交给 PM 一份完整的需求，而不是一句话的便条。对我来说，这种变化不只关乎效率。如今我每天为不知从何下手而焦虑的时间少了很多，这在个人层面上意义重大。

> I do something similar. I have more than 20 to-dos a day, and, as I've shared publicly, I have ADHD. Starting is the hardest part for me. Now every to-do goes into a dedicated Manus project that turns each one into its own task. It starts what it can. When it's unsure, it asks me for background and which PM should own it. Then, using the access I've given it to my own Slack, Gmail, and Notion, it gathers the context and hands the PM a complete request instead of a one-line note. For me, the change isn't only about efficiency. I now spend much less of my day anxious about where to begin, which is huge on a personal level.

#### 9. 值得付出这样的代价吗？

> 9. Is it worth the cost?

我们在 AI 上投入很大，也会密切跟踪这笔开支。我们不会用它来评判任何人的绩效，而是用它来评判这笔开支本身：它是现在就带来了回报，还是在为未来打下基础？

> We spend a lot on AI, and we track that spend closely. We don't use it to judge anyone's performance. We use it to judge the spend itself: is it paying off now, or setting us up for later?

以下是我们认为它能带来的收益，以及我们预期成本会落在哪里：

> Here's what we think it buys us, and where we expect the cost to go:

- It buys time and attention. As a team grows, coordination eats into everyone's attention. AI protects each person's attention and gives them fuller ownership of their work. And we're still hiring.
- Using the best models is how we learn where AI's limits are. The verification and code review setup described in section 4 runs on the strongest models we can get. The colleague who leads developer productivity calls it our best-value spend.
- 成本应该随着产品的改进而下降。如今，我们有更多开发工作是在自家产品 Manus Studio 中完成的，因此，我们的使用数据能让我们看出哪些地方浪费了 token。相应的改进会融入产品，因此也应该能让用户更高效地使用 Manus。我们预计，随着模型价格下降，以及我们消除浪费，目前的成本将大幅降低。这是我们的判断，不是承诺！

> • It buys time and attention. As a team grows, coordination eats into everyone's attention. AI protects each person's attention and gives them fuller ownership of their work. And we're still hiring.
> • Using the best models is how we learn where AI's limits are. The verification and code review setup described in section 4 runs on the strongest models we can get. The colleague who leads developer productivity calls it our best-value spend.
> • The cost should fall through the product. More of our development now happens in Manus Studio, our own product, so our usage data shows us where tokens are wasted. The fixes go into the product, so they should make Manus more efficient for users too. We expect today's costs to fall substantially as models get cheaper and we remove waste. That's a belief, not a promise!

#### 10. 哪些方面尚未奏效

> 10. What isn't working yet

打断少了，注意力却更分散了。过去一天处理四五件事的人，现在可能同时推进 20 或 30 件事。每次切换都意味着要重新熟悉上下文。AI 扩展了人们的能力，也促使他们做更多事。一位产品经理告诉我，只要有任务正在运行，她就忍不住再启动一个智能体。做更多事并不是目标。我们把这种情况视为需要解决的问题，而不是值得赞美的工作节奏。

> There are fewer interruptions, but attention is more fragmented. Someone who used to handle four or five things a day may now push 20 or 30 forward at once. Every switch means reloading context. AI expands what people can do, and it also pushes them to do more. One PM told me that whenever a task is running, she can't resist starting another agent. Doing more things isn't the goal. We're treating this as a problem to solve, not a pace to celebrate.

Information is more scattered. Our head of product used to know every change and why it was made. Now he sometimes screenshots a problem and asks Mono, "Who changed this?" It's funny, but the question is real. When everyone is empowered to change the product, who is responsible for the whole?

> Information is more scattered. Our head of product used to know every change and why it was made. Now he sometimes screenshots a problem and asks Mono, "Who changed this?" It's funny, but the question is real. When everyone is empowered to change the product, who is responsible for the whole?

Sharing permissions need a redesign. When work can be shared and handed over, and agents sit in more of our conversations, we have to decide what's open and what needs approval.

> Sharing permissions need a redesign. When work can be shared and handed over, and agents sit in more of our conversations, we have to decide what's open and what needs approval.

Our fixes are still basic. For now, one agent supervises the others and reports only what's stuck and what needs a human decision. We know this can be better.

> Our fixes are still basic. For now, one agent supervises the others and reports only what's stuck and what needs a human decision. We know this can be better.

#### 11. 我们接下来要构建什么

> 11. What we're building next

These problems point to product work that other teams will probably need too. We didn't plan these features in advance. They came from problems we kept running into ourselves.

> These problems point to product work that other teams will probably need too. We didn't plan these features in advance. They came from problems we kept running into ourselves.

- Sessions as shared workspaces. One person raises a problem, a designer proposes a fix, an engineer builds it, and a PM runs it, all in the same place.
- Work that moves across devices and people. Local and cloud machines stay connected, so work can continue when people step away.
- 能发现人们未曾考虑过的选项的智能体。在公司系统内工作且拥有适当权限的智能体，应该能够提出解决方案，而不只是执行指令。

> • Sessions as shared workspaces. One person raises a problem, a designer proposes a fix, an engineer builds it, and a PM runs it, all in the same place.
> • Work that moves across devices and people. Local and cloud machines stay connected, so work can continue when people step away.
> • Agents that find options people hadn't considered. An agent working inside a company's systems, with the right permissions, should be able to suggest solutions, not just carry out instructions.

我们会先在自己身上试用这些，再将它们带给用户。

> We'll try these on ourselves first, then bring them to users.

#### 12. What people do now

> 12. What people do now

工程师同时开着一排智能体会话，这不只是一个关于效率的故事，更意味着组织赖以运转的方式正在改变。过去，公司通过岗位和层级传递信息。一个人能做多少事，取决于他能调动多少人力和资源。如今，我们花少量时间为 AI 提供上下文和工具，把更多时间用于判断和决策。越来越多的时候，是智能体把问题带到我们面前。决定如何处理这些问题，仍然是我们的职责。

> The engineer with a row of agent sessions open isn't just a story about efficiency. It's a change in what an organization runs on. Companies used to move information through roles and hierarchy. What one person could do depended on how many people and resources they could leverage. Now we spend a little time giving AI context and tools, and more time making judgments and decisions. More and more often, an agent is the one bringing a problem to us. Deciding what to do about it remains our job.

我们开过这样的玩笑：如果 Manus 能做这么多事，为什么还要来办公室？让智能体自己解决就好了。但重要的问题仍然需要人来提出、争论和拍板。例如，什么才算是好产品？或者，说得夸张一点：是打造一款有实际营收、不断突破 AI 能力边界的出色产品，还是追求利润率？AI 不知道我们想要哪一个，我们自己知道。文化和信任来自日复一日、也在关键时刻共同解决问题。每一次会话中的工作，都建立在这个基础之上。

> We've joked about it: if Manus can do this much, why come to the office? Let the agents work it out. But the important questions still need people to raise them, argue about them, and decide. For example, what counts as a good product? Or, to exaggerate a little: build a great product with real revenue that keeps pushing AI's limits, or go for the margin? AI doesn't know which one we want. We do. Culture and trust come from working through things together, day after day and in the moments that matter. That's the foundation the work in every session rests on.

So, for now, here's our answer. In our experiment as an AI-native organization, the role of people hasn't diminished. It has become more focused on areas where they can have the greatest impact: define the problem, judge quality, decide what's worth doing, own the result.

> So, for now, here's our answer. In our experiment as an AI-native organization, the role of people hasn't diminished. It has become more focused on areas where they can have the greatest impact: define the problem, judge quality, decide what's worth doing, own the result.

That's also why we're still hiring. People's skills and judgment are at the center of this way of working — and that isn't changing any time soon.

> That's also why we're still hiring. People's skills and judgment are at the center of this way of working — and that isn't changing any time soon.

写下这些文字时，我很好奇，一年后这篇文章会写些什么。每家公司都有不同的目标、组织结构和文化，因此可能既没有标准答案，也没有最终形态。但对于一家开发智能体的公司来说，弄清楚人与 AI 如何协作并不是可做可不做的事，而是工作的一部分。我们会继续探索，也会持续分享从中学到的东西。

> As I write this, I'm curious what this post would say a year from now. Every company has different goals, structures, and culture, so there may be no standard answer and no final form. But for a company that builds agents, working out how people and AI work together isn't optional. It's part of the job. We'll keep at it, and we'll keep sharing what we learn.

*A note on the numbers. Figures in this post come from internal records. Team sizes and PM shipping figures are as of late October. Some points are estimates or one person's experience rather than measurements.*

> *A note on the numbers. Figures in this post come from internal records. Team sizes and PM shipping figures are as of late October. Some points are estimates or one person's experience rather than measurements.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| AI agent | AI 智能体 | 能够利用上下文和工具执行任务、推进目标的人工智能系统。 |
| Context | 上下文 | 智能体完成任务所依据的需求、代码、讨论、业务背景与历史决策等信息。 |
| Full-stack development | 全栈开发 | 涵盖前端与后端等应用技术层次的开发工作。 |
| Git worktree | Git 工作树 | 允许同一 Git 仓库拥有多个工作目录以支持不同分支并行工作的机制。 |
| Architecture Decision Record | 架构决策记录 | 记录重要架构选择及其背景、理由和影响的文档。 |
| End-to-end testing | 端到端测试 | 沿完整用户流程验证系统各部分协同后是否产生预期结果的测试方式。 |
| Regression testing | 回归测试 | 在系统变更后检查既有功能是否仍按预期工作的测试。 |
| Code review | 代码审查 | 检查代码变更的正确性、质量及其是否符合相关要求的过程。 |
| Pull request | 拉取请求 | 向代码仓库提出合并变更并供审查和讨论的协作机制。 |
| Agent loop | 智能体循环 | 智能体反复获取信息、采取行动并依据反馈继续推进任务的执行过程。 |
| Human in the loop | 人在回路中 | 人在自动化流程内部参与任务执行、检查或决策的协作方式。 |
| Human on the loop | 人在回路之上 | 人通过设定规则、监督运行和必要时介入来管理自动化流程的协作方式。 |
| Benchmark | 基准测试 | 使用既定任务和评估标准比较模型或系统表现的方法。 |
| Message queue | 消息队列 | 暂存和组织待处理消息以协调任务接收与执行的机制。 |
| Token | 词元 | 模型处理文本时使用的基本单位，也是衡量模型用量与成本的常见依据。 |
