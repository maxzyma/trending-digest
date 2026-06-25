---
source: claude-blog
source_url: https://claude.com/blog/meet-the-winners-of-our-claude-opus-4-8-build-day-hackathon
published_at: 2026-06-17
category: Claude Code
title_en: Meet the winners of our Claude Opus 4.8 Build Day hackathon
title_zh: 来认识我们 Claude Opus 4.8 Build Day 黑客松的获奖者
source_intro_paragraphs: 3
source_image_count: 3
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/amweZ92PV6vZ0PNQFM3O1bX7VxEKBD6p"
---

# 来认识我们 Claude Opus 4.8 Build Day 黑客松的获奖者

> 来源：Claude Blog，2026-06-17
> 原文链接：https://claude.com/blog/meet-the-winners-of-our-claude-opus-4-8-build-day-hackathon
> 分类：Claude Code

## 导语

从重建唐代建筑，到对一座合成的旧金山进行民意调查，来看看在我们最新一届黑客松上，获奖者们如何用 Claude Opus 4.8 在一天之内造出他们的作品。

## 核心要点

- 6 月 13 日，超过 300 名创业者与开发者齐聚旧金山，参加为期 12 小时、以 Claude Opus 4.8 为主题的黑客松；1500 多人报名，310 人参与，每人获得 500 美元额度。
- 一等奖 Tekton：将历史木结构建筑重建为 3D 模型，并把每个部件追溯到有据可查的来源，全程在 Opus 4.8 上完成验证。
- 二等奖 Sim Francisco：基于美国人口普查数据构建的 1 万名合成居民的旧金山人口模型，可对整个合成选民群体进行实时民意调查。
- 三等奖 Custom Universe：用手机拍一张照片即可生成可放入场景、可重新风格化的 3D 物体，面向机器人实验室的合成数据需求。
- 三支队伍均计划开源或免费提供其项目，分别面向文化保护、模型训练与机器人研究。
- 各队的共同经验：先规划整个项目再动手、不要止步于第一个可行方案、用 Claude 来选择工具而不仅仅是写代码。

## 中文译文

6 月 13 日，我们把 300 多名创业者和开发者带到旧金山，参加一场为期 12 小时、围绕 Claude Opus 4.8 的黑客松。报名人数超过 1500 人，最终 310 人参与，许多人从世界各地赶来，每人拥有 500 美元额度和一天时间，把一个想法变成可运行的演示。

我们与三支获奖队伍聊了聊他们造了什么，以及如何用 Claude 做到这一点。

恭喜获奖者以及所有参与者。我们希望他们的项目能给你带来一些灵感。

### 一等奖：Tekton，Holly Tang 与 Austin Burgess

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a32e20130b0c237d85e1c09_Claude_Build_Day_258_compressed.jpg)

当一座历史悠久的木结构建筑被烧毁时，数个世纪的工艺也可能随之消失。Tekton 以 3D 形式重建这些建筑，并把每一个部件都追溯到有据可查的来源。

给 Tekton 一座历史建筑，Claude 便会对其展开研究，汇集示意图、施工文档、照片和图解，然后跨越 339 个递进的建造状态组装出一个 3D 模型。当你点击模型中的任意组件时，Tekton 会显示该细节的来源以及它为何被放置在那里。团队把这称为证据链（evidence chain），从源材料一直延伸到经过验证的模型。他们为学术验证、修复工作和文化保护而打造此项目，从唐代建筑和巴黎圣母院（Notre-Dame）的尖塔入手。

验证过程完全运行在 Opus 4.8 上。独立的验证子智能体（verifier sub-agents）在隔离的上下文窗口中对每次重建进行评分，自我纠正循环则反复核查组件的放置，直到全部 20 项测试通过。每一次构建都对照历史记录及其引用进行衡量，因此最终模型遵循该结构最初建造时所记录的规则。

Holly Tang 和 Austin Burgess 是一个月前认识的，当时他们正在 Code with Claude 活动上排队买咖啡。Holly 是一名设计师，一直在帮助 Austin 的创业公司 Pearl。"我喜欢看纪录片，每次看到美丽的建筑毁于火灾都让我难过，"Holly 说。她曾独自做过一次重建的原型；Austin 的贡献则是把它扩展到能端到端地适用于任何建筑。

为了打造 Tekton，两人分阶段推进：先让巴黎圣母院的尖塔在合理规模上渲染出来，然后添加更精细的细节，再向结构的其余部分扩展。时间不够，整座大教堂没能完成。即便如此，仍有几位黑客松参与者向他们询问，或提出帮忙让它更准确。Holly 和 Austin 希望把 Tekton 开源，让博物馆、历史学家、非营利组织和政府都能在其基础上继续构建。

给其他开发者的建议：在动手构建任何部分之前，先把整个项目规划清楚。

"我们建了一份完整的 PRD，还有一个大约 50 张工单的 Notion 看板，每张工单对应一个具体任务，"Austin 说。"几乎就像是：这是从头到尾的完整项目，而这正是我们对每一步的明确要求。"计划定好后，他把构建拆分成不同的工作流并行运行。

Tekton on GitHub

### 二等奖：Sim Francisco，Tanmayi Priya Dasari 与 Tejas Prabhune

![Image 2](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a32e670a9a0ae0844278fec_Claude_Build_Day_280_cropped_native.jpg)

