#!/usr/bin/env bash
set -euo pipefail

command -v hyprctl >/dev/null 2>&1 || exit 1
command -v jq >/dev/null 2>&1 || exit 1

floating="$(hyprctl activewindow -j 2>/dev/null | jq -r '.floating // empty')"

if [[ "$floating" == "false" || "$floating" == "0" ]]; then
    # Classic Hyprland pattern: toggle to floating, resize, then center in one
    # compositor batch so the geometry commands land on the same state change.
    hyprctl --batch "dispatch togglefloating; dispatch resizeactive exact 68% 70%; dispatch centerwindow" >/dev/null
elif [[ "$floating" == "true" || "$floating" == "1" ]]; then
    hyprctl dispatch togglefloating >/dev/null
else
    # Preserve native behavior if activewindow JSON ever changes.
    hyprctl dispatch togglefloating >/dev/null
fi
