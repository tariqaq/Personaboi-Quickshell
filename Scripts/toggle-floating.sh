#!/usr/bin/env bash
set -euo pipefail

command -v hyprctl >/dev/null 2>&1 || exit 1
command -v jq >/dev/null 2>&1 || exit 1

# Do NOT use `.floating // empty` here: jq's // operator treats boolean false
# like a missing value, so tiled windows were falling through to the plain
# toggle path and never reaching the resize/center batch.
floating="$(hyprctl activewindow -j 2>/dev/null | jq -r '.floating')"

if [[ "$floating" == "false" || "$floating" == "0" ]]; then
    # This is the same simple pattern commonly used by Hyprland users:
    # float -> resize -> center in one compositor batch.
    hyprctl --batch "dispatch togglefloating; dispatch resizeactive exact 68% 70%; dispatch centerwindow" >/dev/null
elif [[ "$floating" == "true" || "$floating" == "1" ]]; then
    hyprctl dispatch togglefloating >/dev/null
else
    # Preserve native behavior if activewindow JSON ever changes.
    hyprctl dispatch togglefloating >/dev/null
fi
