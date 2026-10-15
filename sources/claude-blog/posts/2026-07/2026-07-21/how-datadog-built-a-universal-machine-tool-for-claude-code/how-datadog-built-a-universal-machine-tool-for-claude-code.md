# Datadog 如何为 Claude Code 打造一台“万能机床”

> How Datadog built a “universal machine tool” for Claude Code

> 来源：Claude Blog / Anthropic，2026-07-21
> 原文链接：https://claude.com/blog/how-datadog-built-a-universal-machine-tool-for-claude-code
> 分类：AI 工程 / 智能体软件工厂

## 核心要点

- Datadog 通往 Temper 的道路经过了 Courier、BitsEvolve 和 Helix 三个项目，每个项目都暴露出下一个项目要解决的瓶颈。
- Courier 是 2024 年完全手工构建、耗时一年的分布式队列系统，团队在代价高昂或难以逆转的部分采用了形式化建模和仿真来提高严谨程度。
- BitsEvolve 是闭环式进化优化框架，由多模型委员会生成代码变体，再由基准测试、测试和生产可观测性筛选，但其瓶颈在于反馈循环。
- Helix 是一个可与 Kafka 相媲美的流处理服务，主要由 Claude Code 在一人引导下几天内建成，影子运行显示有望将成本降至原来的二分之一到五分之一，但推向生产仍需更长时间的运维加固。
- Temper 让智能体产出规约而不是应用代码，内核验证规约后直接部署其描述的系统，从而消除经过验证的内容与实际运行内容之间的偏差。
- 每项能力由行为、数据契约和授权三份契约描述，其中授权采用默认拒绝、基于范围的审批，被拒请求经人工批准后热加载到策略引擎。
- 规约必须依次通过符号推理、穷举式状态探索、带种子故障注入的确定性模拟以及随机化属性测试四层验证才能被内核加载，小型规约的整个流程耗时远不到一秒。
- 在 Helix 黑灯工厂中，Temper 同时充当智能体控制平面、打通 Git、CI 和部署的工具构建层，以及驱动数据平面工作负载的 Helix 控制 API。
- 与控制逻辑分散在路由、数据库约束和服务代码中的常规 CRUD 应用不同，Temper 将隐含的状态机显式化为数据，编译在 LLM 之外完成，且修改无需经过 CI 即可热加载。
- Temper 的理念是让每个构件小到可以完整理解，借助智能体以较低成本实现以往只有航空和金融等高可靠性系统才负担得起的严谨程度。

## 正文

#### 通往 Temper 之路

> The road to Temper

机械化意味着智能体如今承担了更多工作。而工业化意味着工作变得可重复、可验证、可控制、可扩展。在 Datadog，这一切并非一蹴而就：通往 Temper 的道路经过了另外三个项目，即 Courier、BitsEvolve 和 Helix。每个项目都暴露出了下一个项目要解决的瓶颈，也让他们得以不断扩大自己的目标。

> Mechanization means agents are doing more of the work now. And industrialization means work becomes repeatable, verifiable, controllable, and scalable. At Datadog, this didn’t happen all at once: the path to Temper led through three other projects, Courier, BitsEvolve, and Helix. Each one exposed the bottleneck for the next, and enabled them to grow their ambition.

2024 年，他们推出了 [Courier](https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/)，这是一个分布式队列系统。他们完全手工、从零开始，花了一年时间才将其构建完成。

> In 2024, they introduced [Courier](https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/), a distributed queuing system. It took them one year to build completely by hand and from scratch.

“难点不在于构建各个部件，而在于让它们之间的交互变得可观测、可测试、可验证，”Sesh 说。“所以我们在形式化建模和仿真上非常严谨……找出那些一旦出错代价高昂或难以逆转的部分，并在[那些地方]提高了严谨程度。”

> “The difficulty was not building the parts; it was making the interactions between them observable, testable, and verifiable,” says Sesh. “So we were rigorous with formal modeling and simulation… identified the parts where mistakes would be expensive or hard to reverse, and raised the rigor [there].”

