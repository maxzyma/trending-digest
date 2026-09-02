# 已验证的教训

来自门户上线（2026-07）的实测经验，改动本仓站点或 Worker 路由时先看这几条。

## 平台默认行为必须用真实构建校准

github-trending 无自定义 permalink，Jekyll 默认页面 URL **带 `.html` 后缀**（`/daily/{date}-analysis.html`），weekly 还有 `-old-...` 描述后缀变体。纸面推导的 301 正则漏了这两点，靠真实构建才暴露。涉及 permalink / baseurl / safe-mode 等平台默认行为的规则，实现期必须跑真实构建核对，不能只读配置推断。

## 真实构建才能暴露内容层坏数据

docker 真实 Jekyll 构建暴露了 8 个 claude-blog post 的 front matter YAML 坏值（标题含未引号的冒号，该 post 被静默跳过）。静态检查与 mock 不会发现这类问题。根因在上游流水线的 front-matter 写入，见 [../TODO.md](../TODO.md)。

## 结构性校验要显式构造"整段缺失"反例

`validate-site.rb` 原先只校验挂载 collection 的 permalink 前缀是否错位，对整段缺失的 collection `next unless key?` 直接放行——更严重的故障态反而不拦。同一思路下的多轮审查会盯着"配错"而想不到"整个没有"。校验类代码必须显式构造：整段缺失、空集、零元素。

## 分清"构建能验的"与"必须 live 验的"

域名可达、反代连通、301 生效本质只能在生产域切换后验证，pre-merge 再多轮审查也覆盖不了。这类交付用原子 cutover runbook 兜底（见 [../docs/cutover-runbook.md](../docs/cutover-runbook.md)），live 验证用 agent-browser 而非 curl/WebFetch（后者有假阴性）。

## Worker 反代的两个致命点

- **origin 必须指 Pages 域**（`maxzyma.github.io/...`），指回自定义域会被 CF 路由回 Worker，造成无限递归/502。
- **转发时须剥离原始 Host**，否则 origin 按自定义域路由回本域，同样递归。
