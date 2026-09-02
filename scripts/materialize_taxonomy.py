#!/usr/bin/env python3
"""Materialize the cross-source theme rollup into a renderable Jekyll page.

``taxonomy/rollup.md`` is written by the private aggregation pipeline and carries
no front matter, so Jekyll would copy it to the site verbatim instead of
rendering it. This step reads that file, strips its leading H1 (the layout owns
the page title), and writes ``taxonomy/index.md`` — a gitignored build product
with the front matter the ``taxonomy`` layout consumes, served at ``/taxonomy/``.

The source data files (rollup.md / rollup.json / assignments.jsonl / themes.toml)
stay excluded from the build; only the generated page reaches the site.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "taxonomy" / "rollup.md"
TARGET = ROOT / "taxonomy" / "index.md"

TITLE = "跨源主题聚类"
DESCRIPTION = "GitHub Trending、Claude Blog 与 Lil'Log 的跨源主题分布与升温退潮。"

H1_PATTERN = re.compile(r"\A#\s+(?P<heading>.+?)\s*\n+", re.MULTILINE)


def _yaml_str(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def build_page(rollup: str) -> str:
    """Return the page markdown: front matter + rollup body without its H1."""
    match = H1_PATTERN.match(rollup)
    heading = match.group("heading") if match else TITLE
    body = rollup[match.end():] if match else rollup

    front_matter = "\n".join(
        (
            "---",
            "layout: taxonomy",
            f"title: {_yaml_str(TITLE)}",
            f"heading: {_yaml_str(heading)}",
            f"description: {_yaml_str(DESCRIPTION)}",
            "permalink: /taxonomy/",
            "---",
            "",
        )
    )
    return front_matter + body.lstrip("\n")


def main() -> int:
    if not SOURCE.exists():
        print(f"[materialize-taxonomy] no rollup at {SOURCE}, skipped", file=sys.stderr)
        return 0

    try:
        page = build_page(SOURCE.read_text(encoding="utf-8"))
        TARGET.write_text(page, encoding="utf-8")
    except OSError as error:
        print(f"[materialize-taxonomy] failed: {error}", file=sys.stderr)
        return 1

    print(f"[materialize-taxonomy] wrote {TARGET.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
