# 用 Claude 自动化评测设计与爬山式优化

> Automating eval design and hillclimbing with Claude

> 来源：Claude Blog / Anthropic，2026-09-28
> 原文链接：https://claude.dev/blog/automating-eval-design-and-hillclimbing/
> 分类：AI 工程 / 评测与优化

## 核心要点

- 良好的评测应反映生产任务分布，使更强模型和更多思考带来更高分数，为前沿模型保留提升空间，并保持较低的运行间方差。
- 对抗采样若只挑当前模型失败的用例，会测量单个模型的失败指纹，困难用例应以人类能说明其困难原因为依据，并结合生产失败案例、缺陷报告和工单。
- /claude-api build-eval 按生产对话记录、缺陷报告与工单、手写用例、代码库合成用例的优先顺序采样输入，并在关键节点请用户审阅批准。
- 评分器优先选用成本最低的程序化验证，开放式输出则采用以可核查陈述为细则的 LLM 作为评判者，且评判模型不应是被测模型，用户需先抽查已评分记录再信任评分器。
- 基线运行期间会诊断评分器一致性、超时与截断等基础设施噪声以及剩余提升空间，基线约达 95% 以上时会建议转向优化成本或延迟。
- 爬山法适合用于修改成本低、分数变化可归因且目标范围明确的对象，如提示词、技能描述、effort 与模型选择，成本是评估饱和后仍可追求的目标。
- 为防止评测泄漏进 harness 造成过拟合，应拆分训练集与测试集、绝不把失败内容粘贴进提示词，并从结构上让模型无法直接获取评估答案。
- /claude-api hillclimb 每轮基于训练转录提出一个补丁，训练集提升而测试集持平或出现退化时回滚，分数停滞时按原因归类剩余失败，最终保留测试集最佳版本并附置信区间报告结果。
- 在内部客户支持基准上，爬山优化通过精简提示词、改用低 effort 的 Sonnet 5 并补充路由规则，使留出集得分从 78.6% 提升到 90.5%，成本约降至原来的五分之一。
- 在 claude-api 技能自身的评估上，爬山优化通过补充缺失功能章节、修正类型表、添加旧写法到新写法的迁移表并修复有缺陷的任务和评分器，将得分从 66% 提升到约 88%。

## 正文

