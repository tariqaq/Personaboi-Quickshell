#!/usr/bin/env bash
set -euo pipefail

# Runs from `pboi update` before shared files are applied.
# Keep release-specific dependency migrations here so existing pboi clients
# can prepare for a newer repo version during the same update.

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "26.04" ]]; then
        echo "Warning: Personaboi is tested on Ubuntu 26.04; detected ${PRETTY_NAME:-unknown}." >&2
    fi
fi

# v1.1 has no additional package migration.
exit 0
