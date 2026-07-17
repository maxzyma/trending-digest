---
source: claude-blog
source_url: https://claude.com/blog/ai-code-migration
published_at: 2026-07-16
category: Claude Code
title_en: How Anthropic runs large-scale code migrations with Claude Code
title_zh: Anthropic 如何用 Claude Code 完成大规模代码迁移
format: bilingual-paragraph-zh-first
source_intro_paragraphs: 6
source_image_count: 6
---

# Anthropic 如何用 Claude Code 完成大规模代码迁移

> How Anthropic runs large-scale code migrations with Claude Code

> 来源：Claude Blog，2026-07-16
> 原文链接：https://claude.com/blog/ai-code-migration
> 分类：Claude Code

## 核心要点

- 曾经需要数年的生产代码库跨语言迁移，如今借助 Claude 智能体可在数天到数周内完成，且失败的代价只是删除分支重来。
- Bun 联合创始人 Jarred Sumner 用 Claude Code 在不到两周内生成百万行代码，将 Bun 从 Zig 迁移到 Rust，合并前全部现有测试在 CI 中通过。
- Anthropic Labs 的 Mike Krieger 在一个周末把 Python 代码库迁移为 16.5 万行 TypeScript，采用数百个智能体、八道阶段闸门与三轮对抗式评审。
- 核心理念是不去修补代码本身，而是修正产出代码的流程（迭代循环）。
- 大规模迁移特别适配先进模型：工作可跨文件与 crate 并行、旧代码即现成规格、测试套件充当客观裁判、编译或测试失败自动生成待办队列。
- 迁移不再需要以生死存亡为由；一年的内存缺陷补丁记录或一处长期瓶颈即可构成合理商业理由，但百万行迁移仍需数万至数十万美元成本。
- 流程围绕六个步骤展开：先建立规则手册、依赖图谱与缺口清单，再压力测试规则，随后全量翻译，最后编译、运行并比对行为一致性。

## 正文

运用 AI 智能体开展大规模代码迁移的分步指南——包含 Bun 将百万行代码从 Zig 迁移到 Rust 的实践。

> A step-by-step guide to running large code migrations with AI agents — including Bun's million-line Zig-to-Rust port.

代码迁移，即把生产代码库移植到新语言的项目，直到最近还是耗时数年的工程。

> Code migrations, projects that port a production codebase to a new language, were multi-year endeavors until recently.

在过去一个月里，Anthropic 的开发者们借助 Claude Fable 5、Claude Opus 4.8 和[动态工作流](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)，独立完成了 10 个代码包的迁移，代码量从数万到数十万行不等。本文将介绍其中两个案例，以及这些项目中总结出的最佳实践。

> In the last month, individual developers at Anthropic migrated 10 code packages consisting of tens to hundreds of thousands of lines of code using Claude Fable 5, Claude Opus 4.8, and [dynamic workflows](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code). In this article we’ll cover two examples along with best practices from these projects.

