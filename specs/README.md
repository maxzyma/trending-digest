# specs/ — 设计与契约

本仓的设计事实源。改门户结构、路由规则或站点校验脚本前先读这里。

| 文档 | 内容 |
|------|------|
| [overview.md](overview.md) | 产品定位、职责边界、内容模型、跨功能不变量与质量底线 |
| [decisions.md](decisions.md) | ADR-001~004：单域多仓聚合、小源同仓 vs 大站独立仓、裸 `/` 归属、baseurl 铁律 |
| [lessons.md](lessons.md) | 门户上线的实测教训（平台默认行为、Worker 递归、校验盲区） |
| [portal/](portal/README.md) | 聚合门户的边界、不变量、路由/实体/算法契约与行为规格 |
| [editorial-redesign.md](editorial-redesign.md) | 待做的三站编辑重设计：目标、复用信源、范围与工作项 |

相关但不在此处：

- 运维切换步骤 → [../docs/cutover-runbook.md](../docs/cutover-runbook.md)
- 内容生产者契约 → [../docs/producer-contract.md](../docs/producer-contract.md)
- 待办 → [../TODO.md](../TODO.md)

## SC 编号怎么读

`portal/behaviors/*.gherkin` 是 SC-01~27 的定义源，`scripts/verify-build.sh` 与 `scripts/validate-site.rb` 的断言按 SC 编号标注，[portal/verification-matrix.md](portal/verification-matrix.md) 给出 SC ↔ 测试用例的映射。改行为规格时同步这三处。
