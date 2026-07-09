#!/usr/bin/env bash
# 构建前物化 Jekyll collection：内容源在 sources/claude-blog/posts/（流水线写入契约），
# collection 目录须 _ 前缀且为真实文件（GitHub Pages Actions 构建可能忽略 symlink）。
# 故构建期复制到 _claude_blog/（gitignored 构建产物）。pages.yml 与本地构建共用本脚本。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/sources/claude-blog/posts"
DEST="$ROOT/_claude_blog"

rm -rf "$DEST"
mkdir -p "$DEST"
if [ -d "$SRC" ] && [ -n "$(ls -A "$SRC" 2>/dev/null)" ]; then
  cp -R "$SRC/." "$DEST/"
  echo "[prepare-collections] materialized _claude_blog from sources/claude-blog/posts"
else
  echo "[prepare-collections] WARN: sources/claude-blog/posts empty/missing — _claude_blog is empty"
fi
