#!/usr/bin/env bash
# Publish the archive under the version tag and any extra tags, then summarise.
set -euo pipefail

if [[ "$OCI_REPOSITORY" != oci://*/* ]]; then
  echo "::error::oci-repository must look like oci://<registry>/<namespace>, got '$OCI_REPOSITORY'." >&2
  exit 1
fi

name="$(basename "$PACKAGE" .tar.zst)"
name="${name#zarf-package-}"
name="${name%%-"$ARCH"*}"

read -r -a extra <<<"${EXTRA_TAGS//,/ }"
refs=()
for tag in "$TAG" ${extra[@]+"${extra[@]}"}; do
  zarf package publish "$PACKAGE" "$OCI_REPOSITORY" --tag "$tag" --confirm
  refs+=("${OCI_REPOSITORY#oci://}/${name}:${tag}")
done

{
  echo "refs<<ZARF_REFS_EOF"
  printf '%s\n' "${refs[@]}"
  echo "ZARF_REFS_EOF"
} >>"$GITHUB_OUTPUT"

{
  printf '## Published Zarf package\n\n'
  printf -- "- \`%s\`\n" "${refs[@]}"
} >>"$GITHUB_STEP_SUMMARY"
