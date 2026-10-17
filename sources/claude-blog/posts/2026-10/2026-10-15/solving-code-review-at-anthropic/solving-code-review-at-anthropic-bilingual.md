# Claude Code 团队如何进行代码审查

> How the Claude Code team does code review

> 来源：Claude Blog / Anthropic，2026-10-15
> 原文链接：https://claude.dev/blog/solving-code-review-at-anthropic/
> 分类：软件工程 / AI 辅助代码审查

## 核心要点

- 在智能体大量编写代码的背景下，团队将代码审查的核心问题从“是否有人读过代码”转为“这次变更可能出什么问题、哪种检查最适合发现它”。
- 团队的目标是让大多数 PR 合并时最多只有一名人工参与，同时以回滚率和事故率作为护栏指标，确保人工时间是真正节省而非被转移。
- 大部分审查在 PR 创建前完成：Claude 需运行测试、构建或截图比对并展示输出，再由全新上下文的子代理审查 diff，反复出现的问题通过技能、lint 规则或 CLAUDE.md、REVIEW.md 从源头修复。
- 每个 PR 在人工查看前都会经过 Claude 审查，多个智能体并行找 bug 并投票验证，仅保留被充分认同的发现，按 Important、Nit、Pre-existing 标记，且每条发现都必须修复或附理由关闭。
- 安全审查与 lint、类型检查、跨平台测试和构建等自动化检查均具有阻断作用，未处理的发现会阻止合并。
- 人工审批按变更本身的风险分级，由分类器判定，敏感路径和 CI 工作流始终需人工审核，智能体的批准不能替代人的批准，批准只对应特定提交。
- 合并队列、功能开关、内部先行使用、分渠道发布以及值班与事故复盘共同构成快速检测和快速回滚的最后一层防线。
- 团队把历史事故转化为评估集，并依据作者对评审意见的处理方式衡量噪声，同时通过轮次上限、仅审增量 diff、指出缺陷类别和不重复发现来让评审收敛。
- 人类的精力转向判断是否该做、高风险代码、架构模式、解读验证证据以及对结果负责，代码理解则通过让 Claude 按需生成讲解文档和公开频道协作来共享。
- 团队奉行“谁合入谁负责”，并依靠小变更、一切可逆、按影响范围设门槛和非追责式复盘来避免其负面效应，同时给出了其他团队采用该流程的分阶段建议。

## 正文

我们之前说过，Claude Code 自身约 90% 的代码是由 Claude 编写的。那么，在代码产出量如此之大的情况下，我们如何进行代码审查？现在还有人读代码吗？如果出了问题，谁来发现？

> We've said before that Claude writes about 90 percent of Claude Code's own code. So how do we review code at the volume we produce it? Does anyone read code anymore? And if something breaks, who catches it?

本文介绍 Claude Code 团队的代码审查流程及其演变历程。从 6 月到 9 月，合并到 Claude Code 代码库的拉取请求数量增长了一倍多，而需要回滚的比例下降了 40% 以上。

> This post covers the code review flow on the Claude Code team and how it has evolved. From June to September, merged pull requests to Claude Code's codebase more than doubled while the share that had to be reverted fell by more than 40 percent.

我们并没有取消评审。但我们确实把大部分阅读工作交给了机器，以节省人的时间和注意力为目标进行优化，并投入大量精力，让撤销错误变得快速而简单。

> We didn't remove review. But we did move most of the reading to machines, optimized for human time and attention, and invested heavily in making it fast and easy to undo mistakes.

#### 重新思考代码评审的目的

> RETHINKING THE PURPOSE OF CODE REVIEW

