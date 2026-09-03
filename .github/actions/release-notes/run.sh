#!/bin/bash
set -e

fail() {
  echo "::error::$1"
  exit 1
}

if ! command -v docker >/dev/null; then
  fail "docker not found, needed to run $IMAGE"
fi

if [ -z "$GH_TOKEN" ]; then
  fail "github-token is empty"
fi

case "$OUT" in
  /*) fail "out must be relative to the workspace, got $OUT" ;;
esac

if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  fail "shallow checkout cannot reach the previous tag, use fetch-depth: 0"
fi

if [ -z "$TAG" ]; then
  if [ "$GITHUB_REF_TYPE" != "tag" ]; then
    fail "not a tag push, pass tag:"
  fi
  TAG="$GITHUB_REF_NAME"
fi

if ! git rev-parse -q --verify "$TAG^{commit}" >/dev/null; then
  fail "tag: $TAG does not exist"
fi

if [ -n "$PREVIOUS_TAG" ]; then
  if ! git rev-parse -q --verify "$PREVIOUS_TAG^{commit}" >/dev/null; then
    fail "previous-tag: $PREVIOUS_TAG does not exist"
  fi
else
  PREVIOUS_TAG=$(git describe --tags --abbrev=0 "$TAG^" 2>/dev/null || true)
  if [ -z "$PREVIOUS_TAG" ]; then
    fail "no tag before $TAG to start the range from, tag the previous release first"
  fi
fi

echo "Range: $PREVIOUS_TAG..$TAG"
echo "Running $IMAGE"
if ! docker pull --quiet "$IMAGE"; then
  fail "could not pull $IMAGE"
fi

ARGS=(build --from "$PREVIOUS_TAG" --to "$TAG" --out "$OUT")
IFS=',' read -ra FORMATS <<<"$SLIDES"
for format in "${FORMATS[@]}"; do
  if [ -n "$format" ]; then
    ARGS+=(--slides "$format")
  fi
done

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --volume "$GITHUB_WORKSPACE:/workspace" \
  --workdir /workspace \
  --env GH_TOKEN \
  "$IMAGE" "${ARGS[@]}"

echo "tag=$TAG" >>"$GITHUB_OUTPUT"
echo "out=$OUT" >>"$GITHUB_OUTPUT"

{
  echo "## Release notes for $TAG"
  echo
  cat "$OUT/release-body.md"
} >>"$GITHUB_STEP_SUMMARY"
