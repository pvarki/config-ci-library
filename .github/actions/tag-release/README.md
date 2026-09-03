# tag-release

Tags `HEAD` with the version in `.bumpversion.toml` and pushes it, so `release-notes` has a tag to
release. `1.14.3+260822` tags as `v1.14.3-260822`, matching the image tag `publish-image` pushes.

Intended for repos with no tag / release flow of their own.

| input             | default | description                           |
| ----------------- | ------- | ------------------------------------- |
| `version_context` | `./`    | Directory of the `.bumpversion.toml`. |
| `tag-prefix`      | `v`     | Prefix for the tag.                   |
| `dry-run`         | `false` | Print the decision, tag nothing.      |

Output `tag` is empty when the version was already released.

```yaml
release:
  needs: publish
  runs-on: ubuntu-latest
  permissions:
    contents: write
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
        tag: ${{ steps.tag.outputs.tag }}
        attach-to-release: "true"
```
