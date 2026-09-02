# 待办

按优先级排列。设计与契约见 [specs/](specs/README.md)。

## P1 三站编辑重设计

对齐 theuntold 主站当前设计语言，统一门户、claude-blog、github-trending 三站的排版与明暗机制。需求与 stories 见 [specs/editorial-redesign.md](specs/editorial-redesign.md)。前一次按 token 拷贝的做法已放弃，改走完整重设计。

## P1 构建断言从未跑通

**`scripts/verify-build.sh` 至今没有实测过**（本机 docker 不可用，`jekyll/builder:4` 起不来）。两批改动都压在这个未验证的口子上：

- **talks 手动来源**：多源 `materialize_collection.py`、`talks` collection、layout、SourceCard；改动过的 SC-09 / SC-10 断言只做了 `bash -n`。
- **目录整理**：入口页移到 `pages/`（URL 由 `permalink` 决定，理论上不变）、`/taxonomy/` 新页面与门户首页新增的入口链接（刻意避开 `<li>` 与 `<time>`，以免影响 SC-08 的计数与倒序断言）。

已实测通过的只有：`ruby scripts/validate-site.rb`、`python3 scripts/materialize_collection.py`（claude-blog 52 篇不变 / talks 2 篇生成）、`python3 scripts/materialize_taxonomy.py`、`bash -n`。

**合入前必须补跑 `scripts/verify-build.sh`，尤其确认 SC-05/08/11/12/13 未被目录调整打破。**

## P2 claude-blog front-matter 引号化（跨仓）

`title_en` / `title_zh` 含未引号的冒号会让 Jekyll YAML 解析失败、该 post 静默不渲染。存量 8 个文件已就地修复，但根因在私有编排层的 claude-blog digest 生成脚本（字符串拼接写 front matter，未对特殊字符 scalar 加引号），未修则新增 post 持续复现。

- 修复动作落私有编排层流水线：改用 YAML 库序列化，或对文本 scalar 统一引号化
- 可选：`scripts/validate-site.rb` 增一条 front-matter 可解析性预检（fail-loud）

## P2 手动来源缺 dry-run 与写入后校验

`docs/producer-contract.md` 要求 archive adapter 支持 dry-run、写入后校验文章/索引/manifest 一致性。`talks` 这类手动来源当前全靠人工，无自动校验。

## P3 talks 与 claude-blog 的 layout 重复

`_layouts/talk-post.html` 与 `_layouts/claude-blog-post.html` 的 CSS 近乎重复（约 20 行），`pages/talks.html` 与 `pages/claude-blog.html` 同理。当前按外科手术原则未重构；是否抽公共 layout / include 待定。

## P3 同仓源 markdown 格式契约未成文

双语正文结构、元数据头、原文链接位置目前只由实现约定。它是下游（站点、钉钉文档）的解析契约，变更会破坏下游，值得写进 `specs/`。
