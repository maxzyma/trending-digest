---
source: claude-blog
source_url: https://claude.com/blog/meet-the-winners-of-our-claude-opus-4-8-build-day-hackathon
published_at: 2026-06-17
category: Claude Code
title_en: Meet the winners of our Claude Opus 4.8 Build Day hackathon
title_zh: 认识 Claude Opus 4.8 Build Day 黑客松的获奖者
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/gvNG4YZ7JneMYaqzcNYwgMb9V2LD0oRE"
---

# 认识 Claude Opus 4.8 Build Day 黑客松的获奖者

> 来源：Claude Blog，2026-06-17
> 原文链接：https://claude.com/blog/meet-the-winners-of-our-claude-opus-4-8-build-day-hackathon
> 分类：Claude Code

## 核心要点

- 6 月 13 日，我们在旧金山举办了一场 12 小时的 Claude Opus 4.8 黑客松，超过 300 名创始人与开发者参加，共有 1500 多人申请。
- 第一名 Tekton 用 Claude 研究并以 3D 重建历史木结构建筑，每个部件都可追溯至有据可查的来源，形成"证据链"。
- 第二名 Sim Francisco 基于美国人口普查数据构建了含 1 万名合成居民的旧金山仿真模型，可对现实事件作出实时反应并预测投票结果。
- 第三名 Custom Universe 将手机拍摄的物体转为可拖拽布置的 3D 对象，面向机器人实验室生成合成训练数据。
- 三支团队均借助 Opus 4.8 完成端到端开发，并使用验证子智能体（verifier sub-agent）与对抗智能体来校验结果。
- 共同的经验：先规划再动手、不满足于首个可行方案、用 Claude 选择工具而不仅是写代码。

## 中文译文

6 月 13 日，我们把 300 多名创始人与开发者带到旧金山，参加一场为期 12 小时、围绕 Claude Opus 4.8 展开的黑客松。共有超过 1500 人申请，310 人最终参赛，许多人远道而来，每人获得 500 美元额度，并有一天时间把一个想法变成可运行的演示。

我们采访了三支获奖团队，了解他们构建了什么，以及如何用 Claude 完成。

祝贺所有获奖者和参与者。希望他们的项目能给你带来一些灵感。

## 第一名：Tekton——Holly Tang 与 Austin Burgess

当一座历史悠久的木结构建筑被烧毁时，数百年的工艺也可能随之消失。Tekton 以 3D 重建这些建筑，并把每一个部件追溯到有据可查的来源。

给 Tekton 一座历史建筑，Claude 便会对其展开研究，汇集图纸、施工文档、照片与图解，然后在 339 个递进的建造状态中组装出一个 3D 模型。当你点击模型中的任意构件时，Tekton 会展示该细节的出处以及它为何被放置在那里。团队称之为"证据链"（evidence chain），从源材料一直延伸到经过验证的模型。他们为学术验证、修复工作和文化保护而构建了它，起步于唐代建筑和巴黎圣母院的尖塔。

验证过程完全运行在 Opus 4.8 上。独立的验证子智能体（verifier sub-agent）在隔离的上下文窗口中分别对每次重建打分，自我修正循环反复核查构件位置，直到全部 20 项测试通过。每一次构建都对照历史记录及其引证进行衡量，因此最终模型遵循该结构最初建造时有据可查的规则。

Holly Tang 与 Austin Burgess 在一个月前相识，当时他们在一场 Code with Claude 活动上排队买咖啡。Holly 是一名设计师，一直在协助 Austin 的创业项目 Pearl。"我喜欢看纪录片，每次看到美丽的建筑毁于火灾都让我难过，"Holly 说。她曾独自做过单座建筑重建的原型；Austin 的贡献则是把它扩展成能端到端地处理任意建筑。

为构建 Tekton，两人分阶段推进：先让巴黎圣母院的尖塔以足够规模渲染出来，再添加更精细的细节，然后向结构的其余部分扩展。时间在整座大教堂完成之前就用完了。即便如此，仍有多名黑客松参与者前来询问，或主动提出帮助提升它的准确度。Holly 和 Austin 希望把 Tekton 开源，让博物馆、历史学家、非营利组织和政府能够在其基础上继续构建。

给其他开发者的建议：在动手之前先规划好整个项目。

"我们写了一份完整的产品需求文档（PRD），还做了一个有大约 50 个工单的 Notion 看板，每个工单对应一项具体任务，"Austin 说。"几乎就像是，这里是端到端的完整项目，而这正是我们对每一步的确切期望。"计划确定后，他把构建拆分成独立的工作流并行运行。

Tekton 的 GitHub 仓库

## 第二名：Sim Francisco——Tanmayi Priya Dasari 与 Tejas Prabhune

Sim Francisco 是旧金山人口的一个运作中的模型。它有 1 万名取自美国人口普查数据的合成居民，每人都有各自的人口统计特征、个人经历与世界观，被放置在城市地图上，并实时对新闻作出反应。

