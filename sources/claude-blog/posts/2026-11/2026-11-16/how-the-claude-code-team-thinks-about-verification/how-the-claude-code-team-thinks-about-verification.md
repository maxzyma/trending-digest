# Claude Code 团队如何看待验证

> How the Claude Code team thinks about verification

> 来源：Claude Blog / Anthropic，2026-11-16
> 原文链接：https://claude.dev/blog/how-the-claude-code-team-thinks-about-verification/
> 分类：AI 工程 / 智能体验证

## 核心要点

- 验证循环是把更多工作委托给 Claude 的基础，有了它才能从一次运行一两个 Claude 扩展到并行运行几十乃至上百个。
- 测试、基准测试和规格说明如今可由智能体低成本生成，且以软件形式运行，可频繁执行而不消耗太多额外 token。
- 最值得投入的三类测试是端到端测试、属性测试和差分测试，同时要避免测试不稳定和运行缓慢这两种失败模式。
- 端到端测试难以被糊弄且完成标准明确，配合能启动、操控和检查应用的 skill 以及功能地图，可让智能体在真实系统上拥有“手”和“眼”。
- 属性测试通过生成大量输入去证伪往返编码、不变量、幂等性、等价性等断言，差分测试则以旧系统为预言机，适用于功能应保持不变的大规模迁移。
- 团队把实际运行变更视为验证的核心，用放在代码仓库中的 verify skill 固化冒烟测试方法，并让 Claude 在提交前使用它。
- 检查在三轮修复后仍未通过时由人类介入，代码所有者负责编写自己的检查，39 条可靠性检查则根据 diff 中的触发条件按需执行。
- 把关变更的规则必须位于该变更无法修改的分支上，评审要限定在具体提交上，成本低的检查应先在本地运行。
- 新的提交门禁先以观察模式上线以审查误报，再切换到强制模式，并保留附带说明和连续被拦截后放行的出口。
- 团队通过回滚率、基于历史事故的评估和分阶段召回率来审查审查者本身，把漏掉的案例转化为规则，并定期清理规则与测试。

## 正文

