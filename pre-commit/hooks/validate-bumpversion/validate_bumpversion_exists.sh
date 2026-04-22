#!/bin/bash
set -e
test -f .bumpversion.toml || (echo "ERROR: .bumpversion.toml not found" && exit 1)
