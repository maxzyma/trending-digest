# Behaviors 索引: 聚合门户

| Rule 文件 | Rule（用户任务） | Story | Scenario 数 | SC 范围 |
|-----------|-----------------|-------|------------|---------|
| site-skeleton.gherkin | 本仓具备 Jekyll 站点骨架 + Pages 部署 + CNAME | US-00 | 4 | SC-01~03, 20 |
| portal-homepage.gherkin | 门户首页（Hero + 信源导航网格 + 流占位） | US-01 | 5 | SC-04~07, 21 |
| latest-stream.gherkin | 首页最新内容流（同仓小源倒序） | US-02 | 4 | SC-08~10, 22 |
| small-source-subsite.gherkin | 小源同仓分目录子站 | US-03 | 4 | SC-11~13, 23 |
| github-trending-proxy.gherkin | github-trending 经 Worker 反代 | US-04 | 4 | SC-14~16, 24 |
| legacy-redirect.gherkin | 旧 URL 301 重定向兜底 | US-05 | 4 | SC-17~19, 25 |

合计 6 Rule / 25 Scenario（每 Rule 含正常/边界/错误三类）。SC-20~25 为各 Rule 的 @error 场景。