在 Claude Code 团队，我们绝大部分代码（约 90%）都由 Claude 编写并[由 Claude 审查](https://claude.dev/blog/solving-code-review-at-anthropic/)。在这样的规模下，我们如何让智能体具备用证据验证自身工作的能力，就变得极其重要。

> On the Claude Code team, the vast majority of our code (~90%) is written and [reviewed by Claude](https://claude.dev/blog/solving-code-review-at-anthropic/). At this scale, how we equip our agents to verify their work with evidence becomes extremely important.

验证循环是让你能把更多工作委托给 Claude 的基础构件。没有它们，你实际上一次只能运行一两个 Claude，因为所有东西都得你亲自检查。有了它们，你就可以并行运行几十个乃至上百个。

> Verification loops are the building block that lets you delegate more work to Claude. Without them, you can really only run one or two Claudes at a time, because you have to check everything yourself. With them, you can run dozens or hundreds in parallel.

这是因为，为智能体提供一种[验证自身输出的方式](https://claude.com/blog/building-verification-loops-in-claude-code-with-skills)，是提升质量的有效手段。在围绕结构化文件生成的内部测试中，让一个独立的评分器依据评分标准检查 Claude 的工作成果，相比标准的提示循环，[任务成功率最多提升了 10 个百分点](https://claude.com/blog/claude-managed-agents)，其中在最难的问题上提升幅度最大。

> That’s because giving agents a [way to verify their output](https://claude.com/blog/building-verification-loops-in-claude-code-with-skills) is an effective way to improve quality. In internal testing around structured file generation, having a separate grader check Claude’s work against a rubric [improved task success by up to 10 points](https://claude.com/blog/claude-managed-agents) over a standard prompting loop, with the largest gains on the hardest problems.

过去验证成本高昂的东西（测试、基准测试、规格说明、真实的端到端运行），如今只需向智能体提出请求即可低成本获得。与代码一样，智能体可以快速生成测试、基准测试和规格说明。而且一旦生成，这些测试和基准测试就以软件的形式运行，因此可以频繁运行，而无需消耗太多额外的 token。

> What was once expensive to verify (tests, benchmarks, specs, real end-to-end runs) is now cheap to request from an agent. Like code, agents can quickly generate tests, benchmarks, and specs. And once generated, these tests and benchmarks run as software so they can be run frequently without using many additional tokens.

你还可以利用验证结果来提升智能体在该任务上的表现，从而让验证形成闭环。例如，如果某个智能体在一项检查日志中是否包含用户数据的测试上反复失败，你可以创建一个钩子（hook），或在 CLAUDE.md 中写入一条更明确的规则，以避免日后再出问题。这样（基本上）就能防止问题再次发生。

> You can also close the verification loop by using the results to improve the agent’s performance on that task. For example, if an agent repeatedly fails a test that checks logs for user data, you can create a hook or a more explicit rule in your CLAUDE.md to avoid future issues. This (mostly) stops issues from happening again.

那么，既然验证对于高速产出高质量代码至关重要，你应该使用哪些类型的测试，又该如何在整个流水线中应用它们？本文将回答这些问题，并分享 Claude Code 团队所采用的流程。

> So if verification is critical to producing quality code at a high velocity, what types of tests should you use and how should you apply them across your pipeline? This article answers those questions and also shares the process used by the Claude Code team.

#### 并非所有测试都生而平等：3 种值得投入的测试

> NOT ALL TESTS ARE CREATED EQUAL: 3 TESTS WORTH INVESTING IN

无论你选择哪种测试类型，都有几种失败模式需要避免。

> No matter which test type you choose, there are a few failure modes to avoid.

如果你的测试不稳定，你就会让智能体养成重跑测试的习惯，而不是去修复出错的代码。如果你的测试很慢，智能体在各批次改动之间运行的测试就会减少，这会让问题定位变得困难。较重的测试最好在提交更改之前运行。

> If your tests are flaky you’ll train the agent to run them again rather than fixing the failing code. If your tests are slow, the agent will do fewer tests across batches which can make pinpointing issues difficult. Heavier tests are best deployed before you’ve committed the changes.

下面是我认为最值得投入的三类测试。

> Now, here are the three types of tests I think are most worth investing in.

##### 端到端测试

> E2E tests

如果只能专注于一种测试类型，那就选端到端测试。这类测试描述的是真实的用户流程，比如将商品加入购物车、结账，以及跳转到确认页面。

> If you have to focus on one test type, pick end-to-end. These tests describe real user flows like adding an item to a cart, checking out, and moving to a confirmation page.

端到端（E2E）测试之所以如此有效，是因为它们很难被糊弄——整个功能要么能正常工作，要么不能。它们还有明确的完成标准，并且能具体地告诉你哪里出了问题。

> The reason E2E tests are so effective is that they are difficult to fool–either the whole feature works or it doesn't. They also have definitive done criteria and can concretely tell you what’s broken.

![Unit test failure vs. end-to-end test failure. Left: checkout.test.ts shows only “FAIL checkout.test.ts / Error: Timeout after 30s”, captioned “Shooting blind. No step, no trace.” Right: checkout.spec.ts shows a step trace (Register, Add item to cart, Checkout failed, See confirmation page not reached), a screenshot of shop.example/checkout with “Payment form failed to load” and a disabled “Place order” button, and “What step failed: Checkout: ‘Place order’ stayed disabled because the payment form never loaded”, captioned “Screenshots, trace, and a description of what step failed.”](https://claude.dev/media/3c9c60f4b0696a20f33ef62b6ddcb99c322fd19c440c28de234a6c804f7912a4.png)

虽然单元测试更快、也更不容易出现不稳定的情况，但有可能通过了测试却仍然破坏了功能。这是因为智能体和测试都不理解完整的任务。

> While unit tests are faster and less flaky, it’s possible to pass them and still break the feature. This is because both the agent and the test don’t understand the full task.

对于 E2E 测试，让你的 agent 在真实运行的系统上拥有“手”和“眼”是很有效的做法。你可以使用一个 skill，借助 [CDP](https://chromedevtools.github.io/devtools-protocol/)、模拟器或 API 测试框架等工具来启动、操控和检查应用。

> With E2E tests, it is effective to give your agent hands and eyes on the real running system. You can use a skill to boot, drive, and inspect the app with tools like [CDP](https://chromedevtools.github.io/devtools-protocol/), simulators, or API harnesses.

功能地图可以作为智能体的指南和评分标准，因为它们通常从用户的视角列出各项功能，并附有对路径、键盘快捷键、选择器和预期结果的描述。

> The feature map can serve as a guide and grading rubric for agents as they typically list features from the user’s point of view with descriptions of paths, keyboard shortcuts, selectors, and expected results.

##### 属性测试：不可打破的约束

> Property tests: constraints that can’t break

很多测试都是基于你事先想到的可能出错之处编写的。属性测试关注的则是人们容易忽略的边界情况，而这正是智能体经常出错的地方。

> A lot of tests are based on what you thought might go wrong. Property tests look at the edge cases that people tend to miss, which is where agents often fail.

你先写下一条自认为不可能出错的断言，然后使用测试库（JS/TS 用 [fast-check](https://fast-check.dev/)，Python 用 [Hypothesis](https://hypothesis.readthedocs.io/en/latest/)，Rust 用 [proptest](https://proptest-rs.github.io/proptest/)，等等）生成成千上万个输入，试图证明它并不成立。

> You start by writing a statement you think can’t fail and then use a test library ([fast-check](https://fast-check.dev/) for JS/TS, [Hypothesis](https://hypothesis.readthedocs.io/en/latest/) for Python, [proptest](https://proptest-rs.github.io/proptest/) for Rust, etc.) to generate thousands of inputs that try to prove otherwise.

几乎每个软件项目中都存在许多属性，例如：

> There are many properties in virtually every software project like:

- **往返编码**：“如果你对 X 进行编码，再把它解码回来，得到的仍是 X。”这同样适用于解析和序列化。
- **不变量**：必须始终成立的事情，例如“账户余额永远不能变为负数”。
- **幂等性**：将一个操作（迁移、规范化、重试）执行两次，与执行一次的效果相同。
- **等价性**：优化后的代码与朴素但正确的代码产生相同的结果。

> • **Round-trip encoding**: “if you encode X then decode it back, you get X.” This works for parsing and serialization as well.
> • **Invariants**: Things that must always be true, like “account balance can never become negative.”
> • **Idempotency**: Doing an action (migration, normalization, retry) twice has the same effect as doing it once.
> • **Equivalence**: Optimized code produces the same result as naive but correct code.

属性库是让智能体保持诚实的好办法，因为它所使用的边界用例并不带有与编写原始代码的智能体相同的偏见。当规格说明已经偏离生产环境的实际行为、不再是可靠的验证依据时，它们对重写工作也尤其有帮助。

> Property libraries are a great way to keep agents honest by using edge cases that aren’t created with the same bias as the agent that created the original code. They are also particularly helpful for rewrites when the spec has drifted from production behavior and is no longer a reliable source for verification.

##### 差分测试：以旧系统作为预言机

> Differential tests: the old system is the oracle

差分测试对于[大规模迁移](https://claude.com/resources/articles/ai-code-migration)这类预期功能保持不变的场景尤其有效。在这类测试中，你用相同的输入同时运行旧系统和新系统，看看是否会得到不同的结果。如果结果不同，就说明存在需要修复的 bug 或破坏性变更。

> Differential tests are particularly effective for [large-scale migration](https://claude.com/resources/articles/ai-code-migration) use cases where functionality is expected to remain the same. For these tests, you run both the old system and the new system with the same inputs and see if you get different results. If you do, there is a bug or breaking change that needs to be fixed.

差分测试的关键在于使用随机生成的输入或生产流量的样本。你还需要对空白字符等无关因素进行归一化处理，并维护一份已批准变更的清单，用于新环境理应与旧环境有所不同的情况。

> The key for differential tests is to use randomly generated inputs or a sample of production traffic. You’ll also want to normalize irrelevant factors like whitespace and keep a list of approved changes for situations where the new environment should differ from the old.

#### Claude Code 团队如何看待验证

> HOW THE CLAUDE CODE TEAM THINKS ABOUT VERIFICATION

我们此前曾撰文介绍过 [Anthropic 的代码审查是如何运作的](https://claude.dev/blog/solving-code-review-at-anthropic/)，而本文旨在更深入地探讨我们如何验证自己的工作成果。

> We have previously written about [how code review works at Anthropic](https://claude.dev/blog/solving-code-review-at-anthropic/), but this article aims to go deeper on how we verify our work.

##### 验证意味着实际运行变更

> Verification means running the change

端到端地运行应用比测试更重要。你不会不在模拟器里试一下就发布 iOS 改动，对 Claude 来说也是同样的道理。

> Running the app end to end matters more than tests. You wouldn't ship an iOS change without trying it in a simulator, and the same goes for Claude.

Claude 可以像人类用户或 QA 工程师那样测试整个应用。针对 Web 改动，可以让它使用 Claude Chrome 扩展；针对移动端，使用 iOS 或 Android MCP；针对桌面端，使用 computer use；针对后端工作，则让它在本地运行服务。

> Claude can test the whole app the way a human or QA engineer would. Ask it to use the Claude Chrome extension for web changes, an iOS or Android MCP for mobile, computer use for desktop, or to run the service locally for backend work.

要把启动模拟器或运行应用的方法固化下来，可以创建一个名为 verify 的 skill。把它放在代码仓库的 .claude/skills/ 文件夹中，尽可能靠近相关代码，需要多少个就添加多少个。Claude 知道在提交更改之前要使用 verify skill。

> To codify how to start the simulator or run your app, create a skill called verify. Put it in a .claude/skills/ folder in your repo, as close to the relevant code as you can, and add as many as you need. Claude knows to use the verify skill before committing changes.

然后投入精力，让你的 verify skill 变得快速且可靠。让 Claude 对它反复迭代并进行压力测试。它就是你的冒烟测试工具，所以你要让它坚如磐石。

> Then invest in making your verify skill fast and reliable. Ask Claude to iterate on it and stress test it. It's your smoke test harness, so you want it rock solid.

当你为 Claude 提供一种对其改动进行端到端冒烟测试的方法时，你会得到好得多的结果。你会看到它不断迭代，并更快地发现真正的错误，就像人类会做的那样。在 Anthropic，我们几乎所有的改动都是这样测试的。

> When you give Claude a way to smoke test its changes end to end, you get much better results. You'll see it iterate and catch real mistakes faster, the way a human would. This is how we test nearly all changes at Anthropic.

##### 未通过的测试需要人工关注

> Failing tests require human attention

没有人能读完每一处改动，所以我们把失败当作判断哪些地方需要人工介入的一种方式。Claude 会运行这些检查，并尝试修复所有未通过的项。如果某项检查在三轮之后仍未通过，Claude 就会停下来，请人类介入。

> Nobody can read every change, so we use failures as one way to decide what needs a person. Claude runs the checks and tries to fix anything that fails. If a check is still failing after three rounds, Claude stops and brings in a human.

##### 代码所有者编写自己的检查

> Code owners write their own checks

代码归谁所有，就由谁来为它编写检查，并不断打磨，直到这些检查标记出的问题正是所有者自己会标记的问题。当某项检查拉入一位评审者时，它应当说明原因，这样评审者就不必自己从 diff 中去推断。

> The people who own the code write the checks for it, and refine them until they flag what the owner would flag. When a check pulls in a reviewer, it should say why, so they don't have to work it out from the diff.

##### 可靠性检查基于 diff 触发

> Reliability checks trigger on the diff

我们维护着一份包含 39 个条目的可靠性检查清单，每个条目都有一个可以从 diff 中读出的触发条件、一项检查，以及其背后的事故或 PR。其中一条是“--resume 会加载旧的对话记录”。当会话存储或消息类型发生变化时，我们会问新字段能否安全加载，因为较旧的对话记录里不会有这个字段。

> We maintain a reliability checklist with 39 items, each with a trigger that can be read from a diff, a check, and the incidents or PRs behind it. One is “--resume loads old transcripts.” When session storage or message types change, we ask whether a new field loads safely, since older transcripts won’t have it.

Claude 会阅读 diff，并且只检查触发条件匹配的条目——通常为 3 到 10 项——这样就没有人需要去记住过去发生过的故障。

> Claude reads the diff and checks only the items whose trigger matches–usually 3 to 10–so nobody has to memorize past outages.

##### 一位审稿人，多轮评审

> One reviewer, multiple rounds

我们不会靠堆叠更多评审者来改进评审。在主评审者之上再加一个更昂贵的第二评审者，往往不如调优主评审者。取而代之的是，我们有一份 [REVIEW.md](https://code.claude.com/docs/en/code-review-customize)，其中说明了评审者针对这份代码应该关注什么。

> We don't try to improve reviews by stacking on more reviewers. Adding a second, more expensive, reviewer on top of the primary one is often a worse approach than tuning the primary. Instead, we have a [REVIEW.md](https://code.claude.com/docs/en/code-review-customize) that says what the reviewer should pay attention to for this code.

我们还认为，各轮评审和验证应该层层递进、相互衔接。我们让每一轮都着眼于前几轮的上下文和过去的失败案例，而不是从头重新检查所有内容。这样做成本更低，发现的问题也更多。

> We also think review and verification rounds should build on each other. We point each pass at context from earlier rounds and past failures rather than re-checking everything from scratch. It’s cheaper and finds more.

##### 变更不能修改针对自身的检查

> Changes can't modify their own checks

如果一项变更能够修改用来评判它的检查，那么这项检查就失效了。Code Review 从基础分支或默认分支读取 REVIEW.md 文件，[绝不会从拉取请求的变更中读取](https://code.claude.com/docs/en/code-review-customize)。Claude Code 团队确保把关变更的规则位于该变更无法修改的分支上。

> If a change can modify the check that judges it, the check is broken. Code Review reads the REVIEW.md file from the base or default branch, [never from the pull request's changes](https://code.claude.com/docs/en/code-review-customize). The Claude Code team ensures the rules that gate changes are on a branch that the change can't modify.

Claude Code 团队还把评审限定在具体的提交上。如果评审进行期间有人在推送代码，那么评审结果就不再有用了。在一个过时的提交上通过的评审毫无意义。

> The Claude Code team also reserves reviews for commits. If someone's pushing while the review is happening, then the review result is no longer useful. A passing review on an out-of-date commit means nothing.

团队还会先运行成本低的检查。如果智能体在本地测试之前就推送代码，它就白白耗费了共享的评审和 CI 时间，而这个 bug 它本可以自己发现。在我们团队，Claude 会在发起 pull request 之前运行测试、构建和 linter。你可以通过一个在 Claude 完成工作时运行测试的 [hook](https://code.claude.com/docs/en/hooks) 来强制执行这一点，或者设置一个以测试套件全部通过为目标的 [/goal](https://code.claude.com/docs/en/goal)。

> The team also runs cheap checks first. If an agent pushes before testing locally, it has spent shared review and CI time when it could have caught the bug itself. On our team, Claude runs the tests, build, and linter before opening a pull request. You can enforce this with a [hook](https://code.claude.com/docs/en/hooks) that runs the tests when Claude finishes, or a [/goal](https://code.claude.com/docs/en/goal) of a passing test suite.

##### 以观察模式启动新的门禁

> Start a new gate in observe mode

在我们自己的代码仓库中，我们会给每个提交打上标记，注明它是如何被验证的。这个标记甚至包括“none”，这样我们就能查询出那些未经验证的提交。

> In our own repos, we stamp each commit with how it was verified. The stamp even includes "none" so we can query for commits that weren't verified.

我们还创建了一个提交门禁（commit gate），如果会话中没有包含 /code-review 或 /verify，它可以阻止提交。我们为它设置了 off、observe 和 enforce 三种模式。

> We've also created a commit gate that can block a commit if the session did not contain /code-review or /verify. We've set it up with off, observe, and enforce modes.

观察模式会记录哪些内容本应被拦截，这样我们就可以审查任何误报，并确保没有人受到影响。

> Observe mode will log what would have been blocked, so that we can review any false positives and ensure no one is impacted.

强制（Enforce）模式会阻止提交。任何提交都可以在其提交信息中附带说明，解释它为何未经过验证。如果在当前会话中提交已被阻止两次，那么下一次提交将被放行，以免 Claude 卡住——毕竟 Claude Code 并不完美。

> Enforce mode will block the commit. Any commit can carry an explanation in its message as to why it didn't get verified. If commits have been blocked twice in the session, the next one will be allowed through so Claude doesn't get stuck – Claude Code isn't perfect.

##### 针对真正重要的事项来测试你的检查

> Test your checks on what actually matters

Claude Code 团队还会定期对审查者本身进行审查。我们会跟踪有多少已合并的变更被回滚、有多少变更在合并前被维护者拒绝，以及一组规模相当、至今未出问题的变更子集。

> The Claude Code team also regularly reviews the reviewers. We track how many merged changes were reverted, how many changes a maintainer rejected before merging, and a size-matched subset of changes that have stayed clean.

这也可以通过正式的评估来完成。在我们的[代码审查文章](https://claude.dev/blog/solving-code-review-at-anthropic/)中，我们介绍了 Code Review 团队如何基于以往的事故和回滚建立了一套评估。对于每个样例，他们会把代码仓库还原到审查当时的状态，并提供一句话的参考答案，说明 bug 是什么。只有正确描述了该 bug 的发现才能得分。他们使用已合并且稳定的变更作为对照组，以防止过度标记。他们的调优集是从用于评估系统的固定测试集中单独划分出来的。

> This can also be done with a formal evaluation. In our [code review post](https://claude.dev/blog/solving-code-review-at-anthropic/), we described how the Code Review team has set up an evaluation based on previous incidents and reverts. They recreate the repo to the state at the time of review for each example, and provide a one-sentence answer key to what the bug was. Only findings that correctly describe the bug in question get points. They use merged and stable changes as a control to prevent over-flagging. Their tuning set is split out from the fixed test set they use to evaluate their system.

他们还分别评估了原始发现、验证后和最终评审三个阶段的召回率。这样就能看出系统是否丢掉了它原本已经发现的 bug。任何把这些环节合并成一个端到端分数的评估，都无法捕捉到这种细微差别。

> They also evaluated the recall rate for raw findings, post-verification, and final review separately. This lets them see if the system is losing bugs it had already found. Any evaluation that treats all these as one end-to-end score won't capture this nuance.

除了有效性之外，我们关心的另一个维度是做出这项修改有多重要。一位优秀的审查者会发现大多数技术上正确的问题，但人们在意的是某个 bug 究竟属于必须修复、应该修复，还是无关紧要的小问题。

> In addition to validity, the other dimension we care about is how important it is to make the change. A good reviewer will catch most things that are technically correct, but people care about whether a given bug is a must-fix, a should-fix, or a nit.

Code Review 采用的正是这一思路，它会把问题标记为 [Important、Nit 或 Pre-existing](https://code.claude.com/docs/en/code-review-pull-requests)。“pre-existing”标签的意思是，对于原本就已存在的 bug，审查者不应让作者为此负责。

> Code Review has this exact idea, and it will tag things as [Important, Nit or Pre-existing](https://code.claude.com/docs/en/code-review-pull-requests). The "pre-existing" tag means that the reviewer shouldn't hold the author responsible for something that was already a bug.

最后，Claude Code 团队会不断调高召回率，直到再进一步的提升只是对评测集的过拟合，而非真正发现 bug 为止。

> Finally, the Claude Code team tunes recall up to the point where the next improvement would be overfitting to the eval rather than actually catching bugs.

##### 把失误转化为规则

> Turn misses into rules

在 Claude Code 代码仓库中，我们有两种把漏掉的案例转化为规则的方法。第一种是从人工代码评审意见和 PR 回滚中提取模式，以识别常见问题。这些问题必须至少在两个 PR 中出现，并且能够从 diff 中识别出来，才会被视为潜在规则。三个智能体会尝试证伪它们，随后由人在 PR 中进行审查和批准。

> In the Claude Code repo, we have two methods of turning missed cases into rules. The first is extracting patterns in human code review comments and PR reverts to identify common issues. These must occur in at least two PRs and be identifiable from a diff to be considered a potential rule. Three agents will try to disprove them, and they will be reviewed and approved by a human in a PR.

第二种方法是让三个 bug 查找器针对一个与已知事故相关联的 PR 进行重放。如果至少有两个查找器发现了该 bug，那么它就是一个可检测的 bug。如果在一个很小的 diff 上漏掉了该 bug，这就是一个值得转化为 REVIEW.md 中规则的缺口。

> The second method is replaying three bug finders against a PR that is associated with a known incident. If at least two find the bug, it's a detectable bug. If the bug is missed on a small diff, this is a gap that is worth turning into a rule in REVIEW.md.

不稳定的测试也是同样的处理方式。Claude 不能跳过它们、添加 sleep，或者反复重试直到通过。如果找不到根本原因，它就删除该测试，并写下原因。

> Flaky tests get the same treatment. Claude can't skip them, add sleeps or retry until they pass. If it can't find the root cause, it deletes the test and writes down why.

规则同样需要清理。测试套件、验证步骤和 .md 文件如果放任不管，就只会不断膨胀，所以我们会定期对它们进行整理。

> Rules need cleaning up too. Test suites, verification steps and .md files only grow if you let them, so we tidy them up on a routine.

#### 好的测试，好的结果

> GOOD TESTS, GOOD RESULTS

我们发现，为你的智能体提供一种借助强反馈回路来验证自身工作的方式，会带来截然不同的效果。请像对待其他任何系统一样对待你的验证层。让它们不受其所评判的变更的影响，用那些对你而言真正重要的 bug 来给它们评分，在它们漏掉问题时把教训记录下来，以免同样的情况再次发生，并对这些教训进行精简，使它们始终值得运行。

> We’ve found that giving your agent a way to verify its work with a strong feedback loop makes all the difference. Treat your verification layer like you would any other system. Keep it out of reach of the changes they judge, grade them against the bugs that mattered to you, and write down lessons when they miss something so that it doesn’t happen more than once, and prune those lessons so they stay worth running.

做到这一点，你的工作就会从阅读每一处 diff，转变为定义“完成”是什么样子并审查证据，而这正是让你能够同时运行多个 Claude 的关键。

> Do that and your job shifts from reading every diff to defining what “done” looks like and reviewing the evidence, which is what lets you run many Claudes at once.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| verification loop | 验证循环 | 让智能体用证据检查自身输出并据此迭代改进的反馈机制。 |
| end-to-end test (E2E) | 端到端测试 | 按真实用户流程对整个系统进行完整运行验证的测试。 |
| property-based testing | 属性测试 | 针对应始终成立的断言自动生成大量输入以尝试证伪的测试方法。 |
| differential testing | 差分测试 | 用相同输入同时运行新旧系统并比较输出差异的测试方法。 |
| oracle | 预言机 | 在测试中用作判定结果正确与否的参照依据，例如旧系统的输出。 |
| invariant | 不变量 | 在程序运行过程中必须始终成立的条件。 |
| idempotence | 幂等性 | 同一操作执行多次与执行一次效果相同的性质。 |
| round-trip encoding | 往返编码 | 数据经编码再解码后应与原始数据一致的性质。 |
| flaky test | 不稳定测试 | 在代码未变的情况下结果时而通过时而失败的测试。 |
| smoke test | 冒烟测试 | 快速确认系统基本功能能否正常运行的初步测试。 |
| hook | 钩子 | 在特定事件发生时自动触发执行的脚本或命令。 |
| skill | 技能（skill） | 存放在代码仓库中、供 Claude 按需调用的可复用操作说明与流程。 |
| commit gate | 提交门禁 | 在会话未满足验证条件时阻止提交的检查机制。 |
| recall | 召回率 | 实际存在的问题中被系统成功发现的比例。 |
| diff | 差异（diff） | 一次变更相对于基准版本的代码改动内容。 |
