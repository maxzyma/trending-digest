# Behaviors 索引: 聚合门户

| Rule 文件 | Rule（用户任务） | Story | Scenario 数 | SC 范围 |
|-----------|-----------------|-------|------------|---------|
| site-skeleton.gherkin | 本仓具备 Jekyll 站点骨架 + Pages 部署 + CNAME | US-00 | 3 | SC-01~03 |
| portal-homepage.gherkin | 门户首页（Hero + 信源导航网格 + 流占位） | US-01 | 4 | SC-04~07 |
| latest-stream.gherkin | 首页最新内容流（同仓小源倒序） | US-02 | 3 | SC-08~10 |
| small-source-subsite.gherkin | 小源同仓分目录子站 | US-03 | 3 | SC-11~13 |
| github-trending-proxy.gherkin | github-trending 经 Worker 反代 | US-04 | 3 | SC-14~16 |
| legacy-redirect.gherkin | 旧 URL 301 重定向兜底 | US-05 | 3 | SC-17~19 |

合计 6 Rule / 19 Scenario。
