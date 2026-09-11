# tag-release

Tags `HEAD` with the version in `.bumpversion.toml` and pushes it, so `release-notes` has a tag to
release. `1.14.3+260822` tags as `v1.14.3+260822`, the version verbatim behind the prefix.

Intended for repos with no tag / release flow of their own.

| input             | default | description                           |
| ----------------- | ------- | ------------------------------------- |
| `version_context` | `./`    | Directory of the `.bumpversion.toml`. |
| `tag-prefix`      | `v`     | Prefix for the tag.                   |
| `dry-run`         | `false` | Print the decision, tag nothing.      |

Outputs `tag` and `version`, the latter as `.bumpversion.toml` writes it (`1.14.3+260822`), which is
what `release-notes` wants for `release:`. `tag` is empty when this version was already released from
a different commit; a tag that already points at `HEAD` is kept, so a re-run can rebuild the notes.

```yaml
release:
  needs: publish
  runs-on: ubuntu-latest
  permissions:
    contents: write
    packages: read
    pull-requests: read
  steps:
    - uses: actions/checkout@v6
      with:
        fetch-depth: 0
    - uses: pvarki/config-ci-library/.github/actions/tag-release@main
      id: tag
    - uses: pvarki/config-ci-library/.github/actions/release-notes@main
      if: steps.tag.outputs.tag != ''
      with:
        ref: ${{ steps.tag.outputs.tag }}
        release: ${{ steps.tag.outputs.version }}
        attach-to-release: "true"
```

Needs `fetch-depth: 0`, so the tags are there to compare against, and `contents: write` to push.
