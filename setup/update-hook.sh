#!/usr/bin/env bash
set -euo pipefail

# Runs from `pboi update` before shared files are applied.
# Keep migrations cumulative and idempotent so very old installs can jump
# straight to the current release without replaying every historical version.

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "26.04" ]]; then
        echo "Warning: Personaboi is tested on Ubuntu 26.04; detected ${PRETTY_NAME:-unknown}." >&2
    fi
fi

if command -v apt >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    missing=()

    for pkg in hyprland-qtutils nautilus brightness-udev libnotify-bin jq; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'ok installed'; then
            missing+=("$pkg")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        echo "Installing Personaboi runtime packages missing from this older install: ${missing[*]}"
        sudo apt install -y "${missing[@]}"
    fi

    # v1.4+: brightness control runs as the desktop user. Ubuntu's udev rules
    # grant access through the video group instead of setuid/passwordless sudo.
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
        echo "Adding $USER to the video group for brightness control..."
        sudo usermod -aG video "$USER"
        echo "Brightness permission note: log out and back in once after this update."
    fi

    sudo udevadm control --reload-rules >/dev/null 2>&1 || true
    sudo udevadm trigger --subsystem-match=backlight >/dev/null 2>&1 || true
fi

exit 0
