#!/bin/bash
set -e

CURRENT=$(bump-my-version show current_version --config-file .bumpversion.toml)
git fetch origin "$BASE_REF" --depth=1

if ! git show "origin/$BASE_REF:$VERSION_PATH.bumpversion.toml" > /dev/null 2>&1; then
  echo "No .bumpversion.toml found in origin/$BASE_REF:$VERSION_PATH — treating as new file, skipping version check"
  echo "Current version: $CURRENT"
  exit 0
fi

TMPFILE=$(mktemp /tmp/bumpversion-XXXXXX.toml)
git show "origin/$BASE_REF:$VERSION_PATH.bumpversion.toml" > "$TMPFILE"
PREVIOUS=$(bump-my-version show current_version --config-file "$TMPFILE")
rm "$TMPFILE"

if [ "$CURRENT" = "$PREVIOUS" ]; then
  echo "ERROR: Version was not bumped (still $CURRENT)"
  exit 1
fi

echo "Version bumped: $PREVIOUS → $CURRENT"