Sim Francisco 是旧金山人口的一个可运行模型。它有 1 万名取自美国人口普查（US Census）数据的合成居民，每个人都有自己的人口统计特征、个人经历和世界观，被放置在城市地图上，并实时对新闻做出反应。

向这座城市提一个问题，它便会逐街区地对整个合成选民群体进行民意调查。在知识截止日期为 2023 年 10 月的模型上运行时，它预测 2024 年总统选举的民主党得票率为 81.3%，而实际为 83.8%；对旧金山 2024 年 3 月 A 号提案（Prop A）的预测为 70%，实际为 70.38%。它对 Kalshi 和 Polymarket 等预测市场的跟踪误差在几个百分点之内。*

Opus 4.8 编写了整个前端和后端，并端到端地验证了后端的行为。为验证模型的工作，团队让 Claude 与一个验证器和一个对抗性智能体（adversarial agent）协同工作，构建出一个能重现城市真实人口分布的后端。

Tanmayi Priya Dasari 和 Tejas Prabhune 是加州大学伯克利分校（UC Berkeley）的电气工程与计算机科学专业学生，他们通过校园里的机器学习俱乐部相识。对 Tejas 而言，Sim Francisco 同时也是他正在创办的后训练（post-training）公司的一次测试，他想搞清楚模拟出来的人物角色能否保持足够一致，以便在长周期任务上训练模型。

给其他开发者的建议：不要止步于第一个可行的方案，尤其当它很昂贵时。

团队的第一个版本为 1 万名居民中的每一个分别发起一次推理调用，成本很高。"随着时间推移，Claude 运行了一个它自己创建的演化聚类算法，"Tejas 说，把居民批量归并成约 300 个有代表性的人物角色。归组后的版本在对照 Kalshi、Polymarket 和历史结果时保持了相同的准确度，同时把推理成本削减了 10 到 100 倍。

Sim Francisco on GitHub

### 三等奖：Custom Universe，Jake Stevens 与 Mauricio Pereira

![Image 3](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a32eb3be6cc4dc20abf6ba5_Claude_Build_Day_241_compressed.jpg)

用手机给一把椅子拍张照片，Custom Universe 就会把它变成一个 3D 物体，你可以将它放进场景、用文本提示重新设定风格，并在渲染图像实时更新的同时移动它。

该项目面向机器人实验室，这些实验室需要大量合成数据来针对特定任务和环境训练机器人。实验室可以扫描工厂车间里的一台机器，把它放进场景，生成数据来为那个确切的环境微调（fine-tune）一个机器人模型。搭建这种环境通常意味着要雇佣物理学家和工程师来处理物理和碰撞几何。Custom Universe 让你改为通过拖动物体来布置场景，团队还计划加入精确放置功能，比如把一个物体在厨房台面上挪动 30 厘米。

Opus 4.8 端到端地构建了整个项目，并在整场黑客松期间操控运行模型的远程 NVIDIA H100。团队还用 Claude 来确定哪些模型能产生正确的输出，并构建了把用 Apple 的 RealityKit 扫描得到的手机物体导入 Web 应用的流水线（pipeline）。

Jake Stevens 和 Mauricio Pereira 是在活动现场认识的。Jake 是罗切斯特理工学院（RIT）计算机视觉专业毕业生，经营着一家专注于加速 AI 模型的创业公司 Luminal；这个场景构建器最初是他一直想试一试的副业项目。Mauricio 是麻省理工学院（MIT）机器人专业毕业生，经营着 Coat Robotics，他带来了自己亲身了解的问题：机器人领域仍然缺乏训练数据，而构建合成环境很难。Custom Universe 依赖开源模型和算法，可免费使用；团队表示用户可以在自己的 GPU 上运行它。

给其他开发者的建议：用 Claude 来选择你的工具，而不仅仅是写代码。

"很多迭代都在于看哪个模型能给我们正确的输出，所以我们用 Claude 做了大量调研，"Mauricio 说。团队还把不熟悉的技术交给 Claude 去集成。"例如 Apple RealityKit，以及我们要如何确保人们能把扫描的物体输入到我们的网站。我们对 Claude 说：把这个加进流水线。"

Custom Universe on GitHub

了解我们的 Claude 社区项目，包括线下聚会、黑客松等等。

*Sim Francisco 是一个独立的黑客松项目，它以预测选举结果作为示例。这并不代表 Anthropic 认可将 AI 模拟的选举预测作为一种用例。

## 术语对照

| English | 中文 |
|---|---|
| hackathon | 黑客松 |
| demo | 演示 |
| evidence chain | 证据链 |
| sub-agent / verifier sub-agents | 子智能体／验证子智能体 |
| context window | 上下文窗口 |
| self-correction loop | 自我纠正循环 |
| PRD | 产品需求文档（PRD） |
| workflow | 工作流 |
| synthetic residents | 合成居民 |
| US Census | 美国人口普查 |
| knowledge cutoff | 知识截止日期 |
| prediction markets | 预测市场 |
| adversarial agent | 对抗性智能体 |
| post-training | 后训练 |
| inference call | 推理调用 |
| evolutionary clustering algorithm | 演化聚类算法 |
| synthetic data | 合成数据 |
| fine-tune | 微调 |
| collision geometry | 碰撞几何 |
| pipeline | 流水线 |
| computer vision | 计算机视觉 |