Bun 的联合创始人、Anthropic 技术团队成员 Jarred Sumner 使用 Claude Code [将 Bun 从 Zig 迁移到 Rust](https://bun.com/blog/bun-in-rust)。不到两周就产出了一百万行代码，合并前 Bun 现有测试套件在 CI 中 100% 通过。合并后浮现出 19 处回归，现已全部修复。这个 Rust 移植版于 6 月在 Claude Code 内发布。

> Jarred Sumner, co-founder of Bun and Member of Technical Staff at Anthropic, used Claude Code to [migrate Bun from Zig to Rust](https://bun.com/blog/bun-in-rust). A million lines of code were produced in less than two weeks, with 100% of Bun's existing test suite passing in CI before merge. Nineteen regressions surfaced after merge and have all been fixed. The Rust port was shipped inside Claude Code in June.

Anthropic Labs 联合负责人 Mike Krieger 在一个周末里把一个 Python 代码库迁移成了 16.5 万行 TypeScript。这个过程包括数百个 agent、八道阶段关卡（phase gate）、三轮对抗式评审，以及一次最终一致性检查——把每条命令的输出与 Python 原版逐一对比。

> Mike Krieger, co-lead of Anthropic Labs, migrated a Python codebase to 165,000 lines of TypeScript over a weekend. This included hundreds of agents, eight phase gates, three adversarial review rounds, and a final parity check that diffed every command's output against the Python original.

Claude Code 的新能力改变了这些长期被搁置的项目的算盘。下面是我们现在采用的六步流程，源自这些迁移带给我们的经验。

> Claude Code’s new capabilities change the math for these long-deferred projects. Below is the six-step process we now use, drawn from what these migrations taught us.

核心洞见在于：你不是去修代码，而是去修产出代码的流程（循环）。

> The core insight is that you don’t fix the code. You fix the process (loop) that produced the code.

### 为何以及何时进行语言迁移

> Why and when to migrate languages

在直接进入"怎么做"之前，值得先讨论"何时"和"为何"，因为围绕这类项目的假设已经发生了变化。

> Before going straight into the how, it’s worth discussing the when and why because the assumptions around these projects have evolved.

团队启动迁移，是因为从最初构建到当前项目之间技术格局发生了变化。要么是某个已知的权衡取舍开始成为掣肘，要么是出现了更好的方案，要么是原有的生态系统正在萎缩。

> Teams launch migrations because of landscape changes between their initial build and current project. Either a known trade-off has become limiting, a better approach has emerged, or the original ecosystem is shrinking.

举例来说，Jarred 最初选择 Zig，是因为它以极致的简洁提供了 C 级别的性能，非常适合一位独立创始人——"在大语言模型（LLM）出现之前，于奥克兰一间狭小的公寓里用一年时间写出 Bun"。这种简洁也带来了已知的权衡取舍，[他在这里写到了这一点](https://bun.com/blog/bun-in-rust#just-be-really-smart-and-don-t-make-mistakes)。

> For example, Jarred originally chose Zig because it offered C-level performance with radical simplicity, ideal for a solo founder “writing Bun in 1 year in a cramped Oakland apartment pre-LLM.” This simplicity came with known tradeoffs, [which he writes about here](https://bun.com/blog/bun-in-rust#just-be-really-smart-and-don-t-make-mistakes).

快进到 2026 年。Bun 的命令行工具（CLI）月下载量已超过 1000 万次，并在 Claude Code 中被大量使用。

> Fast forward to 2026. Bun's CLI is getting over 10 million monthly downloads and is used extensively within Claude Code.

就在上个季度，这些权衡取舍还不足以成为冻结路线图、投入资源去做一个跨越多个季度项目的理由。迁移语言可以带来更小、更快、更安全的系统，但没人愿意为此买单。

> As recently as last quarter, those tradeoffs wouldn’t have been enough to justify freezing the roadmap and committing resources to a multi-quarter project. Migrating languages can deliver smaller, faster, and safer systems, but no one wants to pay for them.

软件工程师还不得不面对这些曾经的超大型项目所固有的职业风险。你可能要维护两套并行的代码库好几个季度甚至好几年，而如果最终结果只有 90% 的功能对等，你面对的麻烦比开始时还要大。

> Software engineers have also had to contend with the career risk inherent in these formerly mega-projects. You could maintain two parallel code bases for quarters or years, and if the end result was 90% parity, you had a bigger headache than when you started.

如今，最坏的情况不过是删掉分支，重新再来。

> Now, the worst case scenario is you delete the branch and try again.

迁移仍然需要一个站得住脚的商业理由。虽然百万行级别的迁移不再像四年周期项目那样耗费 300 万到 400 万美元的工程资源，但执行起来仍然要花费数万到数十万美元甚至更多。以 Bun 的迁移为例，它消耗了 59 亿个未缓存的输入 token 和 6.9 亿个输出 token——按 API 定价约合 16.5 万美元。Mike 的移植主体部分用掉了 2700 万个 token。

> There still needs to be a justifiable business case. While million line migrations no longer cost $3 to $4 million in engineering resources over the course of a four year project, they still cost tens to hundreds of thousands of dollars or more to execute. The Bun migration, for example, consumed 5.9 billion uncached input tokens and 690 million output tokens — around $165,000 at API pricing. The main portion of Mike’s port was 27 million tokens.

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a58f8844b99cec5d277a9ee_27e78c5a.png)

不过，迁移的理由不再需要是关乎生死存亡的了。变更日志中一整年的内存 bug 补丁，或者一个长期存在的瓶颈，如今都足以成为迁移的理由。

> However, the migration case no longer needs to be existential.A year of memory-bug patches in the changelog, or one chronic bottleneck, can now justify it.

编译环节正是 Mike 这个项目的推动因素。他的团队所开发的内部工具，是以单个二进制文件的形式交付给用户的。用 Python 工具链生成这个二进制文件，每个平台大约需要八分钟，在整个构建矩阵中每次发布累计要等待 30 分钟。移植之后，同样的编译现在只需大约两秒，二进制文件启动速度快了 6 倍，团队还得以淘汰一条单独的部署流水线。

> The compile step was the impetus for Mike's project. The internal tool his team works on ships to users as a single binary. Producing that binary with the Python toolchain took roughly eight minutes per platform, totaling a 30-minute wait across the build matrix on every release. After the port, the same compile now takes about two seconds, the binary starts 6x faster, and the team was able to retire a separate deployment pipeline.

### 为什么 AI 改变了代码迁移的算法

> Why AI changes the code migration math

Claude Fable 5 是我们能力最强、已全面开放的模型。Fable 和 Opus 4.8 尤其擅长借助子代理（subagent）委派、指挥并验证并行的工作流，同时能为既定目标找到多条实现路径。

> Claude Fable 5 is our most capable, generally available model. Fable and Opus 4.8 are particularly good at delegating, directing, and verifying parallel workstreams with subagents while finding multiple paths towards stated goals.

大规模代码迁移是这些高级模型特别有效的应用场景，原因在于：

> Large code migrations are a particularly effective use case for these advanced models because:

- 工作是并行的。工作可以拆分到成千上万个彼此独立的单元上执行，比如文件和 crate，因此多个代理可以同时干活，而不必一个等着另一个。
- 上下文清晰且完整。旧代码本身就是给模型的一份出色规格说明。它还是一份核心参考，有助于构建供翻译代理遵循的指南。
- 内置了裁判。许多大型代码库都带有测试套件，代理可以用它来验证自己的工作。当验证是客观的时候，代理表现最佳，因为模型可以对着一个基准事实（ground truth）持续打磨数天，无需人来仲裁质量。
- 队列会自我生成。当编译器或测试运行失败时，那就成了代理要修复的下一个事项。
- 它们要求一致性和边界情况处理：整个流程的设计让偏移无处藏身：审查者为每一条发现都援引其背后的规则，于是违规就变成一个队列事项，而不是一次悄无声息的偏离。而当代理真的碰到边界情况时，修复方案就会成为后续每个代理都遵循的规则。

> • The work is parallel. Work can be executed across thousands of independent units such as files and crates, so agents can work at the same time rather than have one waiting on the other.
> • Context is clear and comprehensive.The old code serves as a great spec for the model. It also serves as a core reference to help build the guide for translation agents to follow.
> • There is a built-in referee. Many large codebases will include a test suite that agents can use to verify their work. Agents perform their best when verification is objective, because the model can grind against a ground truth for days without a human arbitrating quality.
> • The queue writes itself. When a compiler or test run fails, that becomes the next item for an agent to fix.
> • They require consistency and edge case handling: The process is built so drift has nowhere to hide: reviewers cite the rule behind every finding, so a violation becomes a queue item instead of a quiet divergence. And when an agent does hit an edge case, the fix becomes a rule every subsequent agent follows.

正如我们下文将看到的，Mike 和 Jarred 在各自的迁移流程中都把 Fable 用在了关键步骤上，尤其是采用一种顾问式模式，用多个模型级别来优化 token 消耗。

> As we will see below, both Mike and Jarred used Fable for key steps in their migration process, particularly in an advisory pattern that used multiple model classes to optimize token consumption.

### 大规模代码迁移的六个步骤

> Six steps for large code migrations

下面的流程已做泛化处理，适用于多种语言和场景。更多细节可阅读 [Jarred 的博客](https://bun.com/blog/bun-in-rust)。

> The process below has been generalized to be relevant to multiple languages and scenarios. For additional details, you can read[Jarred’s blog](https://bun.com/blog/bun-in-rust).

#### 前置条件

> Prerequisites

启动迁移项目前的一个前置条件是要有一个强有力的评判器（judge），否则你将没有退出条件，也无法衡量是否成功。

> A prerequisite before starting on your migration project is to have a strong judge in place, otherwise you won’t have an exit condition or measure of success.

评判器必须能够在同等条件下评估原始代码和目标代码。用原始语言编写的测试套件往往依赖目标代码中不存在的内部函数。

> The judge must be able to evaluate both the original code and the target code on equal terms. Test suites written in the original language will often depend on internal functions that won't exist in the target code.

要构建这个评判器：

> To build this judge:

- 对现有测试分类。用 Claude 识别哪些测试可以表达为外部调用，哪些依赖于无法移植的内部实现。
- 为可移植性重写。将面向外部的测试转换为可同时对原始代码和移植代码运行的断言。用对抗性智能体（adversarial agents）来验证重写后的测试没有削弱断言。
- 验证评判器。先针对原始代码运行，确认它通过。再针对故意弄坏的代码运行，确认它失败——一个抓不出破坏的评判器算不上评判器。

> • Categorize existing tests. Use Claude to identify which tests are expressible as external calls and which depend on internals that won't port.
> • Rewrite for portability. Convert the external-facing tests into assertions that can run against both the original and the port. Use adversarial agents to verify the rewritten tests don't weaken the assertions.
> • Validate the judge. Run it against the original code to confirm it passes. Then run it against deliberately broken code to confirm it fails — a judge that doesn't catch breakage isn't a judge.

Jarred 有一个用第三种语言（TypeScript）编写的大型测试套件，但对大多数项目来说不会是这种情况。对于他从 Python 到 TypeScript 的移植，Mike 用七个真实场景搭建了一个对等测试框架（parity harness），并将任何行为变化都视为需要修复的缺陷。

> Jarred had a large test suite written in a third language (TypeScript), but that will not be the case for most projects. For his Python-to-TypeScript port, Mike created a parity harness of seven real-world scenarios and considered any behavior change a bug to be fixed.

在进入每个阶段之前，这张图或许能帮你跟上思路。它大体遵循 Jarred 的方法论，在每个阶段都设有评审和关卡。Mike 采用了类似的整体结构和类似的循环工作流，但他把整个迁移端到端跑了一遍，根据结果修订规则和工作流，然后再跑一遍——每次都丢弃输出，直到第三次运行才保留。

> Before we get into each stage, this graphic may help you follow along. This mostly follows Jarred’s methodology, with reviews and gates at each stage. Mike followed a similar overall structure using similar loop workflows, but he ran the entire migration end to end, revised the rules and the workflow based on the results, and ran it again — discarding the output each time until the third run.

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a58f8854b99cec5d277aa48_e7dd47de.png)

#### 步骤 1——创建规则手册、依赖关系图和差距清单

> Step 1 — Create the rulebook, dependency map, and gap inventory

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a58fa78da7794274460319e_Code-migration-step1.jpeg)

在这个阶段，我们要打好迁移的基础：一份清单，列出哪些地方需要重构而不只是翻译代码；一份规则手册，说明如何翻译我们的代码；以及一份依赖关系图，用于给迁移实现的各条工作流排序。

> In this stage we are creating the foundations of our migration: an inventory of places where code will need to be refactored rather than just translated, a rulebook for how to translate our code, and a dependency map to order our migration implementation workstreams.

顺序很重要：规则手册必须先于差距清单。差距清单是由规则手册的默认规则未能覆盖的部分定义的，两者会在一次联合审计中一起接受测试。

> The order matters: the rulebook must come before the gap inventory. The gap inventory is defined by what the rulebook's defaults won't cover, and the two are tested together in a joint audit.

##### 规则手册

> Rulebook

[规则手册](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/templates/RULEBOOK.md)的具体形态取决于你在一开始必须做出的关键架构决策。其中最主要的是：新代码是沿用相同结构，还是彻底重新设计。

> The exact shape of the [rulebook](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/templates/RULEBOOK.md) depends on key architectural decisions you must make at the start. Chief among them, if the new code will follow the same structure, or if it will be completely redesigned.

如果是前者（Jarred 的情况），规则手册将主要是一些查找表，在语言之间翻译类型和惯用法，同时对那些较难翻译的组件指向差距清单。如果是后者（Mike 的情况），它将是一份设计文档。

> If it’s the former (Jarred), the rulebook will primarily be lookup tables that translates types and idioms between languages while pointing to the gap inventory for the harder-to-translate components. If it’s the latter (Mike), it will be a design document.

Jarred 通过与 Claude 对话来创建规则手册，为每个存在歧义的领域制定一条策略。他还使用了八个子智能体（subagents），专门根据他自己的直觉针对 8 类常见失败模式进行审查。

> Jarred created his rulebook by chatting with Claude, forming a policy for each area of ambiguity. He also used eight subagents specifically designed to review for 8 different categories of common failure modes based on his own intuition.

##### 依赖关系图

> Dependency map

你需要了解文件之间的依赖关系，才能有效地拆分工作流以进行并行迁移，从而知道先迁移哪些文件、哪些文件应放在同一批次中。有些语言和代码库有明确的清单文件，使这件事变得简单，但对于遗留代码库以及 C/C++ 和 Python 等许多流行语言，这些依赖关系需要被发现并绘制出来。

> You need to understand file dependencies to effectively break up workstreams for a parallel migration so you know which files to migrate first and which files to contain in the same batch. Some languages and codebases have explicit manifests that make this easy, but for legacy codebases and many popular languages like C/C++ and Python, these dependencies need to be discovered and mapped.

Claude Code 可以部署智能体来创建并运行一个确定性脚本，以生成这张图。[迁移工具包中的提示词](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/01-dependency-map.md)采用一个工作流来创建审查—修复循环。注意：这个入门工具包是本文所述流程的泛化模板——并不是这几个具体移植项目实际运行时所用的东西。

> Claude Code can deploy agents to create and run a deterministic script to produce this map. The [prompt in the migration kit](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/01-dependency-map.md) uses a workflow to create a review-and-fix loop. Note: The starter kit is a generalized template of the process laid out in this post — it's not what these specific ports ran on.

##### 差距清单与质疑型审查者

> Gap inventory and skeptic reviewers

新语言与旧语言有着不同的、必须满足的要求。对于 Zig 到 Rust，差异在于手动内存管理（C 和 C++ 的工作方式相同）。例如：

> The new language has different requirements from the old language that must be met. For Zig to Rust the difference was manual memory management (C and C++ work the same way). For example:

Zig

> Zig

```plaintext
fn readConfig(allocator: std.mem.Allocator) ![]u8 {
    const buf = try allocator.alloc(u8, 1024);
    // ...fill buf...
    return buf; // 调用方必须释放它——但只有注释这么说
}

// 忘记写 'defer allocator.free(buf)' 的调用方仍然能编译通过——泄漏只在运行时才暴露。
```

> fn readConfig(allocator: std.mem.Allocator) ![]u8 {
>     const buf = try allocator.alloc(u8, 1024);
>     // ...fill buf...
>     return buf; // caller must free this — but only the comment says so
> }
> 
> // A caller that forgets 'defer allocator.free(buf)' still compiles — the leak only surfaces at runtime.

Rust

> Rust

```rust
fn read_config() -> Vec<u8> { 
let buf = vec![0u8; 1024]; 
// ...fill buf... 
buf // 所有权转移给调用方；内存被自动释放 
} 
// 移动之后还使用它？释放两次？两者都编译不过。 
// 忘记释放它？根本没有可供你忘记的释放调用——drop 是自动的。
```

> fn read_config() -> Vec<u8> {
> let buf = vec![0u8; 1024]; 
> // ...fill buf... 
> buf // ownership moves to the caller; memory is freed automatically 
> } 
> // Use it after it's moved? Free it twice? Neither compiles. 
> // Forget to free it? There's no free call to forget — drop is automatic.

对于 Python 到 TypeScript，差距在于接口和契约。Python 不要求声明它将接受什么形状的对象或返回什么，但 TypeScript 要求。例如：

> For Python to TypeScript the gap was interfaces and contracts. Python doesn’t require a contract declaring what shape of object it will accept or what it returns, but TypeScript does. For example:

Python

> Python

```python
def register(handler):
    handler.setup()
    return handler.run({"retries": 3})

# 任何带有 .setup() 和 .run() 的对象在这里都能用。实际传入的到底是哪些对象？读遍整个代码库才能知道。
```

> def register(handler):
>     handler.setup()
>     return handler.run({"retries": 3})
> 
> # Any object with .setup() and .run() works here. Which objects actually get passed in? Read the whole codebase to find out.

TypeScript

> TypeScript

```typescript
interface RunResult { ok: boolean } 

interface Handler 
{ setup(): void; 
run(opts: { retries: number }): Promise<RunResult>; 
} 

function register(handler: Handler): Promise<RunResult> { 
handler.setup(); 
return handler.run({ retries: 3 }); } 

// 在这段代码能通过编译之前，必须先把契约写下来
```

> interface RunResult { ok: boolean }
> 
> interface Handler 
> { setup(): void; 
> run(opts: { retries: number }): Promise<RunResult>; 
> } 
> 
> function register(handler: Handler): Promise<RunResult> { 
> handler.setup(); 
> return handler.run({ retries: 3 }); } 
> 
> // The contract must be written down before this compiles

Jarred 和 Mike 都创建了缺口清单（gap inventory）文件，用来捕捉这类隐含知识。Jarred 事先就把这些缺口盘点清楚，这也是我们在这里采用的做法；而 Mike 选择先翻译，再通过事后审计来创建缺口清单。你可能两种都需要做。

> Both Jarred and Mike created gap inventory files capturing this implicit knowledge. Jarred inventoried these gaps up front, which is what we do here, while Mike chose to translate first and then create the gap inventory by auditing afterwards. You may need to do both.

看看这个用于创建缺口清单文件的示例 [Claude Code 提示词](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/02-gap-inventory.md)。

> Check out this sample [Claude Code prompt to create a gap inventory file](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/02-gap-inventory.md).

#### 第 2 步——对规则进行压力测试

> Step 2 — Stress-test the rules

![Image 4](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a58fbe31db98b8b59d39ba8_MIgration-step2.jpeg)

这一步是一次小型迁移，作为大规模迁移前的“试航”。

> This step involves a mini-migration that serves as a “shakedown cruise” for the larger migration.

在这一步，Jarred 用一个智能体（agent）按规则手册翻译三个文件，用另一个智能体“像资深 Rust 工程师那样”翻译三个文件，再用一个智能体基于两者的差异来创建新的翻译规则。在这个阶段，他抓出了两个关键问题——如果它们扩散到全部 1,448 个文件，会引发大量麻烦。

> In this step, Jarred used one agent to translate three files using the rulebook, one agent to translate three files “like a senior Rust engineer,” and one agent to use the diff to create new translation rules. At this stage he caught two critical issues that would have created numerous issues if fanned out across all 1,448 files.

提示词大概长[这样](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/03-stress-test.md)。

> The prompt may look something like [this](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/03-stress-test.md).

这类压力测试只对保持结构的迁移有效，也就是同一个文件的两份译文可以逐行对比。如果你的规则手册是一次重新设计——像 Mike 那样——那么等价的测试就是用对抗性评审者直接攻击设计文档，然后用一次一次性的端到端运行来验证它。

> This type of stress test only works for structure-preserving migrations, where two translations of the same file are comparable line by line. If your rulebook is a redesign — like Mike's — the equivalent test is attacking the design document directly with adversarial reviewers, then validating it with a disposable end-to-end run.

无论如何，把翻译出来的文件全部丢掉。目标是打磨规则，而不是取得渐进式进展。

> Regardless, throw out any translated files. The goal is to refine the rules, not make incremental progress.

#### 第 3 步——翻译一切

> Step 3 — Translate everything

![Image 5](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a58fd9c8899de91189a89e0_ai-migation-step4-5-6.jpeg)

在余下的步骤中，你运行同一套多智能体循环架构：实现、评审、修复。

> For the remaining steps, you run the same multi-agent loop architecture: implement, review, and fix.

你可以把实现者的工作卸载给较小的模型，而让评审者继续用较大的模型。例如，Mike 在为主迁移扩展出 12 个子智能体时用的是 Claude Sonnet。

> You can offload implementer work to smaller models and keep reviewers on larger ones. For example, Mike used Claude Sonnet when he fanned out 12 subagents for the main migration.

工作队列应当是机械化的。一个批处理脚本通过检查翻译后的文件是否已存在于磁盘上来判断哪些已完成，然后把待处理文件切成一批批交给实现者智能体。由于队列每次都从磁盘重建，这个迁移在设计上就是可恢复的。

> The work queue should be mechanical. A batch script decides what’s done by checking whether the translated file exists on disk, then slices the pending files into batches for the implementer agents. Because the queue is rebuilt from disk every time, the migration is resumable by construction.

在这个阶段，智能体可能对自己该做多少工作过于谨慎。解决办法可以是一条直白而强硬的提示词指令，并附带上下文说明：编译器会在下一步抓出错误。

> At this stage, agents can be overly cautious with how much work they do. The fix can be a blunt, emphatic prompt instruction with context that the compiler will catch mistakes in the next step.

凡是翻译者无法有把握执行的地方，都用 // TODO(port): <reason> 标记出来，留到第 4 步处理。从这里开始，待办清单会自己写自己：编译器列举出错误，冒烟测试找出崩溃，测试套件报告失败。

> Anything the translator can’t execute confidently gets flagged with // TODO(port): <reason> to be dealt with in step 4. From here on, the to-do lists write themselves: the compiler enumerates the errors, the smoke tests find the crashes, the suite reports the failures.

两个对抗性评审者在各自独立的上下文中评估实现者的工作，评审者之间的分歧则交给第三个智能体裁定。当某个评审者反复在多个文件中抓到同一个错误时，修复方式不是逐文件的。你往规则手册里加一句话，然后重新生成受影响的那一批。规则手册在这一步中持续增长；代码从不针对它做手工打补丁。

> Two adversarial reviewers evaluate the work of the implementers using separate contexts and disagreement between reviewers goes to a third agent. When a reviewer keeps catching the same mistake across files, the fix isn't per-file. You add one sentence to the rulebook and regenerate the affected batch. The rulebook keeps growing through this step; the code never gets hand-patched against it.

这一步中一个值得注意的重要设计决策是编译器放在哪里。Mike 在每个循环内部都运行 TypeScript 编译器，因为它几秒钟就能检查一个单元。Jarred 则完全禁止在循环里用编译器，把它推迟到下一步，因为 cargo 要花好几分钟。

> One important design decision to note in this step is where the compiler sits. Mike ran the TypeScript compiler inside every loop, because it checks a unit in seconds. Jarred banned the compiler from the loop entirely and deferred it to the next step, because cargo takes minutes.

到了这一步，大部分繁重工作已经完成，[提示词开始变短。](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/04-translation-kickoff.md)

> At this step, much of the heavy lifting has been done and [the prompts start to get shorter.](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/prompts/04-translation-kickoff.md)

#### 第 4、5、6 步——编译、运行、对齐行为

> Steps 4, 5, 6 — Compile, run, and match behavior

![Image 6](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a58fd76153c143199b57e1b_ai-migration-step3.jpeg)

这三步共享同一套循环架构，且所需的人类判断逐步递减，因此我们放在一起讲。

> These three steps share the same loop architecture and need progressively less human judgment, so we cover them together.

例如，第 4 步往往会视迁移所用的语言和规模而并入第 3 步。

> Step 4, for example, may often dissolve into step 3 depending on the language and size of the migration.

视编译器这一步的规模和难度而定，智能体可能根本不运行它。Jarred 用一个编排脚本来执行这一步，该脚本在整个工作区上一次性调用编译器。随后“修复者智能体”在对抗性评审的配合下并行处理错误列表。构建再次运行，如此反复。

> Depending on the size and difficulty of the compiler step, agents may not run this at all. Jarred executed this with an orchestrator script that invoked the compiler once across the whole workspace. “Fixer agents” then ran through the error list in parallel with adversarial review. The build runs again, rinse and repeat.

审查错误列表有助于抓出可能需要调整的系统性问题。例如，Jarred 在修复了循环导入之后遇到了成千上万个 Rust 模块错误——这些错误此前被 Zig 的惰性编译所容忍。他通过编码一套逻辑来修复这个循环，用以判断该删除哪个依赖、移动哪个依赖，或重构边界。

> Reviewing the error list is helpful to catch systemic issues that may require adjustments. For example, Jarred ran into thousands of Rust module errors that surfaced after fixing cyclic imports that Zig's lazy compilation tolerated. He fixed the loop by encoding logic to classify which dependence to delete, move, or restructure the boundary.

第 5 步同样有一个类似编译器错误列表的机械化事实来源：冒烟测试产生的崩溃。同样地，循环的修复办法是把问题归类，在这里是按根因对成因分组，再交给对抗性子智能体评审。

> Step 5also has a mechanical source of truth similar to the compiler error list: crashes from the smoke test. Again, the loop fix was to group issues into categories, in this case grouping causes by root cause that are reviewed by adversarial subagents.

第 6 步，也是我们故事的结尾，是对比两套代码库中程序的行为。

> Step 6 and the end of our story is comparing the programs’ behavior across the two codebases.

我们的文件现在已经完成翻译、编译并通过冒烟测试（smoke test）。接下来该把它们分片，并用（前置阶段准备好的）测试套件对其运行。用"修复代理"（fixer agent）处理失败项，它们会对照两套代码库审查失败的测试。对抗性审查者则检查这些修复。

> Our files have now been translated, compiled, and smoke tested. Now it's time to shard them and run the test suite (from the prerequisite stage) against them. Tackle failures with "fixer agents" that review the failed tests against both codebases. Adversarial reviewers check their fixes.

这个循环的下一个阶段是一个[构建守护进程](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/scripts/build_daemon.sh)，它是唯一被允许重新构建二进制文件的进程。修复者编写补丁；守护进程将补丁批量处理，只重建一次，重新运行受影响的测试，并把结果反馈回来。这样就把最昂贵的操作串行化了，而不是让多个代理各自独立地触发它。

> The next stage in this loop is a [build daemon](https://github.com/anthropics/code-migration-kit-with-claude-code/blob/main/scripts/build_daemon.sh), which is the only process allowed to rebuild the binary. Fixers write patches; the daemon batches them, rebuilds once, re-runs the affected tests, and feeds the results back. This serializes the most expensive operation instead of letting multiple agents trigger it independently.

当同一个失败在许多测试中反复出现时，修复就要上移到上游：你修订产生该 bug 的规则，然后只重新生成该规则所涉及的文件。

> When the same failure repeats across many tests, the fix moves upstream: you amend the rule that produced the bug and regenerate only the files that rule touched.

Mike 的做法在这里很重要，因为很多开发者并没有一套现成或已移植的测试套件。Mike 让 Claude 创建了一个小脚本，用 7 个真实场景分别对新移植版本和原始 Python 代码库运行，并对结果做差异比对。每个失败的场景都分配了自己的修复代理，循环一直运行到七个场景全部通过。

> Mike's approach matters here, because many developers won't have a built-out or ported test suite. Mike had Claude create a small script to run 7 real-world scenarios against both the new port and the original Python codebase, and diffed the results. Each failing scenario got its own fix agent, and the loop ran until all seven passed.

然后他更进一步。Claude 设计了自己的端到端（end-to-end）测试套件，并在夜间自主运行，修复出问题的地方并重新运行，连续四个晚上如此。结果，它捕捉到了任何场景清单都无法预料到的小毛病。

> Then he went one step further. Claude designed its own end-to-end test suite and ran it autonomously overnight, fixing what broke and re-running four nights in a row. As a result, it caught the paper cuts no scenario list would have predicted.

这里的教训是，缺少测试套件并不会卡住这一步。如果你无法继承一个"裁判"，就让 Claude 造一个。无论哪种方式，你的原始代码库都是基准真相（ground truth）。

> The lesson is that a missing test suite doesn't block this step. If you can't inherit a referee, have Claude build one. Your original codebase is the ground truth either way.

### 代码迁移最佳实践

> Code migrations best practices

每一次运行都会教给我们上一次没能教会的东西。可以确定，你的下一次迁移也会教给你本指南无法涵盖的东西。但有几条实践在每个项目中都经受住了考验：

> Every run taught us something the previous one didn't. It’s a safe bet your next migration will teach you things this guide can't. But a few practices held up across every project:

- 不要盲目照搬本指南。每一次迁移都不一样。把它当作起点，在正式动手之前先和 Claude 一起规划你具体的迁移方案。
- 不要盯着单个失败。单个失败是循环该管的事。修复智能体（fixer agent）会逐个把它们清掉。你的注意力应该放在模式上。
- 让评审具有对抗性，让验证机械化。对抗性评审能支撑更长时间的任务运行，往往值得为此消耗 token。让脚本——编译器、diff、测试套件——来当裁判。
- 不要凡事都用最大的模型。token 消耗集中在你的循环里，所以要有意识地设计它们。较小的模型能很好地处理大批量的实现扇出（fan-out）；把最大的模型留给评审者，以及任何要编写规则供其他智能体遵循的场景。
- 把人力工时前置投入。规则手册和压力测试最耗时间。之后的一切基本上就是队列在逐步清空。
- 让工作队列机械化且可恢复。“完成”应当意味着“输出文件已存在于磁盘上”。

> • Don't follow this guide blindly. Each migration is different. Treat this as a starting point, and plan your specific migration with Claude before committing to it.
> • Don’t focus on individual failures. Individual failures are the loop's job. Fixer agents burn those down. Your attention belongs on the patterns.
> • Make review adversarial and verification mechanical. Adversarial review allows for longer running tasks and is often worth the token consumption. Let scripts — a compiler, a diff, a test suite — be the referee.
> • Don't use the largest model for everything. Token spend concentrates in your loops, so design them deliberately. Smaller models handle the high-volume implementation fan-out well; save your largest model for reviewers and for anything that writes rules other agents will follow.
> • Front-load the human hours. The rulebook and the stress test are the most time-consuming. Everything after is mostly queues burning down.
> • Make the work queue mechanical and resumable. Done should mean "the output file exists on disk."

### 审查循环的结果，而非代码

> Review loop results, not code

Jarred 的 Bun 迁移现已上线生产环境，尽管每次迁移都有取舍。例如，约 4% 的 Rust 代码位于 "unsafe" 块内，主要是 C/C++ 边界处的单行指针操作。

> Jarred’s Bun migration is now in production, although every migration has tradeoffs. For example, about 4% of the Rust code sits inside "unsafe" blocks, mostly single-line pointer operations at C/C++ boundaries.

但新代码库有可衡量的改进。团队工具能检测到的每一处内存泄漏都已修复：某项 2,000 次重复构建的基准测试，内存占用从 6,745 MB 降至 609 MB。二进制文件在 Linux 和 Windows 上缩小了 19%。跨语言优化使其在 HTTP 服务以及 next build、tsc 等真实工作负载上快了 2–5%。

> But the new codebase is measurably better. Every memory leak the team's tooling can detect has been fixed: one benchmark of 2,000 repeated builds dropped from 6,745 MB of memory to 609. The binary is 19% smaller on Linux and Windows. And cross-language optimization made it 2–5% faster across HTTP serving and real-world workloads like next build and tsc.

不妨考虑一下，是否到了该重新核算你那些长期搁置的迁移工作的时候了。挑一个你一直勉强忍受的代码库，问问 Claude 它的迁移过程会是什么样子。

> Consider whether it’s time to re-run the math of your long deferred migration. Pick the codebase you've been tolerating and ask Claude what the migration process looks like for it.

相关内容

> Related

- [迁移入门套件](https://github.com/anthropics/code-migration-kit-with-claude-code)注意：该入门套件是上述流程的通用化模板——并不是这些具体移植工作实际使用的东西。
- [代码现代化插件](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization)——用于遗留系统现代化和框架升级，而非语言移植
- [Claude Code 中的动态工作流](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)

> • [Migration starter kit](https://github.com/anthropics/code-migration-kit-with-claude-code)Note: The starter kit is a generalized template of the process above — it's not what these specific ports ran on.
> • [Code-modernization plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization)— for legacy modernization and framework upgrades rather than language ports
> • [Dynamic workflows in Claude Code](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)

‍

> ‍

## 术语对照

| English | 中文 |
|---|---|
| code migration | 代码迁移 |
| port | 移植 |
| AI agent | AI 智能体 |
| subagent | 子智能体 |
| test suite | 测试套件 |
| CI | 持续集成 |
| regression | 回归缺陷 |
| dynamic workflows | 动态工作流 |
| rulebook | 规则手册 |
| dependency map | 依赖图谱 |
| gap inventory | 缺口清单 |
| phase gate | 阶段闸门 |
| adversarial review | 对抗式评审 |
| parity check | 一致性核对 |