向这座城市提一个问题，它就会逐街区地对整个合成选民群体进行投票。在使用知识截止于 2023 年 10 月的模型的情况下，它预测 2024 年总统选举的民主党得票率为 81.3%，实际为 83.8%；预测旧金山 2024 年 3 月的 Prop A 提案为 70%，实际为 70.38%。它对 Kalshi、Polymarket 等预测市场的跟踪误差在几个百分点之内。*

Opus 4.8 编写了全部前端与后端，并端到端地验证了后端的行为。为了校验模型的工作，团队让 Claude 与一个验证者和一个对抗智能体协同工作，构建出一个能复现该城市真实人口分布的后端。

Tanmayi Priya Dasari 与 Tejas Prabhune 都是加州大学伯克利分校的电气工程与计算机科学专业学生，通过校内的机器学习俱乐部相识。对 Tejas 来说，Sim Francisco 同时也是对他正在创办的后训练（post-training）公司的一次测试——他在探索模拟出来的人物角色能否保持足够的一致性，以用于在长周期任务上训练模型。

给其他开发者的建议：不要满足于第一个奏效的方案，尤其当它代价高昂时。

团队的第一个版本为 1 万名居民中的每一个都单独发起一次推理调用，成本随之高企。"随着时间推移，Claude 运行了一套它自己创造的演化聚类算法，"Tejas 说，把居民归并为大约 300 个有代表性的人物角色。归并后的版本在对照 Kalshi、Polymarket 和历史结果时保持了相同的准确度，同时把推理成本削减为原来的十分之一到百分之一。

Sim Francisco 的 GitHub 仓库

## 第三名：Custom Universe——Jake Stevens 与 Mauricio Pereira

用手机拍一张椅子的照片，Custom Universe 会把它变成一个 3D 物体，你可以将其放入场景、用文本提示重新设定其风格，并在移动它时让渲染图像实时更新。

该项目面向机器人实验室——它们需要大量合成数据来训练机器人完成特定任务与场景。实验室可以扫描工厂车间里的一台机器，把它放入场景，生成数据来针对那个确切环境微调机器人模型。搭建这类装置通常意味着要聘请物理学家和工程师来处理物理与碰撞几何。Custom Universe 让你改用拖拽物体的方式来布置场景，团队还计划加入精确放置功能，比如把一个物体在厨房台面上挪动 30 厘米。

Opus 4.8 端到端地构建了整个项目，并在整个黑客松期间操作运行模型的远程 NVIDIA H100。团队还用 Claude 来判断哪些模型能产出正确的输出，并构建了把用 Apple RealityKit 扫描的手机物体导入网页应用的流水线。

Jake Stevens 与 Mauricio Pereira 在活动现场相识。Jake 是罗切斯特理工学院（RIT）计算机视觉专业毕业生，经营着一家专注于加速 AI 模型的创业公司 Luminal；这个场景构建器最初是他一直想尝试的一个副业项目。Mauricio 是麻省理工学院机器人专业毕业生，经营着 Coat Robotics，带来了他亲身了解的问题：机器人领域仍然缺乏训练数据，而构建合成环境很难。Custom Universe 依赖开源模型与算法，免费使用；团队表示用户可以在自己的 GPU 上运行它。

给其他开发者的建议：用 Claude 来选择你的工具，而不只是写代码。

"很多迭代都在于查看哪个模型能给我们正确的输出，所以我们用 Claude 做了大量调研，"Mauricio 说。团队还把不熟悉的技术交给 Claude 去集成。"比如 Apple RealityKit，以及我们要如何确保人们能把扫描的物体输入到我们的网站。我们问 Claude：把这个加进流水线。"

Custom Universe 的 GitHub 仓库

了解我们的 Claude 社区项目，包括线下聚会、黑客松等。

*Sim Francisco 是一个独立的黑客松项目，仅以预测选举结果作为示例。这并不代表 Anthropic 认可将 AI 模拟的选举预测作为一种使用场景。

## 术语对照

| English | 中文 |
|---|---|
| hackathon | 黑客松 |
| demo | 演示 |
| credits | 额度 |
| evidence chain | 证据链 |
| 3D model | 3D 模型 |
| construction states | 建造状态 |
| verifier sub-agent | 验证子智能体 |
| context window | 上下文窗口 |
| self-correction loop | 自我修正循环 |
| PRD (Product Requirements Document) | 产品需求文档 |
| workflow | 工作流 |
| open source | 开源 |
| synthetic residents | 合成居民 |
| US Census data | 美国人口普查数据 |
| demographics | 人口统计特征 |
| knowledge cutoff | 知识截止 |
| prediction market | 预测市场 |
| inference call | 推理调用 |
| evolutionary clustering algorithm | 演化聚类算法 |
| personas | 人物角色 |
| post-training | 后训练 |
| long-horizon task | 长周期任务 |
| backend / frontend | 后端 / 前端 |
| adversarial agent | 对抗智能体 |
| synthetic data | 合成数据 |
| collision geometry | 碰撞几何 |
| fine-tune | 微调 |
| pipeline | 流水线 |
| computer vision | 计算机视觉 |
