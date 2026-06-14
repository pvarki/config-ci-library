#!/bin/bash
set -e

ORIGIN_REF="origin/$BASE_REF:.bumpversion.toml"
CURRENT=$(bump-my-version show current_version --config-file .bumpversion.toml)
git fetch origin "$BASE_REF" --depth=1

if ! git show "$ORIGIN_REF"  > /dev/null; then
  echo "No .bumpversion.toml found in origin/$BASE_REF:$VERSION_PATH — treating as new file, skipping version check"
  echo "Current version: $CURRENT"
  exit 0
fi

TMPFILE=$(mktemp /tmp/bumpversion-XXXXXX.toml)
git show "$ORIGIN_REF" > "$TMPFILE"
PREVIOUS=$(bump-my-version show current_version --config-file "$TMPFILE")
rm "$TMPFILE"

if [ "$CURRENT" = "$PREVIOUS" ]; then
  echo "ERROR: Version was not bumped (still $CURRENT)"
  exit 1
fi

echo "Version bumped: $PREVIOUS → $CURRENT"
