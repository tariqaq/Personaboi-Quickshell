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

# v1.4: the corner brightness control must run brightnessctl as the logged-in
# desktop user. Ubuntu ships the permission rules separately in brightness-udev.
if command -v apt >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    if ! dpkg-query -W -f='${Status}' brightness-udev 2>/dev/null | grep -q 'ok installed'; then
        echo "Installing brightness-udev for unprivileged backlight control..."
        sudo apt install -y brightness-udev
    fi

    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
        echo "Adding $USER to the video group for brightness control..."
        sudo usermod -aG video "$USER"
        echo "Brightness permission note: log out and back in once after this update."
    fi

    sudo udevadm control --reload-rules >/dev/null 2>&1 || true
    sudo udevadm trigger --subsystem-match=backlight >/dev/null 2>&1 || true
fi

exit 0
