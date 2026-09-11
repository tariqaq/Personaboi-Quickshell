#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/.local/state/personaboi/logs"
mkdir -p "$LOG_DIR"
HOOK_LOG_FILE="$LOG_DIR/update-hook-$(date '+%Y%m%d-%H%M%S').log"
exec > >(tee -a "$HOOK_LOG_FILE") 2>&1
printf '[%s] update-hook start: user=%s parent_log=%s\n' "$(date '+%F %T %z')" "$USER" "${PBOI_PARENT_LOG:-none}"
trap 'rc=$?; printf "[%s] ERROR rc=%s line=%s command=%q\n" "$(date "+%F %T %z")" "$rc" "$LINENO" "$BASH_COMMAND" >&2' ERR
trap 'printf "[%s] update-hook finished. Log: %s\n" "$(date "+%F %T %z")" "$HOOK_LOG_FILE"' EXIT

# Runs from `pboi update` before shared files are applied.
# Keep migrations cumulative and idempotent so very old installs can jump
# straight to the current release without replaying every historical version.

if [[ -r /etc/os-release ]]; then
    source /etc/os-release
    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "26.04" ]]; then
        echo "Warning: Personaboi is tested on Ubuntu 26.04; detected ${PRETTY_NAME:-unknown}." >&2
    else
        echo "Detected supported OS: ${PRETTY_NAME:-Ubuntu 26.04}"
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
    else
        echo "Runtime migration packages already satisfied."
    fi

    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
        echo "Adding $USER to the video group for brightness control..."
        sudo usermod -aG video "$USER"
        echo "Brightness permission note: log out and back in once after this update."
    else
        echo "Brightness video-group permission already satisfied."
    fi

    sudo udevadm control --reload-rules >/dev/null 2>&1 || true
    sudo udevadm trigger --subsystem-match=backlight >/dev/null 2>&1 || true
else
    echo "APT/sudo unavailable; no Ubuntu package migration attempted."
fi

exit 0
