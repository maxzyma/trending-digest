#!/usr/bin/env python3
"""Materialize the claude_blog Jekyll collection from the archive content source.

The archive stores each article as a self-contained canonical package under
``sources/claude-blog/posts/YYYY-MM/YYYY-MM-DD/<slug>/`` (canonical.json + raw +
translations + rendered markdown variants + metadata.json). The public site must
render ONLY one reading page per article, so this step selects the single reading
markdown, injects the front matter the ``claude-blog-post`` layout consumes, and
writes it to ``_claude_blog/`` under the legacy URL path (``YYYY/MM/YYYY-MM-DD-
slug.md``) so existing links / Cloudflare routes stay stable. Non-reading files
(canonical.json, raw HTML, translation/editorial JSON, other md variants) are
never copied into the collection.

Legacy flat posts (``posts/YYYY/MM/YYYY-MM-DD-slug.md`` already carrying front
matter) are passed through unchanged, deduplicated by slug in favour of a
canonical package when both exist. This keeps the site rendering correct during
the transition from the legacy flat producer to the canonical-package pipeline.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import date
from pathlib import Path


def _yaml_str(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def read_category(package_dir: Path) -> str:
    canonical = package_dir / "canonical.json"
    if canonical.is_file():
        data = json.loads(canonical.read_text(encoding="utf-8"))
        categories = data.get("metadata", {}).get("categories") or []
        if categories:
            return str(categories[0])
    return "Claude Blog"


def frontmatter(meta: dict, category: str) -> str:
    published = str(meta.get("published_at", "")).strip()
    return "\n".join(
        [
            "---",
            f"source: {_yaml_str('claude-blog')}",
            f"source_url: {_yaml_str(meta.get('source_url', ''))}",
            f"published_at: {_yaml_str(published)}",
            f"category: {_yaml_str(category)}",
            f"title_en: {_yaml_str(meta.get('title_en', ''))}",
            f"title_zh: {_yaml_str(meta.get('title_zh', meta.get('title', '')))}",
            f"document_id: {_yaml_str(meta.get('document_id', ''))}",
            'format: "bilingual-paragraph-zh-first"',
            "---",
            "",
        ]
    )


def legacy_url_path(published: str, slug: str) -> Path | None:
    try:
        d = date.fromisoformat(published[:10])
    except ValueError:
        return None
    return Path(f"{d:%Y}") / f"{d:%m}" / f"{d:%Y-%m-%d}-{slug}.md"


def slug_of_legacy(md_path: Path) -> str:
    m = re.match(r"\d{4}-\d{2}-\d{2}-(.*)", md_path.stem)
    return m.group(1) if m else md_path.stem


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    src = root / "sources" / "claude-blog" / "posts"
    dest = root / "_claude_blog"

    if dest.exists():
        import shutil

        shutil.rmtree(dest)
    dest.mkdir(parents=True, exist_ok=True)

    if not src.is_dir():
        print("[materialize] WARN: sources/claude-blog/posts missing — _claude_blog empty")
        return 0

    emitted_slugs: set[str] = set()
    package_count = 0
    legacy_count = 0

    # 1) Canonical packages: identified by a sibling <slug>.metadata.json.
    for meta_path in sorted(src.glob("**/*.metadata.json")):
        package_dir = meta_path.parent
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        slug = package_dir.name
        content_file = package_dir / Path(meta.get("content_file", f"{slug}.md")).name
        if not content_file.is_file():
            print(f"[materialize] WARN: reading md missing for {slug}, skipping")
            continue
        rel = legacy_url_path(str(meta.get("published_at", "")), slug)
        if rel is None:
            print(f"[materialize] WARN: bad published_at for {slug}, skipping")
            continue
        body = content_file.read_text(encoding="utf-8")
        category = read_category(package_dir)
        out = dest / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(frontmatter(meta, category) + body, encoding="utf-8")
        emitted_slugs.add(slug)
        package_count += 1

    # 2) Legacy flat posts (already carry front matter): passthrough, dedup by slug.
    for md_path in sorted(src.glob("[0-9]" * 4 + "/*/*.md")):
        slug = slug_of_legacy(md_path)
        if slug in emitted_slugs:
            continue
        rel = md_path.relative_to(src)
        out = dest / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(md_path.read_text(encoding="utf-8"), encoding="utf-8")
        emitted_slugs.add(slug)
        legacy_count += 1

    print(
        f"[materialize] _claude_blog: {package_count} from canonical packages, "
        f"{legacy_count} legacy flat passthrough, {len(emitted_slugs)} total articles"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
