---
slug: claude-blog-frontmatter-quoting
status: collected
priority: P2
type: fix
created: 2026-07-09
---

# claude-blog 流水线 front-matter 值引号化

## 来源

聚合门户交付（implement 期）真实构建暴露：`sources/claude-blog/posts/**` 中 8 个 post 的 `title_en`/`title_zh` 含未引号的冒号（如 `title_zh: Claude Tag：...`），导致 Jekyll YAML 解析失败、该 post 无法渲染。存量 8 文件已在门户交付中就地修复（加双引号），但**根因在跨仓流水线**（coworkspace 的 claude-blog digest 生成脚本写 front-matter 时未对含特殊字符的 scalar 值加引号）——未修则新增 post 会持续复现。

## 待办

- 定位 coworkspace 侧 claude-blog digest 生成脚本的 front-matter 写入处
- 对 `title_en`/`title_zh` 等文本 scalar 值统一引号化（或用 YAML 库序列化而非字符串拼接）
- 可选：在门户 `scripts/validate-site.rb` 增一条构建前 front-matter 可解析性预检（fail-loud）

## 归属

跨仓：修复动作落 coworkspace（流水线），本仓已消费其产物。P2（存量已修，仅防新增复现）。

## Intake 覆盖账本

| 五问维度 | 覆盖 | 内容 |
|------|------|------|
| 用户 | covered | 门户维护者 / 聚合门户读者（受影响 post 渲染缺失影响阅读） |
| 场景 | covered | claude-blog 流水线新增 digest 时 front-matter 含冒号等 YAML 特殊字符 |
| 任务 | covered | 流水线写 front-matter scalar 值统一引号化，使 Jekyll 构建不再因坏 YAML 跳过 post |
| 成功判据 | covered | 新增 post 的 title_en/title_zh 恒可被 Jekyll YAML 解析；门户构建 0 YAML 解析失败 |
| 边界 | covered | 仅修流水线写入侧引号化 + 可选构建前预检；不改已归档存量（存量 8 文件已就地修）；不扩到其他源 |
