#!/bin/bash
set -e

fail() {
  echo "::error::$1"
  exit 1
}

case "$DRY_RUN" in
  true | false) ;;
  *) fail "dry-run must be true or false, got $DRY_RUN" ;;
esac

if [ ! -f "$VERSION_CONTEXT/.bumpversion.toml" ]; then
  fail "$VERSION_CONTEXT: .bumpversion.toml not found"
fi

if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  fail "shallow checkout has no tags to compare against, use fetch-depth: 0"
fi

VERSION=$(cd "$VERSION_CONTEXT" && python3 -c "import tomllib; d=tomllib.load(open('.bumpversion.toml','rb')); print(d['tool']['bumpversion']['current_version'])")

TAG="$PREFIX$VERSION"

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  if [ "$(git rev-parse "$TAG^{commit}")" = "$(git rev-parse HEAD)" ]; then
    echo "$TAG already points at HEAD"
  else
    echo "::warning::$VERSION was already released as $TAG, bump the version to release"
    TAG=""
  fi
elif [ "$DRY_RUN" = "true" ]; then
  echo "Would tag HEAD as $TAG"
else
  git tag "$TAG"
  git push origin "refs/tags/$TAG"
  echo "Tagged HEAD as $TAG"
fi

{
  echo "tag=$TAG"
  echo "version=$VERSION"
} >>"$GITHUB_OUTPUT"
