#!/bin/bash
set -e
shopt -s nullglob

fail() {
  echo "::error::$1"
  exit 1
}

if ! command -v gh >/dev/null; then
  fail "gh not found, attach-to-release needs a runner with the GitHub CLI"
fi

if [ -z "$REF" ]; then
  fail "ref is empty, nothing to attach to. Gate this step on the tag being non-empty."
fi

if ! git rev-parse -q --verify "refs/tags/$REF" >/dev/null; then
  fail "attach-to-release needs ref to be a tag, got $REF"
fi

BODY="$OUT/release-body.md"
if [ ! -f "$BODY" ]; then
  fail "$BODY not found, run the notes step first"
fi

export GH_REPO="$GITHUB_REPOSITORY"

ASSETS=(
  "$OUT"/*-changelog.md
  "$OUT"/*-release-notes.md
  "$OUT"/*-slides.md
  "$OUT"/*-release-notes.pdf
  "$OUT"/*-release-notes.pptx
)

if gh release view "$REF" >/dev/null 2>&1; then
  if [ "${#ASSETS[@]}" -eq 0 ]; then
    echo "Release $REF exists and there are no assets to add"
  else
    echo "Release $REF exists, uploading ${#ASSETS[@]} assets"
    gh release upload "$REF" "${ASSETS[@]}" --clobber
  fi
else
  echo "Creating release $REF with ${#ASSETS[@]} assets"
  gh release create "$REF" "${ASSETS[@]}" \
    --verify-tag \
    --title "$REF" \
    --notes-file "$BODY"
fi
