#!/usr/bin/env bash
# 构建前物化 Jekyll collection：内容源在 sources/claude-blog/posts/（流水线写入契约），
# collection 目录须 _ 前缀且为真实文件（GitHub Pages Actions 构建可能忽略 symlink）。
# 故构建期复制到 _claude_blog/（gitignored 构建产物）。pages.yml 与本地构建共用本脚本。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Self-contained archive: each article is a canonical package (canonical.json +
# raw + translations + rendered md variants + metadata) under posts/. Only ONE
# reading page per article may reach the site, with the front matter the
# claude-blog-post layout needs, so materialization is a transform (not a raw
# copy): see scripts/materialize_collection.py. Legacy flat posts pass through.
PYTHON_BIN="${TD_PIPELINE_PYTHON:-python3}"
"$PYTHON_BIN" "$ROOT/scripts/materialize_collection.py"

# 跨源主题聚类页：taxonomy/rollup.md 由编排层写入、无 front matter，
# 物化成 taxonomy/index.md 才能被 Jekyll 渲染到 /taxonomy/。
"$PYTHON_BIN" "$ROOT/scripts/materialize_taxonomy.py"
