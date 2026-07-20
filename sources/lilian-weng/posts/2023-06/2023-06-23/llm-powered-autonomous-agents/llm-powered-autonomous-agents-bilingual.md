# LLM 驱动的自主智能体

> LLM Powered Autonomous Agents

> 来源：Lil'Log / Lilian Weng，2023-06-23
> 原文链接：https://lilianweng.github.io/posts/2023-06-23-agent/
> 分类：人工智能 / 大语言模型智能体

## 核心要点

- LLM作为核心控制器是构建自主智能体的关键概念，其潜力不仅限于内容生成，更在于作为强大的通用问题解决器。
- LLM驱动的自主智能体系统主要由规划、记忆和工具使用三个核心组件构成，以实现复杂任务处理。
- 规划组件通过任务分解（如思维链、思维树）和自我反思（如ReAct、Reflexion）机制，使智能体能够将大任务拆解并从错误中学习。
- 记忆组件包括短期记忆（上下文学习）和长期记忆（外部向量存储与快速检索），旨在克服LLM有限上下文窗口的限制。
- 工具使用组件通过调用外部API（如MRKL、HuggingGPT）显著扩展了LLM的能力，使其能够获取额外信息、执行代码或访问专有数据。
- 科学发现代理（如ChemCrow）和生成式代理模拟（如Generative Agents）等案例研究展示了LLM驱动智能体在特定领域和复杂交互环境中的应用。
- 当前LLM驱动智能体面临有限上下文长度、长期规划和任务分解挑战以及自然语言接口可靠性不足等局限性。
- 外部记忆的快速检索通常通过最大内积搜索（MIPS）实现，并利用近似最近邻（ANN）算法如LSH、ANNOY、HNSW、FAISS和ScaNN进行优化。
- 在需要深厚专业知识的领域，LLM评估自身表现的可靠性存疑，专家评估显示其可能无法准确判断任务结果的正确性。

## 正文

