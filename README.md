# CI Library

Contains implementations and information on CI standards. This repository is not intended to be just a reference library, the implementations from here can and should be used in practice. For more best practices reference, see [markdown-pvarki-best_practices](https://github.com/pvarki/markdown-pvarki-best_practises).

## Development

### Pre-Commit

Pre-commit is configured under `.pre-commit-config.yaml`. The recommended tool tro run it locally is [Prek](https://github.com/j178/prek), which is also used in the GitHub Action. There are no additional required dependencies apart from prek. Installing the pre-commit is done as follows:

```
prek install
```

And checks can be manually run as follows

```
prek run --all-files
```

### Versioning

This repo uses [bump-my-version](https://callowayproject.github.io/bump-my-version/), with the format `MAJOR.MINOR.PATCH-YYMMDD`. Version can be incremented using the [CLI tool for bump-my-version](https://callowayproject.github.io/bump-my-version/tutorials/getting-started/#installation):

```bash
bump-my-version bump <patch|minor|major>
```

You can also check the effect on the version using the following command (note that the date is automatically incremented appropriately):

```bash
bump-my-version show-bump
0.1.0-260420 ── bump ─┬─ major ─── 1.0.0-260421
                      ├─ minor ─── 0.2.0-260421
                      ├─ patch ─── 0.1.1-260421
                      ╰─ release ─ 0.1.0-260421
```
