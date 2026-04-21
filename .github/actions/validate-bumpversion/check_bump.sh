#!/bin/bash
set -e

CURRENT=$(bump-my-version show current_version --config-file .bumpversion.toml)
git fetch origin "$BASE_REF" --depth=1

TMPFILE=$(mktemp /tmp/bumpversion-XXXXXX.toml)
git show "origin/$BASE_REF:.bumpversion.toml" > "$TMPFILE"
PREVIOUS=$(bump-my-version show current_version --config-file "$TMPFILE")
rm "$TMPFILE"

if [ "$CURRENT" = "$PREVIOUS" ]; then
  echo "ERROR: Version was not bumped (still $CURRENT)"
  exit 1
fi

echo "Version bumped: $PREVIOUS → $CURRENT"