以LLM（大型语言模型）作为核心控制器来构建智能体是一个很酷的概念。一些概念验证演示，例如[AutoGPT](https://github.com/Significant-Gravitas/Auto-GPT)、[GPT-Engineer](https://github.com/AntonOsika/gpt-engineer)和[BabyAGI](https://github.com/yoheinakajima/babyagi)，都是鼓舞人心的例子。LLM的潜力不仅限于生成高质量的文案、故事、文章和程序；它还可以被视为一个强大的通用问题解决器。

> Building agents with LLM (large language model) as its core controller is a cool concept. Several proof-of-concepts demos, such as [AutoGPT](https://github.com/Significant-Gravitas/Auto-GPT), [GPT-Engineer](https://github.com/AntonOsika/gpt-engineer) and [BabyAGI](https://github.com/yoheinakajima/babyagi), serve as inspiring examples. The potentiality of LLM extends beyond generating well-written copies, stories, essays and programs; it can be framed as a powerful general problem solver.

### 智能体系统概述

> Agent System Overview

在LLM驱动的自主智能体系统中，LLM作为智能体的大脑，并辅以几个关键组件：

> In a LLM-powered autonomous agent system, LLM functions as the agent’s brain, complemented by several key components:

- **规划**


   - 子目标与分解：智能体将大型任务分解为更小、更易管理的子目标，从而实现对复杂任务的有效处理。
   - 反思与完善：智能体可以对过去的行为进行自我批评和自我反思，从错误中学习并为未来的步骤进行完善，从而提高最终结果的质量。
- **记忆**


   - 短期记忆：我将所有上下文学习（参见[提示工程](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/)）视为利用模型的短期记忆进行学习。
   - 长期记忆：这为智能体提供了在长时间内保留和回忆（无限）信息的能力，通常通过利用外部向量存储和快速检索来实现。
- **工具使用**


   - 智能体学习调用外部API以获取模型权重中缺失的额外信息（预训练后通常难以更改），包括当前信息、代码执行能力、访问专有信息源等。

> • **Planning**
>

> ◦ Subgoal and decomposition: The agent breaks down large tasks into smaller, manageable subgoals, enabling efficient handling of complex tasks.

> ◦ Reflection and refinement: The agent can do self-criticism and self-reflection over past actions, learn from mistakes and refine them for future steps, thereby improving the quality of final results.

> • **Memory**
>

> ◦ Short-term memory: I would consider all the in-context learning (See [Prompt Engineering](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/)) as utilizing short-term memory of the model to learn.

> ◦ Long-term memory: This provides the agent with the capability to retain and recall (infinite) information over extended periods, often by leveraging an external vector store and fast retrieval.

> • **Tool use**
>

> ◦ The agent learns to call external APIs for extra information that is missing from the model weights (often hard to change after pre-training), including current information, code execution capability, access to proprietary information sources and more.

![Overview of a LLM-powered autonomous agent system.](https://lilianweng.github.io/posts/2023-06-23-agent/agent-overview.png)

### 组件一：规划

> Component One: Planning

一项复杂的任务通常涉及许多步骤。智能体需要了解这些步骤并提前规划。

> A complicated task usually involves many steps. An agent needs to know what they are and plan ahead.

#### 任务分解

> Task Decomposition

[思维链](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/#chain-of-thought-cot)（CoT；[Wei et al. 2022](https://arxiv.org/abs/2201.11903)）已成为一种标准的提示技术，用于提高模型在复杂任务上的性能。模型被指示“一步一步地思考”，以利用更多的测试时计算将困难任务分解为更小、更简单的步骤。CoT将大型任务转化为多个可管理的任务，并揭示了模型思维过程的一种解释。

> [Chain of thought](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/#chain-of-thought-cot) (CoT; [Wei et al. 2022](https://arxiv.org/abs/2201.11903)) has become a standard prompting technique for enhancing model performance on complex tasks. The model is instructed to “think step by step” to utilize more test-time computation to decompose hard tasks into smaller and simpler steps. CoT transforms big tasks into multiple manageable tasks and shed lights into an interpretation of the model’s thinking process.

**思维树**（[Yao et al. 2023](https://arxiv.org/abs/2305.10601)）通过在每个步骤探索多种推理可能性来扩展CoT。它首先将问题分解为多个思维步骤，并在每个步骤生成多个想法，从而创建一个树状结构。搜索过程可以是BFS（广度优先搜索）或DFS（深度优先搜索），每个状态通过分类器（通过提示）或多数投票进行评估。

> **Tree of Thoughts** ([Yao et al. 2023](https://arxiv.org/abs/2305.10601)) extends CoT by exploring multiple reasoning possibilities at each step. It first decomposes the problem into multiple thought steps and generates multiple thoughts per step, creating a tree structure. The search process can be BFS (breadth-first search) or DFS (depth-first search) with each state evaluated by a classifier (via a prompt) or majority vote.

任务分解可以通过以下方式完成：(1) 通过LLM进行简单提示，例如`"Steps for XYZ.\n1."`、`"What are the subgoals for achieving XYZ?"`；(2) 使用特定任务的指令，例如`"Write a story outline."`用于撰写小说；或 (3) 结合人工输入。

> Task decomposition can be done (1) by LLM with simple prompting like `"Steps for XYZ.\n1."`, `"What are the subgoals for achieving XYZ?"`, (2) by using task-specific instructions; e.g. `"Write a story outline."` for writing a novel, or (3) with human inputs.

另一种截然不同的方法，**LLM+P**（[Liu et al. 2023](https://arxiv.org/abs/2304.11477)），涉及依赖外部经典规划器进行长周期规划。这种方法利用规划领域定义语言（PDDL）作为中间接口来描述规划问题。在此过程中，LLM (1) 将问题翻译成“问题PDDL”，然后 (2) 请求经典规划器根据现有的“领域PDDL”生成PDDL计划，最后 (3) 将PDDL计划翻译回自然语言。本质上，规划步骤被外包给外部工具，前提是存在特定领域的PDDL和合适的规划器，这在某些机器人设置中很常见，但在许多其他领域则不然。

> Another quite distinct approach, **LLM+P** ([Liu et al. 2023](https://arxiv.org/abs/2304.11477)), involves relying on an external classical planner to do long-horizon planning. This approach utilizes the Planning Domain Definition Language (PDDL) as an intermediate interface to describe the planning problem. In this process, LLM (1) translates the problem into “Problem PDDL”, then (2) requests a classical planner to generate a PDDL plan based on an existing “Domain PDDL”, and finally (3) translates the PDDL plan back into natural language. Essentially, the planning step is outsourced to an external tool, assuming the availability of domain-specific PDDL and a suitable planner which is common in certain robotic setups but not in many other domains.

#### 自我反思

> Self-Reflection

自省是一个至关重要的方面，它允许自主智能体通过改进过去的行动决策和纠正以前的错误来迭代改进。它在试错不可避免的现实世界任务中扮演着关键角色。

> Self-reflection is a vital aspect that allows autonomous agents to improve iteratively by refining past action decisions and correcting previous mistakes. It plays a crucial role in real-world tasks where trial and error are inevitable.

**ReAct** ([Yao et al. 2023](https://arxiv.org/abs/2210.03629)) 通过将行动空间扩展为任务特定的离散行动和语言空间的组合，将推理和行动整合到LLM中。前者使LLM能够与环境交互（例如，使用维基百科搜索API），而后者则促使LLM生成自然语言的推理轨迹。

> **ReAct** ([Yao et al. 2023](https://arxiv.org/abs/2210.03629)) integrates reasoning and acting within LLM by extending the action space to be a combination of task-specific discrete actions and the language space. The former enables LLM to interact with the environment (e.g. use Wikipedia search API), while the latter prompting LLM to generate reasoning traces in natural language.

ReAct 提示模板包含 LLM 思考的明确步骤，大致格式如下：

> The ReAct prompt template incorporates explicit steps for LLM to think, roughly formatted as:

```
Thought: ...
Action: ...
Observation: ...
... (Repeated many times)
```

![Examples of reasoning trajectories for knowledge-intensive tasks (e.g. HotpotQA, FEVER) and decision-making tasks (e.g. AlfWorld Env, WebShop). (Image source: Yao et al. 2023 ).](https://lilianweng.github.io/posts/2023-06-23-agent/react.png)

在知识密集型任务和决策任务的两次实验中，`ReAct`的表现优于`Act`的基线，其中`Thought: …`步骤被移除。

> In both experiments on knowledge-intensive tasks and decision-making tasks, `ReAct` works better than the `Act`-only baseline where `Thought: …` step is removed.

**Reflexion** ([Shinn & Labash 2023](https://arxiv.org/abs/2303.11366)) 是一个为智能体配备动态记忆和自我反思能力以提高推理技能的框架。Reflexion 采用标准的强化学习（RL）设置，其中奖励模型提供简单的二元奖励，并且动作空间遵循 ReAct 中的设置，即任务特定的动作空间通过语言进行增强以实现复杂的推理步骤。在每次动作 `a_t` 之后，智能体计算一个启发式 `h_t`，并可选择根据自我反思结果*决定重置*环境以开始新的试验。

英文原文：Reflexion ([Shinn & Labash 2023](https://arxiv.org/abs/2303.11366)) is a framework to equip agents with dynamic memory and self-reflection capabilities to improve reasoning skills. Reflexion has a standard RL setup, in which the reward model provides a simple binary reward and the action space follows the setup in ReAct where the task-specific action space is augmented with language to enable complex reasoning steps. After each action `a_t`, the agent computes a heuristic `h_t` and optionally may *decide to reset* the environment to start a new trial depending on the self-reflection results.

![Illustration of the Reflexion framework. (Image source: Shinn & Labash, 2023 )](https://lilianweng.github.io/posts/2023-06-23-agent/reflexion.png)

启发式函数决定了轨迹何时效率低下或包含幻觉，并应停止。效率低下的规划指的是耗时过长但未成功的轨迹。幻觉被定义为遇到一系列连续的相同动作，这些动作在环境中导致相同的观察结果。

> The heuristic function determines when the trajectory is inefficient or contains hallucination and should be stopped. Inefficient planning refers to trajectories that take too long without success. Hallucination is defined as encountering a sequence of consecutive identical actions that lead to the same observation in the environment.

通过向大型语言模型（LLM）展示两个少样本示例来创建自我反思，每个示例都是一对（失败的轨迹，用于指导未来计划更改的理想反思）。然后，这些反思被添加到智能体的工作记忆中，最多三个，用作查询大型语言模型的上下文。

> Self-reflection is created by showing two-shot examples to LLM and each example is a pair of (failed trajectory, ideal reflection for guiding future changes in the plan). Then reflections are added into the agent’s working memory, up to three, to be used as context for querying LLM.

![Experiments on AlfWorld Env and HotpotQA. Hallucination is a more common failure than inefficient planning in AlfWorld. (Image source: Shinn & Labash, 2023 )](https://lilianweng.github.io/posts/2023-06-23-agent/reflexion-exp.png)

**事后洞察链**（CoH；[Liu et al. 2023](https://arxiv.org/abs/2302.02676)）通过明确地向模型展示一系列过去的输出（每个输出都附有反馈）来鼓励模型改进其自身的输出。人类反馈数据是$D_h = \{(x, y_i , r_i , z_i)\}_{i=1}^n$的集合，其中`x`是提示，每个`y_i`是模型完成，`r_i`是`y_i`的人类评分，`z_i`是相应的人类提供的事后洞察反馈。假设反馈元组按奖励排序，$r_n \geq r_{n-1} \geq \dots \geq r_1$该过程是监督微调，其中数据是$\tau_h = (x, z_i, y_i, z_j, y_j, \dots, z_n, y_n)$形式的序列，其中$\leq i \leq j \leq n$。模型被微调为仅预测`y_n`，其中以序列前缀为条件，以便模型可以根据反馈序列进行自我反思以产生更好的输出。模型在测试时可以选择性地接收多轮带有人类标注者的指令。

英文原文：Chain of Hindsight (CoH; [Liu et al. 2023](https://arxiv.org/abs/2302.02676)) encourages the model to improve on its own outputs by explicitly presenting it with a sequence of past outputs, each annotated with feedback. Human feedback data is a collection of 

$D_h = \{(x, y_i , r_i , z_i)\}_{i=1}^n$, where `x` is the prompt, each `y_i` is a model completion, `r_i` is the human rating of `y_i`, and `z_i` is the corresponding human-provided hindsight feedback. Assume the feedback tuples are ranked by reward, 

$r_n \geq r_{n-1} \geq \dots \geq r_1$ The process is supervised fine-tuning where the data is a sequence in the form of 

$\tau_h = (x, z_i, y_i, z_j, y_j, \dots, z_n, y_n)$, where 

$\leq i \leq j \leq n$. The model is finetuned to only predict `y_n` where conditioned on the sequence prefix, such that the model can self-reflect to produce better output based on the feedback sequence. The model can optionally receive multiple rounds of instructions with human annotators at test time.

为了避免过拟合，CoH 添加了一个正则化项，以最大化预训练数据集的对数似然。为了避免捷径和复制（因为反馈序列中有很多常用词），他们在训练期间随机遮蔽 0% - 5% 的过去标记。

> To avoid overfitting, CoH adds a regularization term to maximize the log-likelihood of the pre-training dataset. To avoid shortcutting and copying (because there are many common words in feedback sequences), they randomly mask 0% - 5% of past tokens during training.

他们实验中的训练数据集是[WebGPT 比较](https://huggingface.co/datasets/openai/webgpt_comparisons)、[来自人类反馈的摘要](https://github.com/openai/summarize-from-feedback)和[人类偏好数据集](https://github.com/anthropics/hh-rlhf)的组合。

> The training dataset in their experiments is a combination of [WebGPT comparisons](https://huggingface.co/datasets/openai/webgpt_comparisons), [summarization from human feedback](https://github.com/openai/summarize-from-feedback) and [human preference dataset](https://github.com/anthropics/hh-rlhf).

![After fine-tuning with CoH, the model can follow instructions to produce outputs with incremental improvement in a sequence. (Image source: Liu et al. 2023 )](https://lilianweng.github.io/posts/2023-06-23-agent/CoH.png)

CoH 的思想是在上下文中呈现一系列逐步改进的输出历史，并训练模型以遵循这种趋势来生成更好的输出。**算法蒸馏**（AD；[Laskin et al. 2023](https://arxiv.org/abs/2210.14215)）将相同的思想应用于强化学习任务中的跨回合轨迹，其中一个*算法*被封装在一个长期的、历史条件策略中。考虑到智能体多次与环境交互，并且在每个回合中智能体都会有所改进，AD 将这种学习历史连接起来并输入到模型中。因此，我们应该期望下一个预测动作能够比之前的尝试带来更好的性能。目标是学习强化学习的过程，而不是训练一个特定于任务的策略本身。

> The idea of CoH is to present a history of sequentially improved outputs  in context and train the model to take on the trend to produce better outputs. **Algorithm Distillation** (AD; [Laskin et al. 2023](https://arxiv.org/abs/2210.14215)) applies the same idea to cross-episode trajectories in reinforcement learning tasks, where an *algorithm* is encapsulated in a long history-conditioned policy. Considering that an agent interacts with the environment many times and in each episode the agent gets a little better, AD concatenates this learning history and feeds that into the model. Hence we should expect the next predicted action to lead to better performance than previous trials. The goal is to learn the process of RL instead of training a task-specific policy itself.

![Illustration of how Algorithm Distillation (AD) works. (Image source: Laskin et al. 2023 ).](https://lilianweng.github.io/posts/2023-06-23-agent/algorithm-distillation.png)

该论文假设，任何生成一组学习历史的算法都可以通过对动作执行行为克隆来蒸馏成神经网络。历史数据由一组源策略生成，每个源策略都针对特定任务进行训练。在训练阶段，在每次强化学习运行时，都会采样一个随机任务，并使用多回合历史的子序列进行训练，从而使学习到的策略与任务无关。

> The paper hypothesizes that any algorithm that generates a set of learning histories can be distilled into a neural network by performing behavioral cloning over actions. The history data is generated by a set of source policies, each trained for a specific task. At the training stage, during each RL run, a random task is sampled and a subsequence of multi-episode history is used for training, such that the learned policy is task-agnostic.

实际上，模型的上下文窗口长度有限，因此剧集应足够短以构建多剧集历史。2-4个剧集的多剧集上下文对于学习接近最优的上下文强化学习算法是必要的。上下文强化学习的出现需要足够长的上下文。

> In reality, the model has limited context window length, so episodes should be short enough to construct multi-episode history. Multi-episodic contexts of 2-4 episodes are necessary to learn a near-optimal in-context RL algorithm. The emergence of in-context RL requires long enough context.

与三个基线进行比较，包括ED（专家蒸馏，使用专家轨迹而不是学习历史的行为克隆）、源策略（用于通过[UCB](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#upper-confidence-bounds)生成蒸馏轨迹）、RL^2（[Duan et al. 2017](https://arxiv.org/abs/1611.02779)；由于需要在线强化学习，因此用作上限），AD展示了上下文强化学习，其性能接近RL^2，尽管只使用了离线强化学习，并且比其他基线学习得快得多。当以源策略的部分训练历史为条件时，AD的改进速度也比ED基线快得多。

> In comparison with three baselines, including ED (expert distillation, behavior cloning with expert trajectories instead of learning history), source policy (used for generating trajectories for distillation by [UCB](https://lilianweng.github.io/posts/2018-01-23-multi-armed-bandit/#upper-confidence-bounds)), RL^2 ([Duan et al. 2017](https://arxiv.org/abs/1611.02779); used as upper bound since it needs online RL), AD demonstrates in-context RL with performance getting close to RL^2 despite only using offline RL and learns much faster than other baselines. When conditioned on partial training history of the source policy, AD also improves much faster than ED baseline.

![Comparison of AD, ED, source policy and RL^2 on environments that require memory and exploration. Only binary reward is assigned. The source policies are trained with A3C for "dark" environments and DQN for watermaze. (Image source: Laskin et al. 2023 )](https://lilianweng.github.io/posts/2023-06-23-agent/algorithm-distillation-results.png)

### 组件二：记忆

> Component Two: Memory

(非常感谢 ChatGPT 帮助我起草本节内容。在与 ChatGPT 的[对话](https://chat.openai.com/share/46ff149e-a4c7-4dd7-a800-fc4a642ea389)中，我学到了很多关于人脑和用于快速 MIPS 的数据结构知识。)

> (Big thank you to ChatGPT for helping me draft this section. I’ve learned a lot about the human brain and data structure for fast MIPS in my [conversations](https://chat.openai.com/share/46ff149e-a4c7-4dd7-a800-fc4a642ea389) with ChatGPT.)

#### 内存类型

> Types of Memory

记忆可以定义为获取、存储、保留和随后检索信息的各种过程。人类大脑中有几种不同类型的记忆。

> Memory can be defined as the processes used to acquire, store, retain, and later retrieve information. There are several types of memory in human brains.

1. **感觉记忆**：这是记忆的最早阶段，它提供了在原始刺激结束后保留感官信息（视觉、听觉等）印象的能力。感觉记忆通常只持续几秒钟。子类别包括图像记忆（视觉）、回声记忆（听觉）和触觉记忆（触觉）。
2. **短期记忆** (STM) 或 **工作记忆**：它存储我们当前意识到的信息，并且是执行学习和推理等复杂认知任务所必需的。短期记忆被认为具有大约 7 个项目的容量 ([Miller 1956](https://lilianweng.github.io/posts/2023-06-23-agent/psychclassics.yorku.ca/Miller/))，并持续 20-30 秒。
3. **长期记忆** (LTM)：长期记忆能够存储信息的时间非常长，从几天到几十年不等，并且存储容量几乎是无限的。长期记忆有两种子类型：
   - 外显/陈述性记忆：这是对事实和事件的记忆，指那些可以有意识地回忆起来的记忆，包括情景记忆（事件和经历）和语义记忆（事实和概念）。
   - 内隐/程序性记忆：这种类型的记忆是无意识的，涉及自动执行的技能和例行程序，例如骑自行车或在键盘上打字。

> • 
> **Sensory Memory**: This is the earliest stage of memory, providing the ability to retain impressions of sensory information (visual, auditory, etc) after the original stimuli have ended. Sensory memory typically only lasts for up to a few seconds. Subcategories include iconic memory (visual), echoic memory (auditory), and haptic memory (touch).

> • 
> **Short-Term Memory** (STM) or **Working Memory**: It stores information that we are currently aware of and needed to carry out complex cognitive tasks such as learning and reasoning. Short-term memory is believed to have the capacity of about 7 items ([Miller 1956](https://lilianweng.github.io/posts/2023-06-23-agent/psychclassics.yorku.ca/Miller/)) and lasts for 20-30 seconds.

> • 
> **Long-Term Memory** (LTM): Long-term memory can store information for a remarkably long time, ranging from a few days to decades, with an essentially unlimited storage capacity. There are two subtypes of LTM:
>

> ◦ Explicit / declarative memory: This is memory of facts and events, and refers to those memories that can be consciously recalled, including episodic memory (events and experiences) and semantic memory (facts and concepts).

> ◦ Implicit / procedural memory: This type of memory is unconscious and involves skills and routines that are performed automatically, like riding a bike or typing on a keyboard.

![Categorization of human memory.](https://lilianweng.github.io/posts/2023-06-23-agent/memory.png)

我们可以大致考虑以下映射：

> We can roughly consider the following mappings:

- 将感觉记忆视为学习原始输入（包括文本、图像或其他模态）的嵌入表示；
- 将短期记忆视为上下文学习。它是短暂且有限的，因为它受限于 Transformer 有限的上下文窗口长度。
- 将长期记忆视为代理在查询时可以关注的外部向量存储，可通过快速检索访问。

> • Sensory memory as learning embedding representations for raw inputs, including text, image or other modalities;
> • Short-term memory as in-context learning. It is short and finite, as it is restricted by the finite context window length of Transformer.
> • Long-term memory as the external vector store that the agent can attend to at query time, accessible via fast retrieval.

#### 最大内积搜索 (MIPS)

> Maximum Inner Product Search (MIPS)

外部记忆可以缓解有限注意力范围的限制。一种标准做法是将信息的嵌入表示保存到向量存储数据库中，该数据库支持快速最大内积搜索 ([MIPS](https://en.wikipedia.org/wiki/Maximum_inner-product_search))。为了优化检索速度，通常选择*近似最近邻 (ANN)*算法来返回大约前 k 个最近邻，以牺牲少量精度换取巨大的速度提升。

> The external memory can alleviate the restriction of finite attention span.  A standard practice is to save the embedding representation of information into a vector store database that can support fast maximum inner-product search ([MIPS](https://en.wikipedia.org/wiki/Maximum_inner-product_search)). To optimize the retrieval speed, the common choice is the *approximate nearest neighbors (ANN)​* algorithm to return approximately top k nearest neighbors to trade off a little accuracy lost for a huge speedup.

用于快速 MIPS 的几种常见 ANN 算法选择：

> A couple common choices of ANN algorithms for fast MIPS:

• [LSH](https://en.wikipedia.org/wiki/Locality-sensitive_hashing)（局部敏感哈希）：它引入了一个*哈希*函数，使得相似的输入项以高概率映射到相同的桶中，其中桶的数量远小于输入项的数量。

• [ANNOY](https://github.com/spotify/annoy)（近似最近邻，哦耶）：其核心数据结构是*随机投影树*，这是一组二叉树，其中每个非叶节点代表一个将输入空间一分为二的超平面，每个叶节点存储一个数据点。树是独立随机构建的，因此在某种程度上，它模仿了哈希函数。ANNOY 搜索在所有树中进行，迭代地搜索最接近查询的那一半，然后聚合结果。这个想法与 KD 树非常相关，但可扩展性更强。

• [HNSW](https://arxiv.org/abs/1603.09320)（分层可导航小世界）：它受到[小世界网络](https://en.wikipedia.org/wiki/Small-world_network)思想的启发，即大多数节点可以在少量步骤内到达任何其他节点；例如，社交网络的“六度分隔”特性。HNSW 构建这些小世界图的分层结构，其中底层包含实际数据点。中间层创建快捷方式以加快搜索速度。执行搜索时，HNSW 从顶层的一个随机节点开始，并导航到目标。当无法再接近时，它会向下移动到下一层，直到到达底层。上层中的每次移动都可能覆盖数据空间中的大距离，而下层中的每次移动都会提高搜索质量。

• [FAISS](https://github.com/facebookresearch/faiss)（Facebook AI 相似性搜索）：它基于这样的假设，即在高维空间中，节点之间的距离遵循高斯分布，因此应该存在数据点的*聚类*。FAISS 通过将向量空间划分为簇，然后在簇内细化量化来应用向量量化。搜索首先通过粗略量化寻找候选簇，然后通过更精细的量化进一步查看每个簇。

• [ScaNN](https://github.com/google-research/google-research/tree/master/scann)（可扩展最近邻）：ScaNN 的主要创新是*各向异性向量量化*。它将数据点 $x_i$ 量化为 $\tilde{x}_i$，使得内积 $\langle q, x_i \rangle$ 尽可能接近 $\angle q, \tilde{x}_i$ 的原始距离，而不是选择最近的量化质心点。

英文原文：

• [LSH](https://en.wikipedia.org/wiki/Locality-sensitive_hashing) (Locality-Sensitive Hashing): It introduces a *hashing* function such that similar input items are mapped to the same buckets with high probability, where the number of buckets is much smaller than the number of inputs.

• [ANNOY](https://github.com/spotify/annoy) (Approximate Nearest Neighbors Oh Yeah): The core data structure are *random projection trees*, a set of binary trees where each non-leaf node represents a hyperplane splitting the input space into half and each leaf stores one data point. Trees are built independently and at random, so to some extent, it mimics a hashing function. ANNOY search happens in all the trees to iteratively search through the half that is closest to the query and then aggregates the results. The idea is quite related to KD tree but a lot more scalable.

• [HNSW](https://arxiv.org/abs/1603.09320) (Hierarchical Navigable Small World): It is inspired by the idea of [small world networks](https://en.wikipedia.org/wiki/Small-world_network) where most nodes can be reached by any other nodes within a small number of steps; e.g. “six degrees of separation” feature of social networks. HNSW builds hierarchical layers of these small-world graphs, where the bottom layers contain the actual data points. The layers in the middle create shortcuts to speed up search. When performing a search, HNSW starts from a random node in the top layer and navigates towards the target. When it can’t get any closer, it moves down to the next layer, until it reaches the bottom layer. Each move in the upper layers can potentially cover a large distance in the data space, and each move in the lower layers refines the search quality.

• [FAISS](https://github.com/facebookresearch/faiss) (Facebook AI Similarity Search): It operates on the assumption that in high dimensional space, distances between nodes follow a Gaussian distribution and thus there should exist *clustering* of data points. FAISS applies vector quantization by partitioning the vector space into clusters and then refining the quantization within clusters. Search first looks for cluster candidates with coarse quantization and then further looks into each cluster with finer quantization.

• [ScaNN](https://github.com/google-research/google-research/tree/master/scann) (Scalable Nearest Neighbors): The main innovation in ScaNN is *anisotropic vector quantization*. It quantizes a data point $x_i$ to $\tilde{x}_i$ such that the inner product $\langle q, x_i \rangle$ is as similar to the original distance of $\angle q, \tilde{x}_i$ as possible, instead of picking the closet quantization centroid points.

![Comparison of MIPS algorithms, measured in recall@10. (Image source: Google Blog, 2020 )](https://lilianweng.github.io/posts/2023-06-23-agent/mips.png)

更多 MIPS 算法和性能比较请查看 [ann-benchmarks.com](https://ann-benchmarks.com/)。

> Check more MIPS algorithms and performance comparison in [ann-benchmarks.com](https://ann-benchmarks.com/).

### 组件三：工具使用

> Component Three: Tool Use

工具使用是人类一个显著而独特的特征。我们创造、修改和利用外部物体来做超出我们身体和认知极限的事情。为大型语言模型（LLM）配备外部工具可以显著扩展模型的能力。

> Tool use is a remarkable and distinguishing characteristic of human beings. We create, modify and utilize external objects to do things that go beyond our physical and cognitive limits. Equipping LLMs with external tools can significantly extend the model capabilities.

![A picture of a sea otter using rock to crack open a seashell, while floating in the water. While some other animals can use tools, the complexity is not comparable with humans. (Image source: Animals using tools )](https://lilianweng.github.io/posts/2023-06-23-agent/sea-otter.png)

**MRKL**（[Karpas 等人，2022](https://arxiv.org/abs/2205.00445)），是“模块化推理、知识和语言”的缩写，是一种用于自主代理的神经符号架构。MRKL 系统被提议包含一组“专家”模块，通用 LLM 作为路由器将查询路由到最合适的专家模块。这些模块可以是神经的（例如深度学习模型）或符号的（例如数学计算器、货币转换器、天气 API）。

> **MRKL** ([Karpas et al. 2022](https://arxiv.org/abs/2205.00445)), short for “Modular Reasoning, Knowledge and Language”, is a neuro-symbolic architecture for autonomous agents. A MRKL system is proposed to contain a collection of “expert” modules and the general-purpose LLM works as a router to route inquiries to the best suitable expert module. These modules can be neural (e.g. deep learning models) or symbolic (e.g. math calculator, currency converter, weather API).

他们进行了一项实验，通过算术作为测试用例，对 LLM 进行微调以调用计算器。他们的实验表明，解决口头数学问题比解决明确陈述的数学问题更困难，因为 LLM（7B Jurassic1-large 模型）未能可靠地提取基本算术的正确参数。结果强调，当外部符号工具可以可靠工作时，*知道何时以及如何使用这些工具至关重要*，这取决于 LLM 的能力。

> They did an experiment on fine-tuning LLM to call a calculator, using arithmetic as a test case. Their experiments showed that it was harder to solve verbal math problems than explicitly stated math problems because LLMs (7B Jurassic1-large model) failed to extract the right arguments for the basic arithmetic reliably. The results highlight when the external symbolic tools can work reliably, *knowing when to and how to use the tools are crucial*, determined by the LLM capability.

**TALM**（工具增强语言模型；[Parisi 等人，2022](https://arxiv.org/abs/2205.12255)）和**Toolformer**（[Schick 等人，2023](https://arxiv.org/abs/2302.04761)）都对语言模型（LM）进行微调，使其学习使用外部工具 API。数据集的扩展基于新添加的 API 调用注释是否能提高模型输出的质量。更多详情请参见提示工程的[“外部 API”部分](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/#external-apis)。

> Both **TALM** (Tool Augmented Language Models; [Parisi et al. 2022](https://arxiv.org/abs/2205.12255)) and **Toolformer** ([Schick et al. 2023](https://arxiv.org/abs/2302.04761)) fine-tune a LM to learn to use external tool APIs. The dataset is expanded based on whether a newly added API call annotation can improve the quality of model outputs. See more details in the [“External APIs” section](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/#external-apis) of Prompt Engineering.

ChatGPT [插件](https://openai.com/blog/chatgpt-plugins)和OpenAI API [函数调用](https://platform.openai.com/docs/guides/gpt/function-calling)是LLM增强工具使用能力在实践中应用的良好范例。工具API的集合可以由其他开发者提供（如插件），也可以是自定义的（如函数调用）。

> ChatGPT [Plugins](https://openai.com/blog/chatgpt-plugins) and OpenAI API  [function calling](https://platform.openai.com/docs/guides/gpt/function-calling) are good examples of LLMs augmented with tool use capability working in practice. The collection of tool APIs can be provided by other developers (as in Plugins) or self-defined (as in function calls).

**HuggingGPT** ([Shen 等人，2023](https://arxiv.org/abs/2303.17580)) 是一个框架，它使用ChatGPT作为任务规划器，根据模型描述选择HuggingFace平台上可用的模型，并根据执行结果总结响应。

> **HuggingGPT** ([Shen et al. 2023](https://arxiv.org/abs/2303.17580)) is a framework to use ChatGPT as the task planner to select models available in HuggingFace platform according to the model descriptions and summarize the response based on the execution results.

![Illustration of how HuggingGPT works. (Image source: Shen et al. 2023 )](https://lilianweng.github.io/posts/2023-06-23-agent/hugging-gpt.png)

该系统包含4个阶段：

> The system comprises of 4 stages:

**(1) 任务规划**：LLM作为大脑，将用户请求解析成多个任务。每个任务有四个相关属性：任务类型、ID、依赖项和参数。他们使用少样本示例来指导LLM进行任务解析和规划。

> **(1) Task planning**: LLM works as the brain and parses the user requests into multiple tasks. There are four attributes associated with each task: task type, ID, dependencies, and arguments. They use few-shot examples to guide LLM to do task parsing and planning.

指令：

> Instruction:

**(2) 模型选择**：LLM将任务分配给专家模型，其中请求被构造成一个多项选择题。LLM会收到一个模型列表供选择。由于上下文长度有限，需要基于任务类型进行过滤。

> **(2) Model selection**: LLM distributes the tasks to expert models, where the request is framed as a multiple-choice question. LLM is presented with a list of models to choose from. Due to the limited context length, task type based filtration is needed.

指令：

> Instruction:

**(3) 任务执行**：专家模型执行特定任务并记录结果。

> **(3) Task execution**: Expert models execute on the specific tasks and log results.

指令：

> Instruction:

**(4) 响应生成**：LLM接收执行结果并向用户提供总结性结果。

> **(4) Response generation**: LLM receives the execution results and provides summarized results to users.

要将HuggingGPT投入实际使用，需要解决几个挑战：(1) 需要提高效率，因为LLM推理轮次和与其他模型的交互都会减慢过程；(2) 它依赖于长上下文窗口来处理复杂的任务内容；(3) 需要提高LLM输出和外部模型服务的稳定性。

> To put HuggingGPT into real world usage, a couple challenges need to solve: (1) Efficiency improvement is needed as both LLM inference rounds and interactions with other models slow down the process; (2) It relies on a long context window to communicate over complicated task content; (3) Stability improvement of LLM outputs and external model services.

**API-Bank** ([Li 等人，2023](https://arxiv.org/abs/2304.08244)) 是一个用于评估工具增强型LLM性能的基准。它包含53个常用API工具、一个完整的工具增强型LLM工作流以及264个涉及568次API调用的带注释对话。API的选择非常多样化，包括搜索引擎、计算器、日历查询、智能家居控制、日程管理、健康数据管理、账户认证工作流等。由于API数量众多，LLM首先需要访问API搜索引擎来找到正确的API进行调用，然后使用相应的文档进行调用。

> **API-Bank** ([Li et al. 2023](https://arxiv.org/abs/2304.08244)) is a benchmark for evaluating the performance of tool-augmented LLMs. It contains 53 commonly used API tools, a complete tool-augmented LLM workflow, and 264 annotated dialogues that involve 568 API calls. The selection of APIs is quite diverse, including search engines, calculator, calendar queries, smart home control, schedule management, health data management, account authentication workflow and more. Because there are a large number of APIs, LLM first has access to API search engine to find the right API to call and then uses the corresponding documentation to make a call.

![Pseudo code of how LLM makes an API call in API-Bank. (Image source: Li et al. 2023 )](https://lilianweng.github.io/posts/2023-06-23-agent/api-bank-process.png)

在API-Bank工作流中，LLM需要做出一些决策，并且在每个步骤中我们都可以评估该决策的准确性。决策包括：

> In the API-Bank workflow, LLMs need to make a couple of decisions and at each step we can evaluate how accurate that decision is. Decisions include:

1. 是否需要进行API调用。
2. 识别要调用的正确API：如果不够好，LLM需要迭代地修改API输入（例如，为搜索引擎API决定搜索关键词）。
3. 基于API结果的响应：如果结果不满意，模型可以选择优化并再次调用。

> • Whether an API call is needed.
> • Identify the right API to call: if not good enough, LLMs need to iteratively modify the API inputs (e.g. deciding search keywords for Search Engine API).
> • Response based on the API results: the model can choose to refine and call again if results are not satisfied.

该基准从三个层面评估代理的工具使用能力：

> This benchmark evaluates the agent’s tool use capabilities at three levels:

- Level-1 评估*调用API*的能力。给定API的描述，模型需要判断是否调用给定API，正确调用它，并对API返回做出适当响应。
- Level-2 考察*检索API*的能力。模型需要搜索可能解决用户需求的API，并通过阅读文档学习如何使用它们。
- Level-3 评估*超越检索和调用的API规划*能力。给定不明确的用户请求（例如，安排团体会议，预订旅行的航班/酒店/餐厅），模型可能需要进行多次API调用来解决。

> • Level-1 evaluates the ability to *call the API*. Given an API’s description, the model needs to determine whether to call a given API, call it correctly, and respond properly to API returns.
> • Level-2 examines the ability to *retrieve the API*. The model needs to search for possible APIs that may solve the user’s requirement and learn how to use them by reading documentation.
> • Level-3 assesses the ability to *plan API beyond retrieve and call*. Given unclear user requests (e.g. schedule group meetings, book flight/hotel/restaurant for a trip), the model may have to conduct multiple API calls to solve it.

### 案例研究

> Case Studies

#### 科学发现代理

> Scientific Discovery Agent

**ChemCrow** ([Bran et al. 2023](https://arxiv.org/abs/2304.05376)) 是一个领域特定的示例，其中大型语言模型（LLM）通过13个专家设计的工具进行增强，以完成有机合成、药物发现和材料设计等任务。该工作流程在 [LangChain](https://github.com/hwchase17/langchain) 中实现，反映了先前在 [ReAct](https://lilianweng.github.io/posts/2023-06-23-agent/#react) 和 [MRKLs](https://lilianweng.github.io/posts/2023-06-23-agent/#mrkl) 中描述的内容，并将CoT推理与任务相关的工具相结合：

> **ChemCrow** ([Bran et al. 2023](https://arxiv.org/abs/2304.05376)) is a domain-specific example in which LLM is augmented with 13 expert-designed tools to accomplish tasks across organic synthesis, drug discovery, and materials design. The workflow, implemented in [LangChain](https://github.com/hwchase17/langchain), reflects what was previously described in the [ReAct](https://lilianweng.github.io/posts/2023-06-23-agent/#react) and [MRKLs](https://lilianweng.github.io/posts/2023-06-23-agent/#mrkl) and combines CoT reasoning with tools relevant to the tasks:

- 大型语言模型（LLM）会获得一份工具名称列表、其用途描述以及预期输入/输出的详细信息。
- 然后，它被指示在必要时使用提供的工具回答用户给出的提示。该指令建议模型遵循 ReAct 格式 - `Thought, Action, Action Input, Observation`。

> • The LLM is provided with a list of tool names, descriptions of their utility, and details about the expected input/output.
> • It is then instructed to answer a user-given prompt using the tools provided when necessary. The instruction suggests the model to follow the ReAct format - `Thought, Action, Action Input, Observation`.

一个有趣的观察是，虽然基于大型语言模型（LLM）的评估得出结论，GPT-4 和 ChemCrow 的表现几乎相当，但专家进行的人工评估（侧重于解决方案的完整性和化学正确性）表明，ChemCrow 大幅优于 GPT-4。这表明使用大型语言模型（LLM）评估其在需要深厚专业知识的领域中的自身表现可能存在问题。专业知识的缺乏可能导致大型语言模型（LLM）不了解自身的缺陷，从而无法很好地判断任务结果的正确性。

> One interesting observation is that while the LLM-based evaluation concluded that GPT-4 and ChemCrow perform nearly equivalently, human evaluations with experts oriented towards the completion and chemical correctness of the solutions showed that ChemCrow outperforms GPT-4 by a large margin. This indicates a potential problem with using LLM to evaluate its own performance on domains that requires deep expertise. The lack of expertise may cause LLMs not knowing its flaws and thus cannot well judge the correctness of task results.

[Boiko et al. (2023)](https://arxiv.org/abs/2304.05332) 也研究了由大型语言模型（LLM）赋能的科学发现智能体，以处理复杂科学实验的自主设计、规划和执行。该智能体可以使用工具浏览互联网、阅读文档、执行代码、调用机器人实验API并利用其他大型语言模型（LLM）。

> [Boiko et al. (2023)](https://arxiv.org/abs/2304.05332) also looked into LLM-empowered agents for scientific discovery, to handle autonomous design, planning, and performance of complex scientific experiments. This agent can use tools to browse the Internet, read documentation, execute code, call robotics experimentation APIs and leverage other LLMs.

例如，当被要求 `"develop a novel anticancer drug"` 时，模型提出了以下推理步骤：

> For example, when requested to `"develop a novel anticancer drug"`, the model came up with the following reasoning steps:

1. 询问了抗癌药物发现的当前趋势；
2. 选择了一个靶点；
3. 请求了一个针对这些化合物的支架；
4. 一旦化合物被识别，模型就尝试合成它。

> • inquired about current trends in anticancer drug discovery;
> • selected a target;
> • requested a scaffold targeting these compounds;
> • Once the compound was identified, the model attempted its synthesis.

他们还讨论了风险，特别是与非法药物和生物武器相关的风险。他们开发了一个测试集，其中包含已知化学武器制剂的列表，并要求代理合成它们。11个请求中有4个（36%）被接受以获得合成解决方案，并且代理尝试查阅文档来执行该程序。11个请求中有7个被拒绝，在这7个被拒绝的案例中，5个发生在网络搜索之后，而2个仅基于提示被拒绝。

> They also discussed the risks, especially with illicit drugs and bioweapons. They developed a test set containing a list of known chemical weapon agents and asked the agent to synthesize them. 4 out of 11 requests (36%) were accepted to obtain a synthesis solution and the agent attempted to consult documentation to execute the procedure. 7 out of 11 were rejected and among these 7 rejected cases, 5 happened after a Web search while 2 were rejected based on prompt only.

#### 生成式代理模拟

> Generative Agents Simulation

**生成式智能体** ([Park, et al. 2023](https://arxiv.org/abs/2304.03442)) 是一个超级有趣的实验，其中25个虚拟角色，每个都由一个LLM驱动的智能体控制，在一个受《模拟人生》启发的沙盒环境中生活和互动。生成式智能体为交互式应用创建了可信的人类行为模拟。

> **Generative Agents** ([Park, et al. 2023](https://arxiv.org/abs/2304.03442)) is super fun experiment where 25 virtual characters, each controlled by a LLM-powered agent, are living and interacting in a sandbox environment, inspired by The Sims. Generative agents create believable simulacra of human behavior for interactive applications.

生成式智能体的设计将LLM与记忆、规划和反思机制相结合，使智能体能够根据过去的经验行事，并与其他智能体互动。

> The design of generative agents combines LLM with memory, planning and reflection mechanisms to enable agents to behave conditioned on past experience, as well as to interact with other agents.

- **记忆**流：是一个长期记忆模块（外部数据库），以自然语言记录智能体经验的全面列表。


   - 每个元素都是一个*观察*，一个由智能体直接提供的事件。
   - 智能体间通信可以触发新的自然语言陈述。
- **检索**模型：根据相关性、新近度和重要性，呈现上下文以指导智能体的行为。


   - 新近度：最近发生的事件得分更高
   - 重要性：区分普通记忆和核心记忆。直接询问语言模型。
   - 相关性：基于其与当前情况/查询的关联程度。
- **反思**机制：随着时间的推移将记忆合成为更高层次的推论，并指导智能体的未来行为。它们是*对过去事件的更高层次的总结*（<- 请注意，这与上面提到的[自我反思](https://lilianweng.github.io/posts/2023-06-23-agent/#self-reflection)略有不同）


   - 用最近的100个观察结果提示语言模型，并根据一组观察/陈述生成3个最突出的高层次问题。然后要求语言模型回答这些问题。
- **规划与反应**：将反思和环境信息转化为行动


   - 规划本质上是为了优化当前时刻与时间上的可信度。
   - 提示模板：`{Intro of an agent X}. Here is X's plan today in broad strokes: 1)`
   - 代理之间的关系以及一个代理对另一个代理的观察都被纳入规划和反应的考虑范围。
   - 环境信息以树状结构呈现。

> • **Memory** stream: is a long-term memory module (external database) that records a comprehensive list of agents’ experience in natural language.
>

> ◦ Each element is an *observation*, an event directly provided by the agent.
> • Inter-agent communication can trigger new natural language statements.

> • **Retrieval** model: surfaces the context to inform the agent’s behavior, according to relevance, recency and importance.
>

> ◦ Recency: recent events have higher scores

> ◦ Importance: distinguish mundane from core memories. Ask LM directly.

> ◦ Relevance: based on how related it is to the current situation / query.

> • **Reflection** mechanism: synthesizes memories into higher level inferences over time and guides the agent’s future behavior. They are *higher-level summaries of past events* (<- note that this is a bit different from [self-reflection](https://lilianweng.github.io/posts/2023-06-23-agent/#self-reflection) above)
>

> ◦ Prompt LM with 100 most recent observations and to generate 3 most salient high-level questions given a set of observations/statements. Then ask LM to answer those questions.

> • **Planning & Reacting**: translate the reflections and the environment information into actions
>

> ◦ Planning is essentially in order to optimize believability at the moment vs in time.

> ◦ Prompt template: `{Intro of an agent X}. Here is X's plan today in broad strokes: 1)`

> ◦ Relationships between agents and observations of one agent by another are all taken into consideration for planning and reacting.

> ◦ Environment information is present in a tree structure.

![The generative agent architecture. (Image source: Park et al. 2023 )](https://lilianweng.github.io/posts/2023-06-23-agent/generative-agents.png)

这个有趣的模拟产生了涌现的社会行为，例如信息传播、关系记忆（例如两个代理继续同一个对话主题）以及社会事件的协调（例如举办派对并邀请许多其他人）。

> This fun simulation results in emergent social behavior, such as information diffusion, relationship memory (e.g. two agents continuing the conversation topic) and coordination of social events (e.g. host a party and invite many others).

#### 概念验证示例

> Proof-of-Concept Examples

[AutoGPT](https://github.com/Significant-Gravitas/Auto-GPT)引起了人们对使用大型语言模型（LLM）作为主要控制器来设置自主代理的可能性的广泛关注。鉴于其自然语言接口，它存在相当多的可靠性问题，但仍然是一个很酷的概念验证演示。AutoGPT中的许多代码都与格式解析有关。

> [AutoGPT](https://github.com/Significant-Gravitas/Auto-GPT) has drawn a lot of attention into the possibility of setting up autonomous agents with LLM as the main controller. It has quite a lot of reliability issues given the natural language interface, but nevertheless a cool proof-of-concept demo. A lot of code in AutoGPT is about format parsing.

以下是AutoGPT使用的系统消息，其中`{{...}}`是用户输入：

> Here is the system message used by AutoGPT, where `{{...}}` are user inputs:

```
You are {{ai-name}}, {{user-provided AI bot description}}.
Your decisions must always be made independently without seeking user assistance. Play to your strengths as an LLM and pursue simple strategies with no legal complications.

GOALS:

1. {{user-provided goal 1}}
2. {{user-provided goal 2}}
3. ...
4. ...
5. ...

Constraints:
1. ~4000 word limit for short term memory. Your short term memory is short, so immediately save important information to files.
2. If you are unsure how you previously did something or want to recall past events, thinking about similar events will help you remember.
3. No user assistance
4. Exclusively use the commands listed in double quotes e.g. "command name"
5. Use subprocesses for commands that will not terminate within a few minutes

Commands:
1. Google Search: "google", args: "input": "<search>"
2. Browse Website: "browse_website", args: "url": "<url>", "question": "<what_you_want_to_find_on_website>"
3. Start GPT Agent: "start_agent", args: "name": "<name>", "task": "<short_task_desc>", "prompt": "<prompt>"
4. Message GPT Agent: "message_agent", args: "key": "<key>", "message": "<message>"
5. List GPT Agents: "list_agents", args:
6. Delete GPT Agent: "delete_agent", args: "key": "<key>"
7. Clone Repository: "clone_repository", args: "repository_url": "<url>", "clone_path": "<directory>"
8. Write to file: "write_to_file", args: "file": "<file>", "text": "<text>"
9. Read file: "read_file", args: "file": "<file>"
10. Append to file: "append_to_file", args: "file": "<file>", "text": "<text>"
11. Delete file: "delete_file", args: "file": "<file>"
12. Search Files: "search_files", args: "directory": "<directory>"
13. Analyze Code: "analyze_code", args: "code": "<full_code_string>"
14. Get Improved Code: "improve_code", args: "suggestions": "<list_of_suggestions>", "code": "<full_code_string>"
15. Write Tests: "write_tests", args: "code": "<full_code_string>", "focus": "<list_of_focus_areas>"
16. Execute Python File: "execute_python_file", args: "file": "<file>"
17. Generate Image: "generate_image", args: "prompt": "<prompt>"
18. Send Tweet: "send_tweet", args: "text": "<text>"
19. Do Nothing: "do_nothing", args:
20. Task Complete (Shutdown): "task_complete", args: "reason": "<reason>"

Resources:
1. Internet access for searches and information gathering.
2. Long Term memory management.
3. GPT-3.5 powered Agents for delegation of simple tasks.
4. File output.

Performance Evaluation:
1. Continuously review and analyze your actions to ensure you are performing to the best of your abilities.
2. Constructively self-criticize your big-picture behavior constantly.
3. Reflect on past decisions and strategies to refine your approach.
4. Every command has a cost, so be smart and efficient. Aim to complete tasks in the least number of steps.

You should only respond in JSON format as described below
Response Format:
{
    "thoughts": {
        "text": "thought",
        "reasoning": "reasoning",
        "plan": "- short bulleted\n- list that conveys\n- long-term plan",
        "criticism": "constructive self-criticism",
        "speak": "thoughts summary to say to user"
    },
    "command": {
        "name": "command name",
        "args": {
            "arg name": "value"
        }
    }
}
Ensure the response can be parsed by Python json.loads
```

[GPT-Engineer](https://github.com/AntonOsika/gpt-engineer) 是另一个项目，旨在根据自然语言指定的任务创建整个代码仓库。GPT-Engineer 被指示思考要构建的较小组件列表，并根据需要请求用户输入以澄清问题。

> [GPT-Engineer](https://github.com/AntonOsika/gpt-engineer) is another project to create a whole repository of code given a task specified in natural language. The GPT-Engineer is instructed to think over a list of smaller components to build and ask for user input to clarify questions as needed.

以下是发送到 GPT-Engineer 使用的 OpenAI ChatCompletion 端点的任务澄清对话示例。用户输入被包裹在 `{{user input text}}` 中。

> Here are a sample conversation for task clarification sent to OpenAI ChatCompletion endpoint used by GPT-Engineer. The user inputs are wrapped in `{{user input text}}`.

```
[
  {
    "role": "system",
    "content": "You will read instructions and not carry them out, only seek to clarify them.\nSpecifically you will first summarise a list of super short bullets of areas that need clarification.\nThen you will pick one clarifying question, and wait for an answer from the user.\n"
  },
  {
    "role": "user",
    "content": "We are writing {{a Super Mario game in python. MVC components split in separate files. Keyboard control.}}\n"
  },
  {
    "role": "assistant",
    "content": "Summary of areas that need clarification:\n1. Specifics of the Super Mario game (e.g. level design, characters, gameplay mechanics)\n2. Details about the MVC components (e.g. which components are in each file)\n3. Keyboard control implementation (e.g. which keys to use, how to handle input)\n\nClarifying question:\nCan you provide more details about the Super Mario game, such as level design, characters, and gameplay mechanics?"
  },
  {
    "role": "user",
    "content": "{{There are 10 levels in total. The main character is a plumber named Mario, who can walk and jump. It is a classical platform game just like Super Mario. The main character moves from left to right, trying to get to the destination, where there are many obstacles and attacks from enemies in the process.}}\n\nIs anything else unclear? If yes, only answer in the form:\n{remaining unclear areas} remaining questions.\n{Next question}\nIf everything is sufficiently clear, only answer \"Nothing more to clarify.\"."
  },
  {
    "role": "assistant",
    "content": "Remaining unclear areas: 2 remaining questions.\nCan you provide more information about how the MVC components are split into separate files?"
  },
  {
    "role": "user",
    "content": "{{Make your own assumptions and state them explicitly before starting}}"
  }
]
```

在这些澄清之后，代理以不同的系统消息进入代码编写模式。系统消息：

> Then after these clarification, the agent moved into the code writing mode with a different system message.
> System message:

```LANG
CODE
```

对话示例：

> Conversatin samples:

```
[
  {
    "role": "system",
    "content": "You will get instructions for code to write.\nYou will write a very long answer. Make sure that every detail of the architecture is, in the end, implemented as code.\nMake sure that every detail of the architecture is, in the end, implemented as code.\n\nThink step by step and reason yourself to the right decisions to make sure we get it right.\nYou will first lay out the names of the core classes, functions, methods that will be necessary, as well as a quick comment on their purpose.\n\nThen you will output the content of each file including ALL code.\nEach file must strictly follow a markdown code block format, where the following tokens must be replaced such that\nFILENAME is the lowercase file name including the file extension,\nLANG is the markup code block language for the code's language, and CODE is the code:\n\nFILENAME\n```LANG\nCODE\n```\n\nYou will start with the \"entrypoint\" file, then go to the ones that are imported by that file, and so on.\nPlease note that the code should be fully functional. No placeholders.\n\nFollow a language and framework appropriate best practice file naming convention.\nMake sure that files contain all imports, types etc. Make sure that code in different files are compatible with each other.\nEnsure to implement all code, if you are unsure, write a plausible implementation.\nInclude module dependency or package manager dependency definition file.\nBefore you finish, double check that all parts of the architecture is present in the files.\n\nUseful to know:\nYou almost always put different classes in different files.\nFor Python, you always create an appropriate requirements.txt file.\nFor NodeJS, you always create an appropriate package.json file.\nYou always add a comment briefly describing the purpose of the function definition.\nYou try to add comments explaining very complex bits of logic.\nYou always follow the best practices for the requested languages in terms of describing the code written as a defined\npackage/project.\n\n\nPython toolbelt preferences:\n- pytest\n- dataclasses\n"
  },
 #  … same conversation as earlier, ended with "Make your own assumptions and state them explicitly before starting".
  {
    "role": "assistant",
    "content": "Assumptions:\n1. Model: The model will contain the game's data, such as level information, character states, and enemy positions.\n2. View: The view will handle the game's visuals, including rendering the game objects, backgrounds, and updating the display.\n3. Controller: The controller will manage user input, such as keyboard controls, and update the model accordingly.\n\nWith these assumptions in mind, is there any specific aspect of the keyboard control implementation you would like me to clarify?"
  },
  {
    "role": "user",
    "content": "Please now remember the steps:\n\nThink step by step and reason yourself to the right decisions to make sure we get it right.\nFirst lay out the names of the core classes, functions, methods that will be necessary, As well as a quick comment on their purpose.\n\nThen you will output the content of each file including ALL code.\nEach file must strictly follow a markdown code block format, where the following tokens must be replaced such that\nFILENAME is the lowercase file name including the file extension,\nLANG is the markup code block language for the code's language, and CODE is the code:\n\nFILENAME\n```LANG\nCODE\n```\n\nPlease note that the code should be fully functional. No placeholders.\n\nYou will start with the \"entrypoint\" file, then go to the ones that are imported by that file, and so on.\nFollow a language and framework appropriate best practice file naming convention.\nMake sure that files contain all imports, types etc. The code should be fully functional. Make sure that code in different files are compatible with each other.\nBefore you finish, double check that all parts of the architecture is present in the files.\n"
  }
]
```

### 挑战

> Challenges

在了解了构建以 LLM 为中心的代理的关键思想和演示之后，我开始看到一些常见的局限性：

> After going through key ideas and demos of building LLM-centered agents, I start to see a couple common limitations:

- **有限的上下文长度**：受限的上下文容量限制了历史信息、详细指令、API 调用上下文和响应的包含。系统设计必须在这种有限的通信带宽下工作，而像自我反思这样从过去的错误中学习的机制将极大地受益于长或无限的上下文窗口。尽管向量存储和检索可以提供对更大知识库的访问，但它们的表示能力不如完全注意力强大。
- **长期规划和任务分解的挑战**：在漫长的历史中进行规划以及有效探索解决方案空间仍然具有挑战性。大型语言模型在面对意外错误时难以调整计划，这使得它们与通过试错学习的人类相比，鲁棒性较差。
- **自然语言接口的可靠性**：当前的智能体系统依赖自然语言作为大型语言模型与外部组件（如记忆和工具）之间的接口。然而，模型输出的可靠性值得怀疑，因为大型语言模型可能会出现格式错误，并偶尔表现出反抗行为（例如拒绝遵循指令）。因此，许多智能体演示代码都专注于解析模型输出。

> • 
> **Finite context length**: The restricted context capacity limits the inclusion of historical information, detailed instructions, API call context, and responses. The design of the system has to work with this limited communication bandwidth, while mechanisms like self-reflection to learn from past mistakes would benefit a lot from long or infinite context windows. Although vector stores and retrieval can provide access to a larger knowledge pool, their representation power is not as powerful as full attention.
> • 
> **Challenges in long-term planning and task decomposition**: Planning over a lengthy history and effectively exploring the solution space remain challenging. LLMs struggle to adjust plans when faced with unexpected errors, making them less robust compared to humans who learn from trial and error.
> • 
> **Reliability of natural language interface**: Current agent system relies on natural language as an interface between LLMs and external components such as memory and tools. However, the reliability of model outputs is questionable, as LLMs may make formatting errors and occasionally exhibit rebellious behavior (e.g. refuse to follow an instruction). Consequently, much of the agent demo code focuses on parsing model output.

### 引用

> Citation

引用方式：

> Cited as:

> Weng, Lilian. (2023年6月). “LLM-powered Autonomous Agents”. Lil’Log. https://lilianweng.github.io/posts/2023-06-23-agent/.

> Weng, Lilian. (Jun 2023). “LLM-powered Autonomous Agents”. Lil’Log. https://lilianweng.github.io/posts/2023-06-23-agent/.

或

> Or

```
@article{weng2023agent,
  title   = "LLM-powered Autonomous Agents",
  author  = "Weng, Lilian",
  journal = "lilianweng.github.io",
  year    = "2023",
  month   = "Jun",
  url     = "https://lilianweng.github.io/posts/2023-06-23-agent/"
}
```

### 参考文献

> References

[1] Wei 等人。 [“Chain of thought prompting elicits reasoning in large language models.”](https://arxiv.org/abs/2201.11903) NeurIPS 2022

> [1] Wei et al. [“Chain of thought prompting elicits reasoning in large language models.”](https://arxiv.org/abs/2201.11903) NeurIPS 2022

[2] Yao 等人。 [“Tree of Thoughts: Dliberate Problem Solving with Large Language Models.”](https://arxiv.org/abs/2305.10601) arXiv 预印本 arXiv:2305.10601 (2023)。

> [2] Yao et al. [“Tree of Thoughts: Dliberate Problem Solving with Large Language Models.”](https://arxiv.org/abs/2305.10601) arXiv preprint arXiv:2305.10601 (2023).

[3] Liu 等人。 [“Chain of Hindsight Aligns Language Models with Feedback “](https://arxiv.org/abs/2302.02676) arXiv 预印本 arXiv:2302.02676 (2023)。

> [3] Liu et al. [“Chain of Hindsight Aligns Language Models with Feedback
> “](https://arxiv.org/abs/2302.02676) arXiv preprint arXiv:2302.02676 (2023).

[4] Liu 等人。 [“LLM+P: Empowering Large Language Models with Optimal Planning Proficiency”](https://arxiv.org/abs/2304.11477) arXiv 预印本 arXiv:2304.11477 (2023)。

> [4] Liu et al. [“LLM+P: Empowering Large Language Models with Optimal Planning Proficiency”](https://arxiv.org/abs/2304.11477) arXiv preprint arXiv:2304.11477 (2023).

[5] Yao 等人。 [“ReAct: Synergizing reasoning and acting in language models.”](https://arxiv.org/abs/2210.03629) ICLR 2023。

> [5] Yao et al. [“ReAct: Synergizing reasoning and acting in language models.”](https://arxiv.org/abs/2210.03629) ICLR 2023.

[6] Google Blog. [“发布 ScaNN：高效向量相似性搜索”](https://ai.googleblog.com/2020/07/announcing-scann-efficient-vector.html) 2020年7月28日。

> [6] Google Blog. [“Announcing ScaNN: Efficient Vector Similarity Search”](https://ai.googleblog.com/2020/07/announcing-scann-efficient-vector.html) July 28, 2020.

[7] [https://chat.openai.com/share/46ff149e-a4c7-4dd7-a800-fc4a642ea89](https://chat.openai.com/share/46ff149e-a4c7-4dd7-a800-fc4a642ea389)

> [7] [https://chat.openai.com/share/46ff149e-a4c7-4dd7-a800-fc4a642ea389](https://chat.openai.com/share/46ff149e-a4c7-4dd7-a800-fc4a642ea389)

[8] Shinn & Labash. [“Reflexion：一个具有动态记忆和自我反思的自主智能体”](https://arxiv.org/abs/2303.11366) arXiv preprint arXiv:2303.11366 (2023)。

> [8] Shinn & Labash. [“Reflexion: an autonomous agent with dynamic memory and self-reflection”](https://arxiv.org/abs/2303.11366) arXiv preprint arXiv:2303.11366 (2023).

[9] Laskin et al. [“基于上下文的算法蒸馏强化学习”](https://arxiv.org/abs/2210.14215) ICLR 2023。

> [9] Laskin et al. [“In-context Reinforcement Learning with Algorithm Distillation”](https://arxiv.org/abs/2210.14215) ICLR 2023.

[10] Karpas et al. [“MRKL 系统：一种结合了大型语言模型、外部知识源和离散推理的模块化神经符号架构。”](https://arxiv.org/abs/2205.00445) arXiv preprint arXiv:2205.00445 (2022)。

> [10] Karpas et al. [“MRKL Systems A modular, neuro-symbolic architecture that combines large language models, external knowledge sources and discrete reasoning.”](https://arxiv.org/abs/2205.00445) arXiv preprint arXiv:2205.00445 (2022).

[11] Nakano et al. [“Webgpt：浏览器辅助的带有人类反馈的问答系统。”](https://arxiv.org/abs/2112.09332) arXiv preprint arXiv:2112.09332 (2021)。

> [11] Nakano et al. [“Webgpt: Browser-assisted question-answering with human feedback.”](https://arxiv.org/abs/2112.09332) arXiv preprint arXiv:2112.09332 (2021).

[12] Parisi et al. [“TALM：工具增强型语言模型”](https://arxiv.org/abs/2205.12255)

> [12] Parisi et al. [“TALM: Tool Augmented Language Models”](https://arxiv.org/abs/2205.12255)

[13] Schick et al. [“Toolformer：语言模型可以自学使用工具。”](https://arxiv.org/abs/2302.04761) arXiv preprint arXiv:2302.04761 (2023)。

> [13] Schick et al. [“Toolformer: Language Models Can Teach Themselves to Use Tools.”](https://arxiv.org/abs/2302.04761) arXiv preprint arXiv:2302.04761 (2023).

[14] Weaviate Blog. [为什么向量搜索如此之快？](https://weaviate.io/blog/why-is-vector-search-so-fast) 2022年9月13日。

> [14] Weaviate Blog. [Why is Vector Search so fast?](https://weaviate.io/blog/why-is-vector-search-so-fast) Sep 13, 2022.

[15] Li et al. [“API-Bank：工具增强型大型语言模型的基准”](https://arxiv.org/abs/2304.08244) arXiv preprint arXiv:2304.08244 (2023)。

> [15] Li et al. [“API-Bank: A Benchmark for Tool-Augmented LLMs”](https://arxiv.org/abs/2304.08244) arXiv preprint arXiv:2304.08244 (2023).

[16] Shen et al. [“HuggingGPT：利用 ChatGPT 及其 HuggingFace 伙伴解决 AI 任务”](https://arxiv.org/abs/2303.17580) arXiv preprint arXiv:2303.17580 (2023)。

> [16] Shen et al. [“HuggingGPT: Solving AI Tasks with ChatGPT and its Friends in HuggingFace”](https://arxiv.org/abs/2303.17580) arXiv preprint arXiv:2303.17580 (2023).

[17] Bran et al. [“ChemCrow：用化学工具增强大型语言模型。”](https://arxiv.org/abs/2304.05376) arXiv preprint arXiv:2304.05376 (2023)。

> [17] Bran et al. [“ChemCrow: Augmenting large-language models with chemistry tools.”](https://arxiv.org/abs/2304.05376) arXiv preprint arXiv:2304.05376 (2023).

[18] Boiko et al. [“大型语言模型涌现的自主科学研究能力。”](https://arxiv.org/abs/2304.05332) arXiv preprint arXiv:2304.05332 (2023)。

> [18] Boiko et al. [“Emergent autonomous scientific research capabilities of large language models.”](https://arxiv.org/abs/2304.05332) arXiv preprint arXiv:2304.05332 (2023).

[19] Joon Sung Park, et al. [“生成式智能体：人类行为的交互式模拟。”](https://arxiv.org/abs/2304.03442) arXiv preprint arXiv:2304.03442 (2023)。

> [19] Joon Sung Park, et al. [“Generative Agents: Interactive Simulacra of Human Behavior.”](https://arxiv.org/abs/2304.03442) arXiv preprint arXiv:2304.03442 (2023).

[20] AutoGPT. [https://github.com/Significant-Gravitas/Auto-GPT](https://github.com/Significant-Gravitas/Auto-GPT)

> [20] AutoGPT. [https://github.com/Significant-Gravitas/Auto-GPT](https://github.com/Significant-Gravitas/Auto-GPT)

[21] GPT-Engineer. [https://github.com/AntonOsika/gpt-engineer](https://github.com/AntonOsika/gpt-engineer)

> [21] GPT-Engineer. [https://github.com/AntonOsika/gpt-engineer](https://github.com/AntonOsika/gpt-engineer)

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| LLM (Large Language Model) | 大型语言模型 | 一种基于深度学习的语言模型，拥有大量参数，能够理解、生成和处理人类语言。 |
| Autonomous Agent | 自主智能体 | 能够独立感知环境、规划行动并执行任务，以实现特定目标的系统。 |
| Chain of Thought (CoT) | 思维链 | 一种提示技术，通过引导模型“一步一步地思考”来分解复杂任务，提高推理能力。 |
| Tree of Thoughts | 思维树 | 扩展思维链，通过在每个步骤探索多种推理可能性并生成多个想法，形成树状结构进行搜索。 |
| ReAct | ReAct (推理与行动) | 一种将推理和行动整合到LLM中的框架，通过任务特定的离散行动和语言空间与环境交互。 |
| Reflexion | Reflexion (反思) | 一种为智能体配备动态记忆和自我反思能力的框架，通过学习过去的错误来提高推理技能。 |
| Algorithm Distillation (AD) | 算法蒸馏 | 将强化学习任务中的跨回合学习历史封装到长期策略中，以学习强化学习过程本身。 |
| Short-term Memory (STM) | 短期记忆 | 存储当前意识到的信息，容量有限且持续时间短，在LLM中常指上下文学习。 |
| Long-term Memory (LTM) | 长期记忆 | 能够长时间存储大量信息，在LLM中通常通过外部向量存储和快速检索实现。 |
| Maximum Inner Product Search (MIPS) | 最大内积搜索 | 一种在向量空间中查找与查询向量内积最大的数据点的方法，常用于信息检索。 |
| Approximate Nearest Neighbor (ANN) | 近似最近邻 | 一类算法，通过牺牲少量精度来大幅提高在高维空间中查找最近邻的速度。 |
| Locality-Sensitive Hashing (LSH) | 局部敏感哈希 | 一种ANN算法，通过哈希函数将相似的输入项以高概率映射到相同的桶中。 |
| HNSW (Hierarchical Navigable Small World) | 分层可导航小世界 | 一种ANN算法，构建分层图结构，利用小世界网络特性实现高效的近似最近邻搜索。 |
| Tool Use | 工具使用 | 智能体调用外部API或模块以获取模型权重中缺失的信息或执行特定任务的能力。 |
| MRKL (Modular Reasoning, Knowledge and Language) | MRKL系统 (模块化推理、知识和语言) | 一种神经符号架构，通用LLM作为路由器将查询路由到最合适的专家模块（神经或符号）。 |
