#!/bin/bash
set -e

if ! command -v gh >/dev/null; then
  echo "::error::gh not found, attach-to-release needs a runner with the GitHub CLI"
  exit 1
fi

export GH_REPO="$GITHUB_REPOSITORY"

ASSETS=()
for name in changelog.md release-notes.md slides.md slides.pdf slides.pptx; do
  if [ -f "$OUT/$name" ]; then
    ASSETS+=("$OUT/$name")
  fi
done

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG exists, uploading ${#ASSETS[@]} assets"
  gh release upload "$TAG" "${ASSETS[@]}" --clobber
else
  echo "Creating release $TAG with ${#ASSETS[@]} assets"
  gh release create "$TAG" "${ASSETS[@]}" \
    --verify-tag \
    --title "$TAG" \
    --notes-file "$OUT/release-body.md"
fi
