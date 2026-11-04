# zarf-package

Builds a Zarf package from the checkout, optionally lints and keyless-signs it, and publishes it to
an OCI registry under the version tag and any extra tags.

## Expects on `PATH`

| tool                          | needed for                                        |
| ----------------------------- | ------------------------------------------------- |
| `zarf`                        | always                                            |
| `bump-my-version`             | resolving the version, unless `version` is passed |
| whatever `build-command` runs | the default needs `task`                          |

The action only checks they are there, installation is to be done by the repository. Keyless signing
additionally needs `permissions: id-token: write`.

## Expects in the repository

The default `build-command` expects a `build:package` task, given `ARCH` and `BUILD_DIR`, leaving
exactly one archive in `BUILD_DIR`. Repositories naming it differently pass their own
`build-command`. The default `lint-command` expects `zarf.yaml` at the root.

## Inputs

| input             | default                                                  | description                                                         |
| ----------------- | -------------------------------------------------------- | ------------------------------------------------------------------- |
| `lint-command`    | `zarf dev lint .`                                        | Command that lints the definition. Empty skips linting.             |
| `build-command`   | `task build:package ARCH="$ARCH" BUILD_DIR="$BUILD_DIR"` | Command that builds into `$BUILD_DIR`. Gets `ARCH` and `BUILD_DIR`. |
| `arch`            | `amd64`                                                  | Package architecture.                                               |
| `version`         | `bump-my-version show current_version`                   | Package version.                                                    |
| `version_context` | `./`                                                     | Directory the version is read from.                                 |
| `extra-tags`      | `latest`                                                 | Tags besides the version, comma or newline separated.               |
| `oci-repository`  | none                                                     | OCI namespace to publish into. Required when publishing.            |
| `publish`         | `true`                                                   | `false` builds only, for pull requests.                             |
| `sign`            | `none`                                                   | `none` or `zarf-keyless`.                                           |
| `github-token`    | `${{ github.token }}`                                    | Logs in to GHCR.                                                    |

Outputs `package` (the archive path), `version`, `tag` and `refs` (the published references, one per
line).

The build command fails the action unless it leaves exactly one `zarf-package-*.tar.zst` in
`$BUILD_DIR`.

## Publish with a keyless signature

```yaml
permissions:
  contents: read
  id-token: write
  packages: write

jobs:
  publish:
    runs-on: arc-runner-set
    steps:
      - uses: actions/checkout@v7.0.1
      - uses: jdx/mise-action@v5.1.1
        with:
          cache: true
      - uses: pvarki/config-ci-library/.github/actions/zarf-package@main
        with:
          oci-repository: oci://ghcr.io/pvarki
          sign: zarf-keyless
```

## A build command of your own

```yaml
- uses: pvarki/config-ci-library/.github/actions/zarf-package@main
  with:
    build-command: task -t taskfiles/build.yaml package ARCH="$ARCH" BUILD_DIR="$BUILD_DIR"
    oci-repository: oci://ghcr.io/pvarki/packages
```

## Check the build on a pull request

```yaml
- uses: pvarki/config-ci-library/.github/actions/zarf-package@main
  with:
    publish: false
```
