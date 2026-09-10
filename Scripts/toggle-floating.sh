#!/usr/bin/env bash
set -euo pipefail

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 1
fi

floating="$(hyprctl activewindow -j 2>/dev/null | jq -r '.floating // empty')"

case "$floating" in
    false)
        hyprctl dispatch togglefloating >/dev/null
        hyprctl dispatch resizeactive exact 70% 72% >/dev/null
        hyprctl dispatch centerwindow 1 >/dev/null
        ;;
    true)
        hyprctl dispatch togglefloating >/dev/null
        ;;
    *)
        exit 0
        ;;
esac
