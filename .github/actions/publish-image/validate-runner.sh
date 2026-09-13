#!/usr/bin/env bash
set -euo pipefail

if [[ "${RUNNER_ENVIRONMENT:-}" != "self-hosted" ]] ||
   [[ "${RUNNER_NAME:-}" != arc-runner-set-* ]]; then
  echo "::error::publish-image requires 'runs-on: arc-runner-set'. Current runner: '${RUNNER_NAME:-unknown}' (${RUNNER_ENVIRONMENT:-unknown})." >&2
  exit 1
fi

for file in \
  /etc/buildkit/tls/ca.crt \
  /etc/buildkit/tls/tls.crt \
  /etc/buildkit/tls/tls.key
do
  if [[ ! -r "$file" ]]; then
    echo "::error::publish-image requires the ARC BuildKit TLS configuration. '$file' is missing. Ensure the job uses 'runs-on: arc-runner-set'." >&2
    exit 1
  fi
done