2025 年 9 月，他们构建了 [BitsEvolve](https://www.datadoghq.com/blog/engineering/self-optimizing-system/)，一个闭环式的进化优化框架。由多个模型组成的委员会生成代码变体，再由一连串[基准测试](https://www.datadoghq.com/blog/ai/production-grounded-code-optimization/)、测试和生产环境可观测性来决定哪些变体得以保留。

> In September 2025, they built [BitsEvolve](https://www.datadoghq.com/blog/engineering/self-optimizing-system/), a closed-loop evolutionary optimization harness. A council of models generates code variants. A cascade of [benchmarks](https://www.datadoghq.com/blog/ai/production-grounded-code-optimization/), tests, and production observability decides what survives.

“对我来说，这是第一次隐约意识到，软件的某些部分可以像生命体一样被培育——通过变异、反馈与适应而生长，”Sesh 说。

> “This was the first glimpse for me that parts of software could be cultivated like living organisms — grown through variation with feedback, and adaptation,” says Sesh.

问题在于：进化的效果取决于它所适应的环境，而 BitsEvolve 的瓶颈正是这个反馈循环。随后他们构建了 [Helix](https://www.datadoghq.com/blog/ai/fully-autonomous-optimization/)，一个可与 Kafka 相媲美的流处理服务。大部分构建工作由 Claude Code 完成，只需一名人员进行引导。

> The catch: evolution is only as good as the environment it adapts within, and BitsEvolve’s bottleneck was this feedback loop. Then they built [Helix](https://www.datadoghq.com/blog/ai/fully-autonomous-optimization/), a Kafka-comparable streaming service. Claude Code did most of the construction with one human steering it.

“令我们难以置信的是，短短几天内，我们就拥有了一个功能完备、可与 Kafka 相媲美的系统，”Sesh 说。“[它构建起来很快]，我们开始对它进行影子运行，并发现它有机会把成本降低到原来的二分之一到五分之一。”

> “To our disbelief, in a few days we had a fully functional Kafka comparable system,” says Sesh. “[It was quick to build] and we started shadowing it and we saw opportunities where it could be 2x to 5x cheaper.”

不过，要把它真正推向生产环境，还需要走更长的路：运维层面的加固只能靠时间积累、靠不止一个人的投入才能换来，而且目前仍在逐步推广之中。

> Getting it to production, though, took a lot more mileage: the operational hardening only earned over time and by more than one person and this is still in the process of rolling out.

“瓶颈再次转移了：智能体已经能够构建系统的大部分内容……但随后，人类仍然需要通过为人类打造的工具和机制进行协调，才能把这些工作交付到生产环境，”Sesh 说道。

> “The bottleneck moved again where agents could build large parts of the system…but then humans still have to coordinate to ship the work to production through tools and mechanisms built for humans,” says Sesh.

Datadog 需要一种方式，让智能体能够在经过验证、由策略驱动的运行时环境中构建自己的工具。这个运行时就是 [Temper](https://github.com/nerdsane/temper)。

> Datadog needed a way for agents to build their own tools in a verified, policy-driven runtime environment. That runtime was [Temper](https://github.com/nerdsane/temper).

#### 性情

> Temper

智能体生成代码的速度远超任何团队人工审查的速度，但它们也可能出错。

> Agents can produce code faster than any team can review by hand, but they can make mistakes.

在 Sesh 看来，智能体生成的内容与能够通过验证的内容之间的差距，正是失败模式不断累积的地方。然而，仅仅在传统代码库外面套一层智能体，只是把这当作吞吐量问题来处理，并没有真正弥合验证差距本身。

> For Sesh, that gap between what an agent generates and what passes verification is where the failure modes accumulate. However, simply wrapping an agent around a traditional codebase treats this as a throughput problem without closing the verification gap itself.

Temper 颠倒了这一等式：智能体不再产出应用代码，而是产出规约。内核读取每份规约，通过四层分析对其进行验证，然后部署该规约所描述的运行系统。由于规约既是被证明的产物，也是被执行的产物，因此经过验证的内容与实际运行的内容之间不存在偏差。

> Temper reverses this equation: instead of producing application code, agents produce specifications. The kernel reads each specification, verifies it through four layers of analysis, and deploys the running system the specification describes. Because the specification is both the artifact that gets proved and the artifact that gets executed, there is no drift between what was verified and what is running.

![](https://assets.claude.com/0bf277022a64a64601b56303d9cbf8c0a5243308.png)

“Temper 改变了系统的*重心*。智能体不再需要为每个局部需求不断发明彼此割裂的工具，而是生成精确的描述，作为对意图和问题域的规约。它是一种机床，就像夹具或数控机床一样——你向它们提供规格说明，比如螺纹需要加工成什么样。它具有极高的可重复性。你可以运行它们，并用它们制造飞机之类的复杂之物，”Sesh 说。

> “Temper changes the *center* of the system. The agent no longer needs to keep inventing disconnected tools for every local need. Instead, it produces precise descriptions as specifications of the intent and problem domain. It is a machine tool in the same sense that a jig or a CNC machine, where you give them specifications of what your screw threading needs to be. It's extremely repeatable. You can run them and you can build aircraft and complex things like that with them,” says Sesh.

因此在这种情况下，智能体不会每次都临时拼凑最终的机制。它可以先给出一份精确的描述，借助 Temper（或类似 Temper 的机制）反复迭代，先让东西跑通，之后再把它变成可重复、可检验、可复用的形式，这样你就真的可以围绕自己的代码库搭建一座软件工厂。

> So in this case, the agent does not improvise the final mechanism each time. It can produce a precise description and iterate with Temper (or a Temper-like mechanism) to make something work first and then later turn that into something repeatable, checkable and reusable so you could actually build a software factory around your code base.

每项能力都由三份契约来描述：

> Each capability is described by three contracts:

- **行为**：状态、状态转换、前置条件，以及必须成立的安全性质。
- **数据契约**：实体类型、其属性以及每种类型所支持的操作，以机器可解析的形式发布，使智能体无需文档即可发现完整的 API。
- **授权**：默认拒绝，基于范围（scope）的审批；被拒绝的请求会被记录为待决事项，由人工批准后热加载到策略引擎中。

> • **Behavior**: the states, the transitions, the preconditions, and the safety properties that must hold.
> • **Data contract**: the entity types, their properties, and the actions each type supports, published in machine-parseable form so an agent can discover the full API without documentation.
> • **Authorization**: default-deny, scope-based approval, with denials recorded as pending decisions a human can approve and hot-load into the policy engine.

每个规约都必须通过四个相互独立的层级，内核才会加载它。符号推理证明每个守卫条件都是可满足的，且每个不变式都是归纳性的。穷举式状态探索会遍历每一个可达状态。

> Every spec passes four independent layers before the kernel will load it. Symbolic reasoning proves each guard is satisfiable and each invariant is inductive. Exhaustive state exploration visits every reachable state.

确定性模拟会运行真实的生产代码路径，并以带种子的方式注入故障（丢包、延迟、乱序、崩溃），因此在相同种子下，故障可以被精确复现。

> Deterministic simulation runs the actual production code path with seeded fault injection — drops, delays, reordering, crashes — so failures reproduce exactly under the same seed.

随机化属性测试会运行约一千个伪随机动作序列，并将任何违例收缩为最小反例。对于一个小型规约，整个级联流程的运行时间远不到一秒。

> Randomized property testing runs about a thousand pseudorandom action sequences and shrinks any violation to a minimal counterexample. On a small spec, the whole cascade runs in well under a second.

#### Helix 的黑灯工厂

> The dark factory for Helix

Simon Willison 让“黑灯工厂”（dark factory）一词广为流行。它指的是这样一种软件流程：在虚拟的工厂车间里，智能体在无人值守的情况下持续工作。在 Helix 黑灯工厂中，Temper 扮演着三种角色。

> Simon Willison popularized the term dark factory, a software process where agents keep working without humans on the virtual factory floor. In the Helix dark factory, Temper plays three roles.

它是托管智能体的**智能体控制平面**——负责会话、角色、工作队列和生命周期。它是**工具构建**层，让智能体能够借助小型 Temper 应用打通 SDLC 工具链（Git、CI、部署）。它还是**Helix 控制 API**，即围绕数据平面、用于驱动工作负载运行的生命周期接口。

> It is the **agent control plane** for managed agents — sessions, roles, work queues, lifecycle. It is the **tool-builder** layer, letting agents bridge SDLC tooling (Git, CI, deployment) with small Temper apps. And it is the **Helix control API**, the lifecycle surface around the data plane that exercises the workload.

“令人意外的是，它开始显得比智能体基础设施更具通用性。如果眯起眼睛粗略地看，很多软件其实就是围绕数据库 API 的控制逻辑：状态、围绕变更的策略、生命周期转换，以及与外部系统的集成。从某种意义上说，Temper 可以是通用的，因为它可以应用于任何具有我所描述的这种形态的软件，”Sesh 说。

> “The surprise was it started to feel more general than agent infrastructure. A lot of software, if you squint, is just control logic around database APIs: state, policies around mutation, lifecycle transitions, integrations with external systems. Temper could be universal in a sense that it can be applied to any software that has the shape I described,” says Sesh.

#### 为什么不直接构建一个 CRUD 应用？

> Why not just build a CRUD app?

“Claude Code 可以非常出色地[用 TypeScript 或 Python 构建 CRUD 应用]。然而，在常规的 CRUD 应用中，控制逻辑分散在路由、数据库约束、服务代码、后台任务和文档之中。它或许拥有完善的测试和覆盖率，但其运行模式（通常表现为一个状态机）却隐含在代码库中，”Sesh 说道。

> “Claude Code can [build a CRUD app in TypeScript or Python] very well. However, in normal CRUD apps, the control logic is spread across routes, database constraints, service code, background jobs, and documentation. It may have good tests and coverage, but the operational mode, which generally takes the form of a state machine, is implicit in the codebase,” says Sesh.

“Temper 让这个状态机变得显式。智能体产出的是一份精确的描述，而不是任意代码。编译步骤在 LLM 之外完成，就像你把 Rust 代码交给 Rust 编译器一样。转换表是数据，而不是埋在服务方法里的面条式控制流。智能体可以动态地、安全地修改它，并且无需经过 CI 就能热加载，”他解释道。

> “Temper makes that state machine explicit. The agent produces a precise description, not arbitrary code. The compilation step is outside the LLM, the same way you hand Rust code to the Rust compiler. The transition table is data, not spaghetti control flow buried in service methods. Agents can change it dynamically, with safety, and hot-reload it without going through CI,” he explains.

#### 未来走向

> Where this is going

Temper 背后的理念是：每个构件都应当足够小，小到可以完整地装进你的脑子里。航空和金融系统等高可靠性软件几十年来一直是这样构建的，但在智能体出现之前，依靠人力达到这种严谨程度的成本太高，通用软件无法承受。

> The idea behind Temper is that each artifact should be small enough to fit in your head. High-assurance software like aviation and financial systems has been built this way for decades, but the cost of achieving that rigor with humans was too high for general software until agents entered the picture.

工业革命之所以成为可能，是因为机床让零件变得可组合、可检验、可替换，从而使我们能够制造出规模越来越大、结构越来越复杂的机器。

> The industrial revolution became possible because machine tools made parts composable, inspectable, and replaceable, so we could build ever-larger and more complex machines.

“如果智能体能够在工厂中以这样的纪律自主构建软件，或许我们不必止步于黑灯工厂。以这种方式构建的软件开始让人觉得像一个有机体，我们可以通过反馈、选择和适应来培育、栽培并推动它演化，”Sesh 说。

> “If agents can build software autonomously inside factories with this kind of discipline, maybe we don't need to stop at dark factories. Software built this way starts to feel like an organism we can grow, cultivate, and evolve through feedback, selection, and adaptation,” says Sesh.

| Datadog 团队的最佳实践 |
| --- |
| 你真正的瓶颈是生成，还是验证？ | 以验证为前提。智能体生成代码的速度早已超过任何团队的审查能力；已生成的内容与已被证明的内容之间的差距，正是各种失效模式不断累积的地方。应该把投入放在这里，而不是追求更高的吞吐量。 |
| 智能体究竟应该输出什么？ | 对控制逻辑（而非代码）使用规约，对任意代码采用携带证明的方式。将编译和证明放在 LLM 之外——把规约交给一个确定性内核，这样经过验证的产物就是实际运行的产物。 |
| 你的控制逻辑是显式的，还是散落在代码库各处？ | 把状态机从路由、服务方法和后台任务中抽离出来，将其转化为数据：一张智能体可以在策略约束下读取、修改并热加载的状态转换表。 |
| 人能否把每个产物都完整装进脑子里来理解？ | 如果做不到，你就又回到了原点。让每一块生成的内容都保持在足够小、能够推理清楚的范围内。 |

> 英文原表 / English original

| Best practices from the Datadog team |
| --- |
| Is your real bottleneck generation or verification? | Assume verification. Agents already produce code faster than any team can review; the gap between what's generated and what's proven is where the failure modes pile up. Invest there, not in more throughput. |
| What should the agent actually emit? | Specs for control logic (not code), and proof carrying for arbitrary code. Put compilation and proof outside the LLM — hand the spec to a deterministic kernel so the artifact that gets verified is the artifact that runs. |
| Is your control logic explicit, or scattered across the codebase? | Pull the state machine out of routes, service methods, and background jobs and make it data: a transition table an agent can read, modify, and hot-reload under policy. |
| Can a human hold each artifact in their head to comprehend? | If not, you're back where you started. Keep every generated piece small enough to reason about. |

*[观看完整分享](https://www.youtube.com/watch?v=EdmuYPBt_EM&list=PLmWCw1CzcFim2obQ-w3ohbULOfwp5lApR&index=9)，了解现场演示及更深入的讨论：Datadog 如何构建 Temper——一个受约束的框架，它将一次性的智能体工具转化为安全、可复用的组件，并在不同会话和团队之间持续累积价值。*

> *[Watch the full session](https://www.youtube.com/watch?v=EdmuYPBt_EM&list=PLmWCw1CzcFim2obQ-w3ohbULOfwp5lApR&index=9) for a live demo and deeper discussion of how Datadog built Temper, a constrained framework that turns one-off agent tools into secure, reusable components that compound across sessions and teams.*

‍

> ‍

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| Temper | Temper（运行时框架） | Datadog 构建的受约束运行时，读取并验证智能体产出的规约后部署对应的运行系统。 |
| Specification | 规约 | 对系统意图、状态与约束的精确描述，在 Temper 中既是被证明的产物也是被执行的产物。 |
| Dark Factory | 黑灯工厂 | 智能体在无人值守情况下持续完成软件生产工作的流程。 |
| Formal Modeling | 形式化建模 | 用数学化的精确模型描述系统行为，以便进行严格推理和验证。 |
| Evolutionary Optimization | 进化优化 | 通过生成变体并依据反馈筛选保留，从而迭代改进代码的方法。 |
| Shadow Run | 影子运行 | 让新系统与生产系统并行处理真实流量但不对外生效，用于验证其表现。 |
| Invariant | 不变式 | 在系统所有可达状态中都必须始终成立的性质。 |
| Guard Condition | 守卫条件 | 决定某个状态转换能否发生的前置判定条件。 |
| Exhaustive State Exploration | 穷举式状态探索 | 遍历系统每一个可达状态以检查性质是否被违反的验证方法。 |
| Deterministic Simulation | 确定性模拟 | 以固定种子注入故障运行真实代码路径，使故障场景可被精确复现。 |
| Property-Based Testing | 属性测试 | 生成大量随机输入序列检验性质是否成立，并将违例收缩为最小反例。 |
| Control Plane | 控制平面 | 负责管理会话、角色、工作队列和生命周期等协调逻辑的系统层。 |
| Data Plane | 数据平面 | 实际承载和处理业务数据流量的系统层。 |
| Hot Reload | 热加载 | 在系统不停机的情况下加载新的配置、策略或逻辑。 |
| State Machine | 状态机 | 由状态及其之间的转换规则构成、用于描述系统行为的模型。 |
