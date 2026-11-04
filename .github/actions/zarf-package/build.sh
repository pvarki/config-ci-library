#!/usr/bin/env bash
# Resolve the version, lint the definition, and build exactly one package archive.
set -euo pipefail

if ! command -v zarf >/dev/null 2>&1; then
  echo "::error::zarf is not on PATH." >&2
  exit 1
fi

case "$SIGN" in
none | zarf-keyless) ;;
*)
  echo "::error::sign must be 'none' or 'zarf-keyless', got '$SIGN'." >&2
  exit 1
  ;;
esac

if [[ -z "$VERSION" ]]; then
  if ! command -v bump-my-version >/dev/null 2>&1; then
    echo "::error::bump-my-version is not on PATH. Pass the 'version' input to skip it." >&2
    exit 1
  fi
  VERSION="$(cd "$VERSION_CONTEXT" && bump-my-version show current_version)"
fi

TAG="${VERSION//+/-}"
if [[ ! "$TAG" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}$ ]]; then
  echo "::error::Missing version or invalid OCI version tag: $TAG" >&2
  exit 1
fi

if [[ -n "$LINT_COMMAND" ]]; then
  bash -euo pipefail -c "$LINT_COMMAND"
fi

BUILD_DIR="$(mktemp -d "${RUNNER_TEMP:-/tmp}/zarf-build.XXXXXX")"
export ARCH BUILD_DIR
bash -euo pipefail -c "$BUILD_COMMAND"

shopt -s nullglob
packages=("$BUILD_DIR"/zarf-package-*.tar.zst)
if [[ ${#packages[@]} -ne 1 ]]; then
  echo "::error::Expected exactly one Zarf package archive in '$BUILD_DIR', found ${#packages[@]}." >&2
  exit 1
fi

{
  echo "package=${packages[0]}"
  echo "version=$VERSION"
  echo "tag=$TAG"
} >>"$GITHUB_OUTPUT"
