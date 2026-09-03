# release-notes

Runs [releasenote-tool](https://github.com/pvarki/python-releasenote-tool) on the checkout: a
changelog from the commits in `previous-ref..ref`, release notes from the `releasenote` block of the
pull requests in it, and a slide deck of those notes. Files are named `<product>-<release>-<kind>`,
beside a fixed-name `release-body.md` that holds the notes and the changelog in one.

| input               | default                   | description                                                               |
| ------------------- | ------------------------- | ------------------------------------------------------------------------- |
| `ref`               | the pushed tag            | End of the range, inclusive. Titles the release.                          |
| `previous-ref`      | the tag before `ref`      | Start of the range, exclusive.                                            |
| `pr`                | none                      | Also read this pull request, merged or not, to preview what it would add. |
| `product`           | the repository name       | Name the output files lead with.                                          |
| `release`           | `ref`                     | Version the documents claim.                                              |
| `out`               | `release-notes`           | Directory to write into, relative to the workspace.                       |
| `slides`            | `pdf,pptx`                | Slide formats to render, comma separated. Empty renders no slides.        |
| `image`             | a pinned releasenote-tool | Tool image to run.                                                        |
| `attach-to-release` | `false`                   | Attach the output to the release of `ref`, creating it if there is none.  |
| `github-token`      | `${{ github.token }}`     | Pulls the image, reads the pull requests, manages the release.            |

Outputs `out` (the directory), `ref` (the resolved end of the range) and `body` (the path to
`release-body.md`). On a tag push the defaults are enough:

```yaml
on:
  push:
    tags: ["v*"]

jobs:
  release-notes:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: read
      pull-requests: read
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: pvarki/config-ci-library/.github/actions/release-notes@main
        with:
          attach-to-release: "true"
```