当智能体编写代码时，代码变更的数量会迅速增长。在 Anthropic 的 monorepo 中，每天合入的变更数从今年 [5 月的约 2,500 个增长到 9 月的超过 30,000 个](https://www.anthropic.com/engineering/redesigning-source-control)。

> When agents write code, the number of changes goes up, fast. In Anthropic's monorepo, changes landing per day went from about [2,500 in May to more than 30,000 in September](https://www.anthropic.com/engineering/redesigning-source-control) this year.

Claude Code 位于独立的代码仓库中，与 monorepo 分开，但它同样承受着很大的压力。在以如此快的速度交付时，人工逐行审查代码即便并非完全不可能，也是极其困难的。

> Claude Code lives in its own repository, separate from the monorepo, but it's seeing a lot of pressure too. When you are shipping this fast, manual, line-by-line code review is incredibly difficult if not impossible.

代码审查承担两项职责：

> Code review does two jobs:

1. 在问题上线之前发现并修复它们
2. 在团队中建立共享上下文与对代码库的共同理解

> 1\. Find and fix issues before they ship
> 2\. Build shared context and codebase understanding across the team

本文主要聚焦于发现和修复问题，但我们会在接近结尾时再回到第二项工作。

> This article mainly focuses on finding and fixing issues, but we will come back to the second job near the end.

我们认为，“有人读过这段代码吗？”只是一个不够精确的替代指标，它真正想问的是：“这次变更可能会出什么问题？哪种检查（自动化的还是人工的）才最适合发现它？”

> We think "did a human read the code?" is an imprecise proxy for "what could go wrong with this change, and which check—automated or human—is the right one to catch it?"

提出这个问题，也改变了评审发生的*时机*。过去，评审是路的尽头的一道关卡：写完代码，提交 PR，然后等同事来审。

> Asking that question also changed *when* review happens. Before, review was a gate at the end of the road: write the code, open a PR, wait for your colleague.

如今，审查是持续进行的，更像是写作时的拼写检查。大多数变更在请人类查看之前，至少已经由 Claude 审查并修复过一次。这能发现大多数常规错误，并把团队的注意力留给更高层次的问题和审视。

> Now, review runs continuously, more like spellcheck while you write. Most changes have been reviewed and fixed by Claude at least once before a human is asked to look. This catches most routine mistakes, and saves team attention for higher-level questions and scrutiny.

#### 稀缺资源：人的时间与注意力

> THE SCARCE RESOURCE: HUMAN TIME AND ATTENTION

我们希望把人的时间和注意力留给只有人才能解决的问题，并确保其余问题都由自动化检查发现。按照我们目前的变化速度，仍有大量工作需要人来完成，我们的团队几乎每天都会遇到前所未有的新挑战。

> We want to preserve human time and attention for issues only humans can solve and make sure automated checks catch the rest. At our current rate of change, there is still an incredible amount of work for humans to do, and our team encounters new and novel challenges almost daily.

人力时间涵盖了审查成本的两个方面：人们花在审查上的时间，以及他们花在修复劣质代码所造成问题上的时间。如果减少的前一部分时间只是转移到了后一部分，那么削减前者就毫无帮助。

> Human time covers both sides of review's cost: the time people spend reviewing, and the time they spend fixing what bad code breaks. Cutting the first doesn't help if the time just shows up in the second.

因此，我们的目标是：Claude Code 各代码仓库（CLI、桌面端与 Web 应用，以及移动应用）中的大多数拉取请求在合并时，流程中最多只有一名人工参与（可以是作者本人），且回滚和事故不增加。为衡量人工投入的时间，我们追踪每个 PR 的人工批准次数（中位数和第 95 百分位数）、人工评论数，以及 PR 等待人工处理的时长。回滚率和事故率是护栏指标：如果它们上升，说明我们并没有节省人工时间，只是把它转移了。

> So the goal is that most pull requests in the Claude Code repos (the CLI, the desktop and web apps, and the mobile apps) merge with at most one human in the loop, who can be the author, with no increase in reverts or incidents. To measure human time, we track human approvals per PR (median and 95th percentile), human comments, and how long a PR waits on a person. Revert and incident rates are the guardrail: if they rise, we haven't saved human time, we've only moved it.

#### 一次变更的生命周期

> THE LIFE OF A CHANGE

一次典型的变更，从工程师的笔记本电脑（或 Slack 中的 Claude 会话）发起，会经过多层代码审查。

> A typical change, from an engineer's laptop (or a Claude session in Slack), goes through multiple layers of code review.

#### 逐层

> LAYER BY LAYER

##### 1. 在任何人查看之前，工作就已经过验证

> 1. The work is verified before anyone else looks

现在，大部分审查工作在 PR 创建之前就已完成。我们会给 Claude 一些它可以运行的东西——比如测试、构建，或者一张用来与设计稿比对的截图——并要求它展示输出结果，而不是只说已经完成。然后，由一个子代理在全新的上下文中审查 diff。这两个习惯都来自我们的[最佳实践指南](https://code.claude.com/docs/en/best-practices)。

> Most review now happens before a PR exists. We give Claude something it can run—like tests, a build or a screenshot to compare against the design—and ask it to show the output instead of saying it's done. Then a subagent reviews the diff with fresh context. Both habits come from our [best-practices guide](https://code.claude.com/docs/en/best-practices).

在提交 PR 之前，我们中的许多人还会运行几个内部技能：一个用于查找 bug，一个用于精简 diff，还有一个用于端到端地检查行为。UI 改动还会对照我们的设计规范进行检查。

> Before opening a PR, many of us also run a few internal skills: one hunts for bugs, one simplifies the diff, and one checks the behavior end to end. UI changes also get checked against our design guidelines.

Claude Code 的创建者 Boris Cherny 曾表示，为 Claude 提供一种验证自身工作的方法，[可能是最重要的一点](https://x.com/bcherny/status/2007179861115511237)，是获得良好结果的关键。他估计，这能让最终结果提升两到三倍，并写道：“不同领域的验证方式各不相同。它可能简单到只需运行一条 bash 命令，或者运行一套测试，又或者在浏览器或手机模拟器中测试应用。”

> Boris Cherny, who created Claude Code, has called giving Claude a way to verify its work [probably the most important thing](https://x.com/bcherny/status/2007179861115511237) for getting good results. He estimates it makes the final result two to three times better, and writes, "Verification looks different for each domain. It might be as simple as running a bash command, or running a test suite, or testing the app in a browser or phone simulator."

**当自动审查工具反复标记同一个问题时，我们会从源头上修复它：**在技能中修复、通过 lint 规则修复，或者更新指导性文件，例如：

> **When the automated reviewer keeps flagging the same thing, we fix it at the source:** in the skill, with a lint rule, or with updates to instructional files such as:

- `CLAUDE.md` 告诉 Claude 这个项目是什么：技术栈、约定、目标以及非目标。每次审查都会加载它，因此在大型代码库中，我们会让它保持简短，并在其中指向其他文档。审查者还会标记出违反其中约定的代码，以及导致其中某一行内容过时的变更。
- `REVIEW.md` 由代码所有者编写，告诉审查者在他们负责的那部分代码中什么才是重要的。我们会另外检查审查者是否真正遵循了它。好的写法都很简短。它们会说明在该仓库中失败是什么样子（对文档而言是“内容失实”，对配置而言是“路由错误”），限制细枝末节意见的数量，列出应跳过的路径，并要求以文件和行号作为证据，而不是凭名称去猜测。它们还要求总结以一个计数开头，并在没有需要修复的内容时明确说明。

> • `CLAUDE.md` tells Claude what the project is: the stack, the conventions, the goals and the non-goals. Every review loads it, so in a large codebase we keep it short and point to other docs from there. The reviewer also flags code that breaks a convention in it, and changes that make a line in it out of date.
> • `REVIEW.md`, written by code owners, tells the reviewer what matters in their part of the code. We check separately whether the reviewer actually follows it. The good ones are short. They say what failure looks like in that repo (for docs it's "it lies," for config it's "it misroutes"), cap the nits, list paths to skip, and ask for a file and line as evidence instead of a guess from a name. They also ask for a summary that starts with a count and says plainly when there's nothing to fix.

##### 2. 对每个拉取请求进行 AI 审查

> 2. AI review on every pull request

每个拉取请求在有人查看之前，都会先经过 Claude 的审查。它会对照整个代码库和该 PR 所陈述的意图来阅读 diff，并追问：这项改动是否解决了它要解决的问题、是否契合整个系统，还是会破坏其他东西？

> Every pull request gets a Claude review before a person looks. It reads the diff against the whole repo and the PR's stated intent, and asks: does the change solve its problem, fit the system, or break something else?

在修复 bug 时，它会追查根本原因。其公开版本 [Code Review for Claude Code](https://code.claude.com/docs/en/code-review) 现已在 Team 和 Enterprise 套餐中正式推出，而 `/code-review` 则在本地运行一个更轻量的版本。

> On a bug fix, it looks for the root cause. The public version, [Code Review for Claude Code](https://code.claude.com/docs/en/code-review), is now generally available on Team and Enterprise plans, and `/code-review` runs a lighter version locally.

在我们[推出研究预览版](https://claude.com/resources/articles/code-review)时，获得实质性审查评论的内部 PR 比例从 16% 上升到了 54%。大多数超过 1,000 行的 PR 都会发现问题，而大多数小型 PR 审查后都没有问题。管理员可将每个仓库设置为 Quick、Standard 或 Deep 模式。当漏掉一个 bug 的代价高于额外的审查时间时，Deep 模式就是值得的。

> When we [launched the research preview](https://claude.com/resources/articles/code-review), the share of internal PRs getting substantive review comments went from 16% to 54%. Most PRs over 1,000 lines get findings, and most small ones come back clean. Admins set each repo to Quick, Standard, or Deep. Deep is worth it where one missed bug costs more than the extra review time.

**发现的问题在交由人工审查之前，会先经过其他智能体的验证。**多个智能体同时查找 bug。随后，另一组智能体对每条发现进行投票，只有足够多的智能体认同其确实存在时，才会被发布。仅涉及代码风格、诊断信息或清理工作的发现会被丢弃。在保留这些过滤规则之前，我们先在自己的 PR 上对它们进行了 A/B 测试。剩下的发现会以行内评论的形式呈现，并按严重程度排序。每条评论都会被标记为 Important、Nit 或 Pre-existing，这样一来，并非由该 PR 引入的 bug 就不会看起来像是作者的过错。

> **Findings get verified by other agents before humans review them.** Several agents look for bugs at the same time. Then a separate group votes on each finding, and it only gets posted if enough of them agree it's real. Findings that are only about style, diagnostics, or cleanup get dropped. We A/B tested those filters on our own PRs before keeping them. What's left shows up as inline comments sorted by severity. Each is tagged Important, Nit, or Pre-existing, so a bug the PR didn't introduce doesn't look like the author's fault.

**每一条发现都必须得到回应。**你要么修复它，要么附上理由将该讨论串标记为已解决。通常会有智能体在夜间接手修复，因此作者回来时，看到的 PR 已经又经过了一轮处理。

> **Every finding has to be answered.** You either fix it or resolve the thread with a reason. Often an agent picks up the fix overnight, so the author comes back to a PR that's already been through another round.

##### 3. 可阻断流程的安全审查

> 3. Security review that can block

安全方面同样有专门的自动化审查。只要 bug 审查或安全审查中还有任何发现未被处理，PR 就无法合并。你要么修复问题，要么附上简短理由关闭该讨论串，误报就是通过这种方式消除的。

> Security gets its own automated review too. A PR can't merge while any finding from the bug review or the security review is still open. You either fix it or close the thread with a short reason, which is how you clear a false positive.

如果后续提交修复了该问题，这条发现会自动清除。你也可以通过开源的安全审查 GitHub Action 或 `/security-review` 命令实现同样的设置。具体配置方法请参阅 [Claude Code 中的自动化安全审查](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code)。

> If a later commit fixes the issue, the finding clears on its own. You can set up the same thing with the open-source security review GitHub Action or the `/security-review` command. Setup is covered in [automated security reviews in Claude Code](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code).

##### 4. 具有阻断作用的自动化检查

> 4. Automated checks that block

都是常规流程：lint、类型检查、在每个平台上运行测试，以及构建。（我们曾在[这里](https://claude.com/resources/articles/agentic-coding-is-straining-ci-heres-how-we-scaled-test-impact-analysis-at-anthropic)介绍过如何为这样的规模扩展 CI。）一个典型的 CLI 拉取请求在有人查看之前，可能要先跑几十项检查。PR 模板会询问这项改动是如何测试的，以及如何撤销。Claude 可以填写这些内容，但最终由提出这项改动的人签字确认。

> The usual: lint, type checks, tests on every platform, and a build. (We wrote about scaling CI for this volume [here](https://claude.com/resources/articles/agentic-coding-is-straining-ci-heres-how-we-scaled-test-impact-analysis-at-anthropic).) A typical CLI pull request may run dozens of checks before anyone looks at it. The PR template asks how the change was tested and how to undo it. Claude can fill that in, but the person who asked for the change signs off on it.

##### 5. 按风险分级的人工审批

> 5. Human approval, scaled by risk

文档修复和自动更新程序的改动风险不同，因此需要不同程度的审查。

> A docs fix and an auto-updater change carry different risk, so they get different review.

| 风险 | 示例 | 人工审批 |
| --- | --- | --- |
| 低 | 文档、文案、仅限内部使用的功能、置于功能开关之后的增量变更 | 自动化审查和安全检查全部通过后，无需额外操作 |
| 中等 | 普通的产品变更，以及对缓存、自动更新程序或系统提示词等敏感领域的变更 | 一个人 |
| 高 | 风险最高的代码，外加一小部分始终需要两人把关的路径 | 两个人 |

> 英文原表 / English original

| Risk | Examples | Human approvals |
| --- | --- | --- |
| Low | Docs, copy, internal-only features, additive changes behind a flag | None required once automated review and security checks are green |
| Medium | Ordinary product changes, and changes to sensitive areas such as caching, the auto-updater, or system prompts | One person |
| High | The highest-risk code, plus a small set of paths that always need two people | Two people |

**决定风险等级的是变更本身，而不是作者。**一个分类器读取变更并为其确定风险等级。第二个分类器则判断：即便按等级来看不需要，这项具体变更是否仍需要另一个人审核。某些路径始终需要人工审核，包括所有者列为敏感的任何内容，以及任何 CI 工作流文件。

> **The change sets the tier, not the author.** A classifier reads the change and picks its risk tier. A second classifier asks whether this particular change needs another person even when its tier says it doesn't. Some paths always need a person, anything owners have listed as sensitive and any CI workflow file.

**只有受信任的作者才能走更轻量的流程。**只有列在仓库受信任名单上的作者才能走更轻量的流程，这些作者大多来自负责该仓库的团队。其他所有人都需要第二个人批准。此外，智能体的批准也绝不能算作人的批准。自动化审查可以放行低风险的变更，但无法填补需要由人来担任的审批席位。

> **Only trusted authors get the lighter paths.** Only authors on the repo's trusted list get the lighter paths, mostly the team that owns it. Everyone else needs a second person to approve. An agent's approval never counts as a person's, either. Automated review can clear a low-risk change, but it can't fill a slot that calls for a human.

**谁发起了这项变更，谁就要为它负责。**对于由智能体编写的 PR，指挥该智能体的人算作必需审阅者之一，就如同代码是他们亲手敲出来的一样。

> **Whoever prompted the change is on the hook for it.** On an agent-written PR, the person directing the agent counts as one of the required reviewers, the same as if they'd typed the code themselves.

**一次批准只对应一个特定的提交。**如果出现了系统无法担保的新提交，比如智能体推送的提交，或是有人手动解决冲突后完成的合并，就必须重新给出批准。

> **An approval covers one specific commit.** If new commits land that the system can't vouch for, like an agent's push or a merge someone resolved by hand, the approval has to be given again.

##### 6. 合并队列、功能开关与渐进式发布

> 6. Merge queue, flags and a gradual release

合并队列会在应用变更后的 main 上重新运行所有检查，因此两个各自通过检查的 PR 不会在合并后让 main 出问题。新行为通常会先通过功能开关向 Anthropic 员工发布，而我们的高强度使用往往能赶在用户之前发现回归问题。公开版本会先发布到 `latest` 渠道，`stable` 渠道随后跟进。

> The merge queue re-runs every check against main with the change applied, so two PRs that pass separately can't combine into a broken main. New behavior usually ships behind a flag to Anthropic employees first, and our heavy use often surfaces regressions before users do. Public releases go to the `latest` channel first. The `stable` channel trails it.

##### 7. 快速检测，快速回滚

> 7. Fast detection, fast rollback

总会有一些错误漏网，所以最后一层的目标是快速发现它们。功能开关无需部署即可关闭。Claude Code 实行每周轮换的值班制度，事故复盘时会追问：本应由哪一层拦截这个问题。

> Some mistakes will still get through, so the last layer is about catching them fast. Flags turn off without a deploy. Claude Code has a weekly on-call rotation, and incident reviews ask which layer should have caught the issue.

发现一次有问题的合并，目前仍要依靠作者和值班人员，以及回滚和事故仪表盘。我们还没有熔断机制，能在这些指标出现波动时收紧审批；这里的工程师希望在更多代码转向零人工合并之前先把它建立起来。

> Noticing a bad merge still depends on the author and on-call as well as the revert and incident dashboards. We don't yet have circuit breakers that tighten approval when those numbers move; engineers here want them before more code moves to zero-human merges.

一位同事说，放慢速度确实会降低错误率，但这主要是因为你做的每件事都变少了。我们更希望在发现和修复问题上变得更快。

> One colleague said slowing down does lower your error rate, but mostly because you're doing less of everything. We'd rather get faster at noticing and fixing problems.

#### 我们如何让评审模型变得更好

> HOW WE MAKE THE REVIEWER BETTER

我们的代码审查流程在循环中不断改进。

> Our code review process is constantly improving in a loop.

**任何事故如今都成了一项评估。**团队收集了过去引发事故的 PR，连同其前向修复和回滚记录，并请熟悉相关代码的工程师逐一确认每个 bug 及其所在位置。审查器每天都会针对这一数据集运行。

> **Any incidents are now an eval.** The team collected past PRs that caused incidents, with their fix-forwards and reverts, and had engineers who know that code confirm each bug and where it lived. The reviewer runs against that set daily.

**我们通过观察人们如何处理评审意见来衡量噪声。**如果不介意标记大量并非 bug 的问题，要捕获更多 bug 很容易，所以我们需要对此加以制衡。我们根据 PR 作者的回应，对评审器留下的每条意见进行分类：他们修复了问题、认为意见有误、表示该行为是有意为之，或者认为无关紧要。我们还会在已知没有问题的 PR 上运行评审器，统计它有多少次报告了可能导致有人做出有害修改的内容。我们明确写下的优先级是：首先捕获真实的 bug，其次减少评审轮次。

> **We measure noise by watching what people do with the comments.** It's easy to catch more bugs if you don't mind flagging a lot of non-bugs, so we need a check on that. We sort every comment the reviewer leaves by how the person on the PR responded: they fixed it, said it was wrong, said the behavior was intentional, or decided it didn't matter. We also run the reviewer on PRs we know are clean and count how often it reports something that would have led someone to make a harmful change. Our priority, written down, is catching real bugs first and cutting review rounds second.

当作者是智能体时，噪音的代价更高。人可以在几秒内把一个无关紧要的小意见置之不理；而智能体会去修复它，这意味着又一次提交和又一轮评审。

> Noise costs more when the author is an agent. A person can wave off a nit in seconds. An agent fixes it, which means another commit and another round of review.

**评审必须能够收敛。**作为作者的智能体和作为评审者的智能体可以无休止地让彼此忙个不停。曾有一个 CLI PR 在一夜之间经历了五十多轮评审与修复，直到其作者出手叫停。

> **Review has to converge.** An agent author and an agent reviewer can keep each other busy indefinitely. One CLI PR went through more than fifty rounds of review and fixes overnight before its author stopped it.

当我们对审查器反复标记的问题运行 git blame 时，发现其中约 59% 的代码在审查器第一轮审查时就已经存在。审查器很少发现新的 bug，它只是每一轮都多找出几个旧 bug 而已。

> When we ran git blame on what the reviewer kept flagging, about 59% of it was code that had been there since the reviewer's first pass. The reviewer was rarely finding new bugs, it was finding a few more old ones each round.

这个问题有一部分是我们自己造成的。我们已经习惯了默认跑好几轮，因为每一轮都能发现一些新问题。对于高风险的改动，这样做可能是值得的，但并非每个 PR 都需要如此。团队现在会在跟踪召回率的同时跟踪通过所需轮数，并调整了重新评审的方式：

> We made it worse ourselves. We'd gotten used to running several rounds by default, since each pass catches something new. This can be worthwhile on a risky change, but not on every PR. The team now tracks rounds-to-pass alongside recall, and changed re-review:

- **轮次上限。**经过三轮之后，审阅者会要求作者退一步，重新考虑所采用的方法。
- 在最初几轮审查之后，**仅针对差异进行复审**。
- **指出这一类缺陷，**让作者修复所有同类问题，而不只是改一行。
- **不要重复**已经发布过的发现。

> • **A round cap.** After three rounds, the reviewer asks the author to step back and reconsider the approach.
> • **Diff-only re-review** after the first few passes.
> • **Flag the class of bug,** so the author fixes every instance, not one line.
> • **No repeats** of findings already posted.

审查智能体还会每晚对现有代码进行检查，帮助我们在旧缺陷于其他地方暴露之前就将其发现。

> Review agents also run nightly over existing code, helping us catch old bugs before they show up somewhere else.

#### 人类始终参与其中的环节

> WHERE HUMANS STAY IN THE LOOP

为了发现一个常规错误而把资深工程师从深度工作中拉出来，其代价远高于一次自动化审查。在 Anthropic，我们的工作已经从阅读每一个 diff，转向了机器不擅长的决策：

> Pulling a senior engineer out of deep work to catch a routine mistake costs far more than an automated review. At Anthropic, our jobs have moved from reading every diff to the decisions machines are bad at:

- **我们到底该不该做这个？**方向、品味与范围。有一个团队宣称已经解决了评审瓶颈，但对于来自团队外部的变更，他们仍然保留了人工评审，以便有人来问一句“我们真的应该做这个吗？”
- **高风险代码**，例如计费、自动更新程序和 CI 工作流。
- **架构**，确立一种他人会效仿的模式。
- **解读证据。**测试输出、实际运行的命令及其返回结果、截图、审查者的发现。如果你说不出这些检查会遗漏什么，就应请求一次真正的审查，而不是快速批准了事。
- **对结果负责。**每一项上线的变更都必须有人为之负责，无论代码是谁敲出来的。

> • **Should we build this at all?** Direction, taste and scope. One team that declared its review bottleneck solved still kept human review for changes from outside the team, so someone asks "should we even do this?"
> • **Risky code** such as billing, the auto-updater and CI workflows.
> • **Architecture** that sets a pattern others will copy.
> • **Reading the evidence.** Test output, the command that ran and what it returned, a screenshot, the reviewer's findings. If you can't say what the checks would miss, ask for a real review rather than a quick approval.
> • **Owning the outcome.** A person is accountable for every change that ships, whoever typed it.

#### 在整个团队中共享上下文

> SHARING CONTEXT ACROSS THE TEAM

代码审查一直以来还肩负着第二项职责：传播对代码库的理解。阅读队友的 diff，正是你了解改动内容以及各部分如何协同运作的方式。如果大部分阅读工作都由机器完成，那么人们又该如何了解代码呢？

> Code review's second job has always been to spread codebase understanding. Reading a teammate's diff is how you learn what changed and how the pieces fit. If machines do most of the reading, how does anyone learn the code?

我们对此并没有正式的流程。团队里没有人在脑中保有一个完整的 Claude Code 心智模型，我们也认为没有人需要这样做。当有人想了解代码库的某个部分时，他们会让 Claude 专门针对那一部分写一份讲解文档。这只需要几分钟，而且反映的是代码当前的实际状态。

> We don't have a formal process for this. Nobody on the team keeps a complete mental model of Claude Code in their head, and we don't think anyone needs to. When someone wants to understand a part of the codebase, they ask Claude to write an explainer for exactly that slice. It takes minutes and reflects the code as it is today.

![Diagram titled "If machines do most of the reading, how does anyone learn the code?" On the left, a grid stands for the codebase, with a few squares highlighted as managed settings, the part you want to understand; nobody keeps a complete mental model of it in their head. An arrow labeled "Ask Claude about exactly that slice", with the example question "How does Claude Code retrieve managed settings?", leads to two outcomes: Claude writes an explainer, which takes minutes and reflects the code as it is today; and, for some, Claude builds a small artifact that visualizes that part of the code and teaches it the way that person likes to learn. Along the bottom: reading trivial diffs line by line, a one-line copy change teaches you almost nothing; an explainer for the module you are about to change teaches you a lot.](https://claude.dev/media/d4fafcbf3d2137bc64eb7f0707ba91809ff1ed4d098785e36d7422b3b07f6c40.png)

我们中的一些人会更进一步，让 Claude 构建一个小型 artifact，将那部分代码可视化，并以那个人喜欢的学习方式来讲解它。

> Some of us go a step further and have Claude build a small artifact that visualizes that part of the code and teaches it the way that person likes to learn.

如果目标是把人的注意力用在刀刃上，这种做法胜过逐行阅读琐碎的 diff。一行文案改动几乎教不了你什么，而一份针对你即将修改的模块的讲解文档却能让你学到很多。我们默认在公开 Slack 频道中工作的文化也有帮助，因为你能在别人构建东西的同时看到他们在做什么。

> If the goal is to spend human attention well, this beats reading trivial diffs line by line. A one-line copy change teaches you almost nothing. An explainer for the module you're about to change teaches you a lot. Our culture of defaulting to working on open Slack channels helps too, since you see what others are building while they build it.

#### "谁合入，谁负责"

> "YOU LAND IT, YOU OWN IT"

如果你合入了一个小型或中型的改动，之后仍然出了问题，按照团队惯例，通常由你来修复。有几点可以防止这种做法带来不良后果：

> If you land a small or medium change and something still goes wrong, it's a team norm that you usually fix it. A few things keep this from going badly:

- **变更很小，**因此易于审查、调试和回滚。
- **一切皆可逆。**借助功能开关、回滚和分阶段发布，大多数错误都能在几分钟内撤销。
- **影响范围决定门槛。**代价高昂的代码需要更多人参与、更多检查。
- 通过遥测和内部使用，**回归问题会迅速暴露**。
- **这不是追责。**由你负责修复，是因为你掌握的背景信息最多；事故复盘关注的是系统本身。

> • **Changes are small,** so they're easy to review, debug and revert.
> • **Everything is reversible.** Flags, reverts and staged releases undo most mistakes in minutes.
> • **Blast radius sets the bar.** Expensive code gets more people and more checks.
> • **Regressions surface fast** through telemetry and internal use.
> • **It isn't blame.** Owning a fix means you have the most context; incident reviews look at the system.

所有权也是共享的。团队中的许多人在[公开频道](https://claude.com/product/tag)中工作，任何人都能看到其他人正在构建什么，可以接手某个话题，或者让一个 Claude 去填补某个空缺；反馈也会来自并不负责这部分代码的人。这种开放性在很大程度上解释了为什么无需对每一行代码设卡把关，质量依然能保持在高水平。

> Ownership is also shared. Much of the team works in [open channels](https://claude.com/product/tag) where anyone can see what others are building, pick up a thread, or point a Claude at a gap, and feedback comes from people who don't own the code too. That openness is a big part of how quality stays high without a gate on every line.

#### 当我们改变方向时

> WHEN WE CHANGE DIRECTION

智能体让启动一项工作变得成本很低，因此有些工作本不该合入。通常，频道里会有人询问原因、指出之前的某项决定，或者建议一条更简单的路径，然后作者便会关闭或调整这个 PR。

> Agents make it cheap to start things, so some work shouldn't land. Usually someone in the channel asks why, points at an earlier decision, or suggests a simpler route, and the author closes or reshapes the PR.

由于代码写起来很快，关闭 PR 并不会让人觉得是一种损失。诀窍在于尽早在讨论串中提出不同的方向，而不是等 PR 完成后再以阻塞性评论的方式提出。

> Since the code was fast to write, closing the PR doesn't feel like a loss. The trick is to raise a different direction in the thread early, not as a blocking comment on a finished PR.

#### 如何采用这一流程

> HOW YOU CAN ADOPT THIS PROCESS

如今，与团队一起实现这一点所需的大部分要素都已经具备。

> Most of the pieces to do this with your team exist today.

##### 提交拉取请求之前

> Before the pull request

- 为你的智能体提供它可以运行的检查项，并列在一个简短的 `CLAUDE.md` 中，同时配置运行格式化工具和代码检查工具（linter）的钩子。
- 在本地运行 `/code-review` 和 `/security-review`，或使用全新上下文的子代理进行审查。
- 添加一个 `REVIEW.md`，并将反复出现的评审意见移入其中。

> • Give your agent checks it can run, listed in a short `CLAUDE.md`, plus hooks that run formatters and linters.
> • Run `/code-review` and `/security-review` locally, or a fresh-context subagent review.
> • Add a `REVIEW.md`, and move repeated review comments into it.

##### 每次拉取请求时

> On every pull request

- 强制要求 CI，并在 PR 模板中加入“测试”“风险”和“如何回滚”这几项。
- 先在一个仓库上引入 AI 审查工具（Code Review for Claude Code 或 Claude Code GitHub Action），用几周时间调整 `REVIEW.md`，然后再逐步推广。
- 添加自动化安全审查，并要求在合并前解决所有审查讨论。
- 让审查投入与风险相匹配：常规改动快速过一遍，漏掉一个 bug 代价高昂的地方则深入审查（即 Code Review 中的 Quick、Standard 或 Deep 级别）。
- 限制评审轮数；前几轮之后，只重新评审新增的 diff。

> • Require CI, and add "Testing", "Risk" and "How to revert" to your PR template.
> • Add an AI reviewer (Code Review for Claude Code, or the Claude Code GitHub Action) on one repo, tune `REVIEW.md` for a few weeks, then widen.
> • Add automated security review, and require every review thread resolved before merge.
> • Match review effort to risk: a quick pass on routine changes, a deep one where a missed bug is expensive (Quick, Standard or Deep in Code Review).
> • Cap review rounds; after the first few, re-review only the new diff.

##### 审批

> Approval

- 把风险等级明确写下来，依据变更本身而非作者来确定；起初从严，再根据证据逐步放宽。
- 对于你信任的作者，保留较轻量的审批路径。
- 使用 CODEOWNERS 和分支保护，确保认证、计费、CI 与发布工作流以及安装程序始终需要有人把关。
- 切勿让机器人的批准取代必需的人工批准；有新提交时应撤销已有的批准。

> • Write down risk tiers, set from the change rather than the author; start strict and loosen with evidence.
> • Keep the lighter approval paths for authors you trust.
> • Use CODEOWNERS and branch protection so auth, billing, CI and release workflows, and installers always need a person.
> • Never let a bot's approval replace a required human's; dismiss approvals on new commits.

##### 合并及之后

> Merge and after

- 使用合并队列、功能开关，先在内部使用，再分阶段发布，并支持一步回滚。
- 将事故和回滚转化为评估集，并在评审器的提示词、工具或模型发生变化时重新为其评分。
- 衡量人力耗时，并以回滚率和事故率作为护栏指标。

> • Use a merge queue, feature flags, internal use first, staged releases and one-step rollback.
> • Turn incidents and reverts into an eval set, and rescore the reviewer whenever its prompts, tools or model change.
> • Measure human time, with revert and incident rates as the guardrail.

#### 未来走向

> WHERE THIS IS GOING

Code Review 的[发布公告](https://claude.com/resources/articles/code-review)指出，批准拉取请求仍需由人来决定；该产品只发布审查发现，而不做批准。我们自己的代码仓库走得更远，允许所有者决定哪些低风险变更仅凭自动化检查即可合并，而这条界线还在不断变化。

> Code Review's [announcement](https://claude.com/resources/articles/code-review) said approving a pull request is still a human call; the product posts findings, not approvals. Our own repos go further, letting owners decide which low-risk changes merge on automated checks alone, and that line keeps moving.

当某次评审遗漏了问题时，我们会追问模型当时缺少了哪些信息，然后把修复措施落实到 `CLAUDE.md`、某个 skill 或一项新的检查中。目标始终没变：每次变更占用更少的人力时间，同时回滚次数不比以前多。

> When a review misses something, we ask what the model didn't have in front of it and put the fix into a `CLAUDE.md`, a skill or a new check. The goal hasn't changed: less human time per change, and no more reverts than before.

如果你的团队允许智能体发起拉取请求，我们很想了解你们已经将哪些检查自动化、哪些检查仍需人工完成，以及你认为我们哪里有误。

> If your team lets agents open pull requests, we'd like to hear which checks you've automated, which still need a person, and what you think we have wrong.

*感谢 Emma Webb、Michael Segner 和 Amie Rotherham 的审阅。*

> *With thanks to Emma Webb, Michael Segner and Amie Rotherham for their reviews.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Code Review | 代码审查 | 在合并前检查代码变更以发现问题并共享上下文的过程。 |
| Pull Request (PR) | 拉取请求 | 请求将分支上的代码变更合并到主分支的协作机制。 |
| Monorepo | 单体仓库 | 将多个项目或服务的代码存放在同一个版本库中的组织方式。 |
| Subagent | 子代理 | 由主智能体派生、在独立上下文中执行特定任务的智能体。 |
| Diff | 差异 | 代码变更前后内容的逐行对比。 |
| Lint | 代码静态检查 | 通过规则自动检测代码风格与潜在错误的分析过程。 |
| Revert | 回滚 | 撤销已合并的某次变更以恢复先前状态。 |
| Guardrail Metric | 护栏指标 | 用于确保优化主要目标时不损害其他关键质量的约束性指标。 |
| Merge Queue | 合并队列 | 在合并前基于最新主分支依次重新运行检查以避免冲突性破坏的机制。 |
| Feature Flag | 功能开关 | 无需重新部署即可在运行时开启或关闭某项功能的配置机制。 |
| Staged Rollout | 分阶段发布 | 先向小范围用户发布再逐步扩大覆盖面的发布策略。 |
| CODEOWNERS | 代码所有者文件 | 指定仓库各路径负责人并据此要求其审批的配置文件。 |
| Branch Protection | 分支保护 | 对特定分支设置合并前必须满足的审批与检查规则。 |
| False Positive | 误报 | 被检查工具标记为问题但实际上并非问题的发现。 |
| Recall | 召回率 | 实际存在的问题中被成功检出的比例。 |
