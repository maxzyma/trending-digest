# Producer Contract

## Role

`trending-diggest` is a public archive and reading site. Producers deliver
deterministic public artifacts into this repository; they do not run extraction,
translation, scheduling, or remote delivery from inside the repository.

## Input boundary

The preferred producer input is a versioned canonical article package containing:

- stable document and block identifiers;
- source URL and source revision hash;
- structured content and optional translation overlays;
- generator and policy versions;
- content-addressed asset references.

Target Markdown must be rendered from that package. It must not be reused as the
source for DingTalk or other publisher renderers.

## Archive transaction

A producer must:

1. Validate the canonical package and translation coverage.
2. Produce a read-only archive plan.
3. Render quoted, valid YAML front matter and Markdown.
4. Stage the post, source index, and public manifest together.
5. Verify staged content and run repository build checks.
6. Apply the write only after explicit approval or automation policy permits it.
7. Commit and push as separate, explicit orchestration operations.

## Public manifest

`sources/<source>/manifest.json` may contain:

```json
{
  "schema_version": "archive-manifest.v1",
  "documents": [
    {
      "document_id": "source:stable-id",
      "source_url": "https://example.com/article",
      "source_revision": "sha256:...",
      "archive_path": "sources/source/posts/YYYY/MM/article.md",
      "published_at": "YYYY-MM-DD",
      "generator_version": "article-pivot@..."
    }
  ]
}
```

It must not contain credentials, internal URLs, destination IDs, retries,
dead-letter state, scheduler cursors, or notification routing.

## Legacy compatibility

`sources/claude-blog/state/processed.json` remains temporarily because the
current production script uses it for URL deduplication. New producers must not
adopt this file. Migration removes it only after private runtime state has been
backfilled and the old producer has stopped writing it.
