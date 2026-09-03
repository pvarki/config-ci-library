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

if [ -z "$OUT" ]; then
  fail "out must name a directory"
fi

case "$OUT" in
  /*) fail "out must be relative to the workspace, got $OUT" ;;
  *..*) fail "out must stay inside the workspace, got $OUT" ;;
esac

if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  fail "shallow checkout cannot reach the previous tag, use fetch-depth: 0"
fi

if [ -z "$REF" ]; then
  if [ -n "$PR" ]; then
    REF="HEAD"
  elif [ "$GITHUB_REF_TYPE" = "tag" ]; then
    REF="$GITHUB_REF_NAME"
  else
    fail "not a tag push, pass ref: or pr:"
  fi
fi

if ! git rev-parse -q --verify "$REF^{commit}" >/dev/null; then
  fail "ref: $REF does not exist"
fi

if [ -n "$PREVIOUS_REF" ] && ! git rev-parse -q --verify "$PREVIOUS_REF^{commit}" >/dev/null; then
  fail "previous-ref: $PREVIOUS_REF does not exist"
fi

echo "Range: ${PREVIOUS_REF:-the tag before $REF}..$REF"
echo "Running $IMAGE"
if ! docker pull --quiet "$IMAGE"; then
  fail "could not pull $IMAGE."
fi

ARGS=(changes --to "$REF" --out "$OUT")
if [ -n "$PREVIOUS_REF" ]; then
  ARGS+=(--from "$PREVIOUS_REF")
fi
if [ -n "$PR" ]; then
  ARGS+=(--pr "$PR")
fi
if [ -n "$PRODUCT" ]; then
  ARGS+=(--product "$PRODUCT")
fi
if [ -n "$RELEASE" ]; then
  ARGS+=(--release "$RELEASE")
fi

IFS=',' read -ra FORMATS <<<"$SLIDES"
for format in "${FORMATS[@]}"; do
  format="${format//[[:space:]]/}"
  case "$format" in
    '') ;;
    pdf | pptx) ARGS+=(--slides "$format") ;;
    *) fail "slides: unknown format '$format', expected pdf or pptx" ;;
  esac
done

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --volume "$GITHUB_WORKSPACE:/workspace" \
  --workdir /workspace \
  --env GH_TOKEN \
  "$IMAGE" "${ARGS[@]}"

BODY="$OUT/release-body.md"

{
  echo "out=$OUT"
  echo "ref=$REF"
  echo "body=$BODY"
} >>"$GITHUB_OUTPUT"

if [ -f "$BODY" ]; then
  {
    echo "## Release notes for $REF"
    echo
    cat "$BODY"
  } >>"$GITHUB_STEP_SUMMARY"
else
  echo "::warning::$BODY was not written, nothing to summarise"
fi
