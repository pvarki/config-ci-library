# release-notes

Runs [releasenote-tool](https://github.com/pvarki/python-releasenote-tool) on the checkout: a
changelog from the commits in `previous-tag..tag`, release notes from the `releasenote` block of the
pull requests in it, and a slide deck of those notes.

| input               | default                                 | description                                                              |
| ------------------- | --------------------------------------- | ------------------------------------------------------------------------ |
| `tag`               | the pushed tag                          | Tag to release. Titles the release and ends the commit range.            |
| `previous-tag`      | the tag before `tag`                    | Tag the range starts after, exclusive.                                   |
| `out`               | `release-notes`                         | Directory to write into, relative to the workspace.                      |
| `slides`            | `pdf,pptx`                              | Slide formats to render, comma separated. Empty renders no slides.       |
| `image`             | `ghcr.io/pvarki/releasenote-tool:0.1.0` | Tool image to run.                                                       |
| `attach-to-release` | `false`                                 | Attach the output to the release of `tag`, creating it if there is none. |
| `github-token`      | `${{ github.token }}`                   | Reads the pull requests, and manages the release when attaching.         |

```yaml
on:
  push:
    tags: ["v*"]

jobs:
  release-notes:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: read
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: pvarki/config-ci-library/.github/actions/release-notes@main
        with:
          attach-to-release: "true"
```

Needs `fetch-depth: 0`, `docker` and `gh` on the runner, and a tag before `tag` to function as intended.