评估可以反映你的应用或技能在特定任务上的表现。但设计评估，以及在不自欺欺人的前提下提升评估表现，都并非易事。我们已在 [claude-api 技能](https://github.com/anthropics/skills/tree/main/skills/claude-api)中补充了这两方面的指导。

> Evaluations provide a signal on how your app or skill is performing on specific tasks. But designing evaluations, and improving performance on them without fooling yourself, is hard. We've added guidance for both to the [claude-api skill](https://github.com/anthropics/skills/tree/main/skills/claude-api).

借助该技能，你可以运行 `/claude-api build-eval` 在代码库中构建评估，并运行 `/claude-api hillclimb` 依据该评估改进你的应用，每次只做一处改动，同时用一组留出的样例来发现过拟合。

> With the skill, you can run `/claude-api build-eval` to build an evaluation inside your codebase, and run `/claude-api hillclimb` to improve your application against it, one change at a time, with a held-out set of examples to catch overfitting.

本文首先介绍良好评测设计与爬山式迭代优化（hillclimbing）的原则，然后展示搭载 `claude-api` skill 的 Claude Code 如何应用这些原则。最后，我们将通过几个示例来演示这些命令。

> In this article, we highlight the principles of good eval design and hillclimbing first, then show how Claude Code with the `claude-api` skill applies those principles. We’ll close by showing a few examples of these commands.

#### 评测设计

> EVAL DESIGN

设计良好的评估通常具备几个共同要素（图 1）：

> Well designed evaluations have a few common elements (Figure 1):

1. **评估任务应反映生产环境。**从你在“生产环境”中关心的任务里抽样，也就是你所测试的能力或应用将被实际使用的场景。有时任务被选中，只是因为它们容易生成或容易评分。但重要的是确保任务分布代表你*真正*关心的内容。
2. **更强的模型和更多的思考会带来更好的表现**。能力更强的模型和更高的投入程度（effort level）通常应在评估中表现更好。如果并非如此，往往是任务存在歧义或评分器校准不当拖累了表现。
3. **前沿模型仍有“过得去”的提升空间**。能力最强的模型在最高推理强度下，在该评测上的得分也应远低于 100%，否则你就无法可靠地判断各种改动对性能的影响。重要的是，这一差距不应源于无法完成或含义模糊的任务：一个常见的迹象是，某个任务无论重复运行多少次，在每次评测中都会失败。好的任务应当满足：两位领域专家会得出相同的判定，并且评分器所检查的每一项内容都已在任务中明确说明。
4. **运行间方差低**。高方差通常源于设计不佳、含义模糊的任务，或是对相同输出给出不同判定的评分器。方差也可能隐藏在配置中。例如，effort 设置可能没有被一致地应用。此外，环境也会影响评估结果：先前试验遗留的状态（某个文件、一段 git 历史）可能会直接把答案交给智能体。

> 1\. **Eval tasks mirror production.** Sample tasks that you care about in “production,” or the setting in which the capability or application you are testing will be used. Sometimes tasks are picked because they are easy to generate or they are easy to grade. But it’s important to ensure that the task distribution represents what you *actually* care about.
> 2\. **Performance improves with stronger models and more thinking**. More capable models and higher effort levels typically should perform better on an evaluation. If they don’t, ambiguous tasks or a miscalibrated grader often are hobbling performance.
> 3\. **There is “passable” headroom at the frontier**. The most capable model at the highest effort should be well below 100% on the evaluation, otherwise you can’t reliably judge how changes impact performance. Importantly, the gap should not be explained by impossible or ambiguous tasks: a common tell is that a task fails every evaluation run, regardless of the number of replicates. A good task is one where two domain experts would reach the same verdict and everything the grader checks is stated in the task.
> 4\. **Low run-to-run variance**. High variance is often due to poorly designed, ambiguous tasks or a grader that produces different verdicts on identical output. Variance can also hide in the configuration. For example, effort may not be applied consistently. Also, the environment can affect the results of the evaluation: leftover state from an earlier trial (a file, a git history) can hand the agent the answer.

##### 对抗采样

> Adversarial sampling

模型的能力是参差不齐的。如果你因为当今模型在某些用例上失败而选择它们，那么你就是在对单个模型能力曲面的低谷进行采样（图 2）。这样一来，评估最终衡量的可能是该模型的失败指纹，而不是对你的应用而言本质上困难或有价值的任务。

> Model capability is jagged. If you pick cases because today's model fails them, you are sampling the valleys of one model's capability surface (Figure 2). The evaluation can end up measuring that model's failure fingerprint rather than what is intrinsically hard or valuable for your application to do.

![Two panels plotting capability across task space, each with today’s model as a jagged curve and the next model as a smoother curve above it. On the left, cases sampled where today’s model fails sit only in its valleys; on the right, cases a person judged hard are spread across peaks and valleys, with a few should-not-fire cases.](https://claude.dev/media/6a014fa959cbc13b3026ca0f2ac1cb8754d541bd07da79bb4c61d81af428024a.png)

挑选困难用例，应以人类判断其困难为依据：一个有用的检验标准是，在纳入某项任务之前，你能说出它为什么困难。纳入那些源自生产流量、缺陷报告或工单的、你的应用中的具体失败案例。不过，不要盲目信任用户流量：用户有时只会尝试他们预期能成功的操作，因此严格从用户流量中抽取的任务分布可能会偏向简单。

> Pick hard cases because a human judged them hard: a useful test is to be able to say why a task is hard before you include it. Include cases that are specific failures in your application derived from production traffic, bug reports, or tickets. However, don’t blindly trust user traffic: users sometimes try what they expect to work, so a task distribution drawn strictly from user traffic may skew easy.

#### /CLAUDE-API BUILD-EVAL

> /CLAUDE-API BUILD-EVAL

claude-api skill 中的 `build-eval` 命令将这些原则转化为一套引导式工作流。当你在 Claude Code 中运行 `/claude-api build-eval` 时，Claude 会向你提问以了解需求，在你的代码库中构建评估，并在特定节点暂停以等待你的批准。

> The `build-eval` command in the claude-api skill turns these principles into a guided workflow. When you run `/claude-api build-eval` in Claude Code, Claude interviews you, builds the eval inside your codebase, and pauses for approval at specific points.

##### 设计示例

> Designing examples

Claude 会按以下顺序帮助你采样输入以构建评估：

> Claude helps you sample inputs to build evaluations in this order:

1. 生产环境的对话记录，但要先问清数据保留期限和敏感数据的处理要求。
2. 缺陷报告和支持工单。
3. 由你亲手编写的五到十个用例。
4. 从你的代码库中合成的用例。

> 1\. Production transcripts, after asking about retention and sensitive data.
> 2\. Bug reports and support tickets.
> 3\. Five to ten cases you write by hand.
> 4\. Cases synthesized from your codebase.

该 skill 优先使用生产流量，但也可以基于你提供的少量真实示例生成合成数据。该 skill 会指示 Claude 生成一个简单的页面，向你展示每一条输入，并等待你确认。作为示例，下面展示了一个电子邮件路由应用的输入集，skill 可能会请用户审阅这些输入（图 3）。

> The skill prioritizes production traffic, but it can also generate synthetic data anchored in a few real examples that you provide. The skill instructs Claude to generate a simple page that shows you every input and waits until you confirm them. As an illustration, below we show an example set of inputs for an e-mail router application that the skill may ask the user to review (Figure 3).

![The skill’s review page for an inbox-routing eval with 24 inputs, listing each case’s email text with tags such as billing, easy and ambiguous. Beside it, Claude asks in chat whether the inputs are representative, and the user answers yes.](https://claude.dev/media/bccc92050c6361924330ef504796ca2c0ce9208d8837356472373f8957b9fdd5.png)

##### 验证评分器

> Validating the grader

确定输入之后，Claude 会提出一个与你的应用输出相匹配、成本最低的评分器：

> After the inputs, Claude proposes the cheapest grader that fits your application’s output:

- **程序化验证**：如果输出的可能范围受到限制，就使用基于代码的检查（精确匹配、来自固定集合的标签、符合 schema 的 JSON、通过的测试）。
- **LLM 作为评判者（LLM-as-judge）**：如果输出空间是开放式的，即存在许多有效答案但质量标准明确，它就会默认采用这类检查。在这种情况下，由第二个模型读取输入、输出以及一份以可核查陈述（而非 1 到 5 分的量表）写成的评分细则，并返回一个分数及其推理过程。如果你有可供比较的基线，评判模型则会以随机顺序读取两个输入，且不会被告知哪一个是基线，然后选出更好的那个。评判模型由你来选择，并且它不应是你正在测试的那个模型。

> • **Programmatic verification**: If the output possibilities are constrained, it uses a code based check (exact match, a label from a fixed set, JSON that matches a schema, tests that pass).
> • **LLM-as-judge**: It will default to this type of check if the output space is open-ended, with many valid answers but clear quality criteria. In this case, a second model reads the input, the output and a rubric written as checkable claims (not a 1-to-5 scale), and returns a score with its reasoning. If you have a baseline to compare against, the judge instead reads both inputs in random order, without being told which is the baseline, and picks the better one. You pick the judge model, and it should not be the model you are testing.

Claude 会对少量案例进行评分，并询问你是否会对其中任何一个给出不同的分数（图 4）。一般来说，在信任你的评估器之前，务必先[阅读一部分已评分的对话记录样本](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)；评分失误是评估配置出错最常见的原因之一。

> Claude grades a handful of cases and asks whether you would have scored any of them differently (Figure 4). In general, it is important to [read a sample of scored transcripts](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) before believing your evaluator; scoring failures are among the most common ways an evaluation is misconfigured.

当你完成对评分器的验证后，该技能会告诉你评估集的规模（用例数 × 重复次数 × 模型数，以及大致需要多长时间），运行基线，并输出带置信区间的分数。你会得到：用例、评分器、运行器、每个用例对应的一行 JSON 和一份完整对话记录，以及一个简单的页面，列出每个用例的分数并附上指向其对话记录的链接。如果你想看到比这个页面更多的内容（例如图表），只需提出要求，Claude 就会在它旁边额外生成一个页面。默认情况下，这些额外页面都是静态文件，在本地打开，不会从网络加载任何内容。

> When you’ve validated the grader, the skill tells you the size of the evaluation set (cases × repeats × model, and roughly how long it will take), runs the baseline, and prints the score with a confidence interval. What you get back: the cases, the grader, the runner, one JSON line and one full transcript per case, and a plain page that lists each case's score with a link to its transcript. If you want more than that page shows (e.g., a chart), just ask and Claude will build it as an extra page next to it. By default, these extra pages are static files that open locally and load nothing from the network.

![The skill’s results page for the inbox-routing eval: a baseline scoring 0.681 mean correct across 24 cases, then a table of per-case scores with a link to each repetition. A rep link opens that case’s raw JSON trace, shown alongside.](https://claude.dev/media/9c7c2f00ebdd0f9e6b8ad0d3de8cdcc6ebb162c9d2fa5b4f4950ac36b736aef8.png)

##### 诊断检查

> Diagnostic checks

在上述基线运行期间，Claude 会检查以下几项内容：

> During the baseline runs mentioned above, Claude checks a number of things:

- **评分器**：Claude 对同一输出运行两次评分器，并报告判定结果是否发生了变化。
- **基础设施检查**：Claude 会检查超时、API 错误和被截断的回答，确保基础设施噪声不会被误当作模型方差。
- **提升空间**：如果基线得分已达到约 95% 或更高，该技能会向用户发出警告，并提示爬山优化应着眼于探索成本或延迟，而非质量。

> • **Grader**: Claude runs the grader twice on the same output, and reports whether the verdict changed.
> • **Plumbing**: Claude checks for timeouts, API errors, and cut-off answers to ensure infrastructure noise doesn't pass as model variance.
> • **Headroom**: if the baseline already scores about 95% or higher, the skill warns the user and alerts that the hillclimb should aim to explore cost or latency rather than quality.

#### 爬山法

> HILLCLIMBING

既然你已经有了一种可靠的方法来评估应用在某项任务上的表现，就可以着手改进它了。爬山法（hillclimbing）是调优 effort 或提示词等参数的有效方法，这些参数需要在成本与性能之间做出权衡。以下是选择在哪些地方应用它的一些通用建议：

> Now that you have a reliable means of grading your application’s performance on a task, you can try to improve it. Hillclimbing is an effective way to tune parameters like effort or prompts, which trade-off cost and performance. Some general tips for choosing where to apply it:

- **低成本迭代** - 修改你在爬山式优化中所聚焦的那个对象，应当是低成本的（无论是时间、费用还是精力）。许多内部项目和客户都将爬山式优化的重点放在文本上，例如提示词和技能。这些内容易于修改，也易于回滚。相比之下，在爬山式优化过程中对智能体 harness 进行开放式修改，可能涉及大量的代码改动。
- **可归因** - 评估分数的变化应当能够归因于你在爬山优化过程中所修改的那个层面。例如，已有多个成功的爬山优化应用聚焦于技能触发。其评估指标（技能的触发率）与正在被修改的技能描述直接关联。
- **目标范围明确** - 一种常见的失败模式是：在没有仔细考虑评估还剩多少提升空间的情况下，提出一个开放式的性能改进请求；如果评估已接近饱和，或者任务范围界定不清（例如，开放式地要求更新 harness），工作就更容易陷入停滞。在各类工作中，成本通常都是一个很好的目标：即使评估已经饱和，你仍然可以让 Claude [寻找降低成本的方法](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform)，同时保持性能不变。

> • **Cheap iteration** - It should be inexpensive (in terms of time, cost, and effort) to modify whatever surface you are focused on for hillclimbing. Many internal efforts and customers have focused hillclimbing on text, such as prompts and skills. These are easy to change and revert. In contrast, open-ended modifications to an agent harness during hillclimbing may involve extensive code changes.
> • **Attributable** - Changes in the score on your evaluation should be attributable to the surface you are modifying during hillclimbing. For example, several successful applications of hillclimbing have focused on skill triggering. The evaluation metric (the trigger rate for the skill) is directly coupled to the skill description that is being modified.
> • **Well-scoped objective** - One common failure mode is an open-ended request to improve performance without careful consideration of the headroom available in the evaluation; an evaluation that’s near saturation or a poorly scoped surface (e.g., an open-ended request to update the harness) is more likely to stall. One generally strong objective across various efforts is cost: even if an evaluation is saturated, you can ask Claude to [find ways to reduce cost](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform) while keeping performance at parity.

##### 过拟合

> Overfitting

即使是设计良好的评估，也很少能与你在生产环境中真正关心的任务分布完全吻合。因此，对评估"过拟合"是一个常见问题，其结果是系统在评估上的表现优于在生产流量上的表现。

> Even a well-designed evaluation rarely matches the exact task distribution you care about in production. As a result, "overfitting" to an evaluation is a common problem and results in a system that performs better on an evaluation than on production traffic.

评估“泄漏”进你的 harness（即模型周围的代码，包括提示词、工具以及调用 Claude 的循环）的方式有很多。例如，假设某个评估任务能从 OCR 中获益，但 OCR 在你的生产任务中却很少有用。评估 harness 可能会给你的应用添加一个 OCR 工具，这会提升基准测试成绩，却对生产毫无影响。更广泛地说，爬山式优化（hillclimbing）可能会向 harness 添加一些功能，专门处理你所选特定评估样例中的边缘情况。这些 harness 上的新增内容会提高你的评估分数，却无法转化为生产中的改进（图 5）。

> There are many ways an evaluation can "leak" into your harness (the code around the model, including prompts, tools, and loop that calls Claude). For example, consider an evaluation task that benefits from OCR, but OCR is rarely beneficial in your production tasks. The evaluation harness might add an OCR tool to your application, which improves on the benchmark without any impact on production. More broadly, hillclimbing may add features to that harness that address edge cases in the particular evaluation examples you’ve chosen. These harness additions improve your evaluation score, but don’t translate to improvements in production (Figure 5).

![The benchmark’s traits on the left, each shaping a matching addition to the harness on the right: a task mix that needs OCR adds an OCR tool, tasks in /app add “always cd /app, run pytest”, distinctive phrasings get a tuned prompt, and failures you’ve read get one patch each. A dashed arrow marks the outright leak: a public repo with answers lets the harness curl the reference solution.](https://claude.dev/media/a328a3f4d5bfd0967174ef2ca79bc8f094d8db3c12af71be3189891bf40d0e53.png)

有三件事可以帮助解决这个问题：

> Three things can help address this:

- **拆分用例**。使用一个爬山优化器可以读取的训练集，以及一个它从未见过的测试集。如果训练集得分提升而测试集得分停滞不前，这就是过拟合的常见警示信号。
- **绝不要把失败内容粘贴进提示词**。如果爬山优化器会读取失败的运行记录，它就绝不应把失败内容粘贴进提示词。
- **从结构上让答案处于模型无法触及的位置**。模型有时会通过直接找到评估答案来“奖励作弊”（reward hack）。

> • **Split the cases**. Use a train set that the hillclimber may read and a test set that is never seen. If the train set scores improve while the test set scores stay flat, then that is a common overfitting warning sign.
> • **Never paste failures into the prompt**. If the hillclimber reads the failing transcripts, it should never paste the failure content into the prompt.
> • **Keep the answers structurally out of the model's reach**. Models can sometimes “reward hack” by directly finding answers to evaluations.

正如下文所述，claude-api 技能会替你应用这些原则。

> As discussed below, the claude-api skill applies these principles for you.

#### /CLAUDE-API 爬山式迭代优化

> /CLAUDE-API HILLCLIMB

claude-api 技能中的 hillclimb 命令将这些原则转化为一套引导式工作流。当你在 Claude Code 中运行 `/claude-api hillclimb` 时，Claude 会针对给定的评估进行迭代改进。你可以选择允许它做出哪些更改，包括：

> The hillclimb command in the claude-api skill turns these principles into a guided workflow. When you run `/claude-api hillclimb` in Claude Code, Claude iterates to improve against a given evaluation. You choose what changes it can make including:

- 你的系统提示词
- Skills 或指令文件
- 工具描述
- 模型选择、effort 级别及其他 API 参数
- 你的 harness 代码

> • Your system prompt
> • Skills or instruction files
> • Tool descriptions
> • Model choice, effort level, and other API parameters
> • Your harness code

开始之前，Claude 会询问你想优化什么（例如性能，或在性能保持不变的前提下优化成本），然后将评估集随机划分为测试集和训练集。如果目标是成本，它会考虑[几个常见的成本驱动因素](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform)，包括提示缓存、审查提示词与所选模型的兼容性，以及选择模型和 effort 设置。

> Before it starts, Claude asks what you want to optimize (e.g., performance, or cost while performance holds) and then splits the evaluation set at random into test and train. With a cost goal, it considers [a few common cost drivers](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform), including prompt caching, auditing the prompt for compatibility with the selected model, and picking the model and effort setting.

在第一轮开始之前，Claude 会检查评测的噪声（仅凭偶然因素分数可能波动的幅度）是否小于你会据以采取行动的最小改进幅度；如果不是，它会明确指出这一点，并建议增加重复次数或用例。

> Before the first round, Claude checks that the eval's noise (how far the score can move by chance alone) is smaller than the smallest improvement you'd act on; if it isn't, it says so and suggests more repetitions or cases.

每一轮中，Claude 会阅读上一轮的训练转录记录，并以补丁形式提出一项修改。它每一轮都瞄准那些效果能够超出评估噪声的修改：从根源上修复失败的行为（例如，重写导致该行为的段落，或补充缺失的规则），而不是仅仅改写某一行措辞。随后，它用打过补丁的修改运行评估。此时，Claude 会进行一项检查：如果 `train` 集有所提升而 `test` 集持平，Claude 会怀疑出现了过拟合并回滚该补丁。如果出现退化，Claude 也会回滚。如果训练集和测试集都有提升，它就保留该补丁（图 6）。

> Each round, Claude reads the previous round’s train transcripts and proposes one change as a patch. It aims each round at a change whose effect can show above the eval's noise: it fixes the failing behavior at its root (e.g., rewrites the section that causes it or adds a missing rule) rather than rewording a line. It then runs evaluation with the patched change. At this point, Claude applies a check: if the `train` set improves but the `test` set is flat, Claude suspects overfitting and reverts the patch. If there is a regression, Claude reverts. If train and test sets improve, it keeps the patch (Figure 6).

![The hillclimbing loop: the thing being edited, such as a prompt, feeds a fixed model and harness that is scored on a held-out test split and a train split. An analyzer reads only the train failures and proposes one diff per round; the diff is kept when train and test both rise, and reverted when only train rises or either score drops.](https://claude.dev/media/dafbc5fb0edf5aeed96af8984ec09f6a0f8ebd753274c305ccf3043e1640d75a.png)

当分数连续两三轮停滞不前时，Claude 会逐一查看剩余的每个训练集失败案例，并按原因进行归类。如果任何单一修复所能带来的提升都不会超过评测本身的噪声，它也会提前执行这一步，并建议增加重复次数或用例，而不是把轮次耗费在小到无法测量的改动上。这一步可以发现含义模糊的评测用例、测试框架错误或不同运行之间的波动。

> When the score stalls for two or three rounds, Claude reads each remaining train failure and sorts it by cause. It does the same early if no single fix could gain more than the eval's noise, and suggests more repetitions or cases, rather than spending rounds on changes too small to measure. This step can catch ambiguous evaluation cases, harness errors, or run-to-run variance.

只有真正的失败案例才会被纳入后续的爬山优化轮次。

> Only legitimate failures are included in more hillclimbing rounds.

爬山优化完成后，Claude 会将你的代码保留在针对你的目标、在测试集上表现最好的那个版本。它会报告测试结果相对于基线的表现，并附上置信区间（图 7）。如果提升幅度在噪声范围之内，它会如实说明，并建议不要合并。

> When hillclimbing completes, Claude leaves your code at the version that did best on the test set for your goal. It reports the test result against the baseline with confidence intervals (Figure 7). If the gain is within noise, it says so and recommends against merging.

![The inbox-routing results page after hillclimbing, comparing three variants on train and test scores. Variant v1, which defines each queue and adds a tie-break rule, is marked best at 0.875 on both; v2, which adds two worked examples, was reverted because train went up while test stayed flat.](https://claude.dev/media/8c9b0ffdf9d75df81ec451ccb55feb091693fb7eb88ad9c20f3911387e3ec4e1.png)

#### 示例

> EXAMPLES

##### 通过爬山法降低成本

> Hillclimbing for cost reduction

我们在一个[内部客户支持基准测试](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform)上运行了 `/claude-api hillclimb`，目标是降低成本并提升性能。该基准测试包含 44 个工单，其中 30 个用于搜索，14 个留作保留集。初始配置为 Opus 4.8、默认（high）effort 设置，在搜索工单上的决策准确率为 74.4%，每个工单的 token 成本为 4.6 美分。

> We ran `/claude-api hillclimb` on an [internal customer support benchmark](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform) with the goal of reducing cost and improving performance. The benchmark included 44 tickets, with 30 used for the search and 14 held out. It started on Opus 4.8 at default (high) effort settings with 74.4% decision accuracy on the search tickets and a token cost of 4.6 cents per ticket.

爬山式优化首先审查了提示词，[删除了](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform)强制性的工具调用流程、草稿推理步骤以及相互矛盾的规则。随后，它尝试在低推理强度下使用 Opus 5.5。这一配置以 87.8% 的准确率越过了基线准确率门槛，并将成本降至每张工单 1.9 美分，不到初始成本的一半。

> The hillclimb first audited the prompt, [removing](https://claude.com/blog/reducing-cost-and-improving-performance-with-claude-platform) mandatory tool-call rituals, a scratchpad step, and contradictory rules. Then it tried Opus 5.5 on low effort. This cleared the baseline accuracy bar at 87.8% and cut cost to 1.9 cents per ticket, less than half the starting cost.

节省的部分原因来自 [Opus 5.5 的定价](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/)：其输入和输出 token 的价格比 Opus 4.8 低 20%，缓存读取的价格低 60%。由于 Opus 5.5 达到了标准，爬坡优化随后降低一个档位，检验更便宜的模型能否同样达标。低投入（low effort）模式下的 Sonnet 5 得分大致相同，为 88.9%，成本约为一半，即每张工单 1 美分（图 8）。

> Part of that saving comes from [Opus 5.5's pricing](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/): input and output tokens cost 20% less than on Opus 4.8, and cache reads cost 60% less. Because Opus 5.5 cleared the bar, the hillclimb then stepped down a tier to check whether a cheaper model could clear it too. Sonnet 5 on low effort scored about the same, 88.9%, at about half the cost, 1 cent per ticket (Figure 8).

最后，Claude 通过加入路由规则和退款上限交叉引用改进了提示词，使 Sonnet 5 在成本大致不变的情况下达到 98.9%。在搜索过程中从未见过的 14 个留出工单上，最终配置的得分为 90.5%，而原始设置为 78.6%，成本约为后者的五分之一。

> Finally, Claude improved the prompt with routing rules and a refund-cap cross-reference, bringing Sonnet 5 to 98.9% at about the same cost. On the 14 held-out tickets that the search never saw, the final configuration scored 90.5% against the original setup's 78.6%, at about one fifth of the cost.

##### 通过爬山法提升性能

> Hillclimbing for performance improvement

另一个例子是我们的 [claude-api](https://github.com/anthropics/skills/tree/main/skills/claude-api) skill，它提供了使用我们 API 的指导，以及与 Claude 协作的通用技巧（包括本文讨论的子命令）。我们希望确保该 skill 能够正确实现调用我们 API 的代码，因此基于我们的文档构建了一个评估集来测试该 skill。

> Another example is our [claude-api](https://github.com/anthropics/skills/tree/main/skills/claude-api) skill, which provides guidance on using our APIs and general tips for working with Claude (including the sub-commands discussed in this article). We want to ensure our skill can correctly implement code that uses our APIs, and we built an evaluation set derived from our documentation to test the skill.

在我们的评估中，该技能最初的得分为 66%。我们让 hillclimber 能够访问文档和我们的 SDK，使 Claude 能够发现错误并自行纠正（图 9）。Claude 发现该技能缺少对八项功能的覆盖。

> On our evaluation, the skill started at 66%. We gave the hillclimber access to documentation and our SDKs, allowing Claude to identify errors and self-correct them (Figure 9). Claude found that the skill was missing coverage of eight features.

在技能中为它们添加相应章节后，性能提升到了 74%。随后，它又发现了 C# 和 Java 类型表中的错误，将性能进一步提升到 77%。

> Adding sections for them in the skill improved performance to 74%. It then found errors in C# and Java type tables, boosting performance to 77%.

在分数连续两轮停滞不前之后，Claude 分析了剩余的失败案例，并按根本原因进行了归类。常规的一轮会针对最常见的失败做一处修改。而这一步不做任何修改，只是将所有剩余的失败按原因分类。这一反思步骤在以下几个方面很有用：

> After the score stalled for two rounds, Claude analyzed the remaining failures and bucketed them by root-cause. A normal round makes one edit for the most common failure. This step makes no edit; it only sorts every remaining failure by cause. This reflection step was useful in a few ways:

- 在对一批失败案例进行综合分析后，hillclimber 发现技能内容本身并不缺失，问题在于 Claude 写出的仍是旧版的 API 形式（例如来自其训练先验）。为解决这一问题，hillclimber 在技能文件靠前的位置添加了一张表格，引导 Claude 从它记忆中的旧写法转向当前写法：例如，从使用固定 token 预算的扩展思考（API 现已在近期的 Opus 模型上拒绝这种用法）转向自适应思考，以及从旧版的网页搜索和网页抓取工具转向当前版本。它还把 C# 和 Java 中关于避免使用固定预算思考的警告移到了各自的自适应思考示例之前。这使性能提升到了 80%。
- 有些任务即便补上了明显的内容缺口，表现也始终没有提升，这说明示例或评分器本身存在缺陷。其中一个任务要求编写捕获一种错误类型的代码，而它的评分器却要求至少三层的错误链。Claude 重新措辞了这个任务。另一个评分器的说明与我们的文档相互矛盾，而对真实 API 的测试表明文档是对的。解决这些问题，再加上对技能的更多修改，使表现提升到约 88%。

> • Reflecting across a collection of failures, the hillclimber found that the skill content was present but Claude was simply writing older API shapes (e.g., from its trained priors). To address, the hillclimber added a table near the top of the skill that guided Claude from the forms it remembered to the current ones: for example, from extended thinking with a fixed token budget, which the API now rejects on recent Opus models, to adaptive thinking, and from older versions of the web search and web fetch tools to the current ones. It also moved the C# and Java warnings against fixed-budget thinking above their adaptive-thinking examples. This improved performance to 80%.
> • Tasks that never improved in performance despite addressing obvious content gaps are tells that the example or grader is flawed. One task asked for code that catches one error type, while its grader wanted a chain of at least three. Claude reworded the task. Another grader's instructions contradicted our docs, and testing the real API showed the docs were right. Addressing these, along with more skill edits, brought performance to ~88%.

#### 入门指南

> GETTING STARTED

**注意：**请先运行 `claude update`。claude-api skill 随 Claude Code 一同提供，因此更新后即可获得这些命令的最新版本。

> **Note:** Run `claude update` first. The claude-api skill ships inside Claude Code, so updating gets you the latest version of these commands.

```
claude update
```

然后，在 Claude Code 中：

> Then, in Claude Code:

```
/claude-api build-eval
/claude-api hillclimb
```

这些子命令可以通过 [claude-api skill](https://github.com/anthropics/skills/tree/main/skills/claude-api) 在 Claude Code 中直接使用：

> These sub-commands can be used directly in Claude Code via the [claude-api skill](https://github.com/anthropics/skills/tree/main/skills/claude-api):

如果你想为某个特定问题生成评估集，可以运行 `/claude-api build-eval`。你可以通过提供示例（例如 trace）来引导它。Claude 会运用本文分享的指导原则来设计示例和评分器，并确保由你来审批这些示例和评分器。

> Run `/claude-api build-eval` if you want to generate an evaluation set for a particular problem. You can steer it by providing access to examples (e.g., traces). Claude will employ the guidance shared in this article to design the examples and grader, and ensure you approve the examples and the grader.

如果你已有一套评估，并希望 Claude 在你的目标指引下（例如提升性能，或在性能不变的前提下降低成本）对其进行改进，请运行 `/claude-api hillclimb`。Claude 会运用本文分享的指导方法，在分数攀升过程中检查是否存在过拟合，并检查评估本身是否存在缺陷，例如评分器把看似正确的答案判为错误，或测试框架出错；这些检查会在第一轮之前进行，也会在分数停滞不前时进行。

> Run `/claude-api hillclimb` if you have an evaluation and want Claude to improve on this, guided by your goal (e.g., better performance, or lower cost while performance holds). Claude will employ the guidance shared in this article to check for overfitting while climbing and check for bugs in the eval itself, such as a grader that marks a correct-looking answer wrong or a harness error, both before the first round and whenever the score stalls.

*特别感谢 Misha Khalman 在技能开发方面的贡献。感谢 Misha Khalman、Michael Segner、Matt Bell、Matt Thanabalan 和 Punit Shah 提供的审阅、贡献和产品支持。*

> *With special thanks to Misha Khalman for skill development. With thanks to Misha Khalman, Michael Segner, Matt Bell, Matt Thanabalan, and Punit Shah for reviews, contributions, and product support.*

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Eval | 评估 / 评测 | 衡量应用或技能在特定任务上表现的一组用例与评分方法。 |
| Hillclimbing | 爬山式优化 | 每次做一处改动并依据评估分数决定保留或回滚的迭代优化方法。 |
| Grader | 评分器 | 对模型输出给出分数或判定的程序或模型。 |
| LLM-as-judge | LLM 作为评判者 | 由另一个模型依据评分细则对输出打分的评估方式。 |
| Rubric | 评分细则 | 评判模型据以打分的一组可核查标准陈述。 |
| Overfitting | 过拟合 | 系统在评估上的表现提升却无法迁移到生产流量的现象。 |
| Held-out set | 留出集 | 优化过程中从未被读取、用于检验泛化效果的用例集合。 |
| Harness | 运行框架 / harness | 模型周围的代码，包括提示词、工具以及调用模型的循环。 |
| Reward hacking | 奖励作弊 | 模型通过钻评估漏洞而非真正完成任务来获得高分。 |
| Effort level | 投入程度 / 推理强度 | 控制模型在回答时投入多少思考的 API 参数。 |
| Adversarial sampling | 对抗采样 | 专门挑选当前模型失败用例来构建评估的采样方式。 |
| Variance | 方差 | 同一配置多次运行之间分数的波动程度。 |
| Confidence interval | 置信区间 | 表示分数估计不确定性范围的统计区间。 |
| Prompt caching | 提示缓存 | 复用已处理的提示前缀以降低成本和延迟的机制。 |
| Adaptive thinking | 自适应思考 | 由模型自行决定思考量、取代固定 token 预算的扩展思考方式。 |
