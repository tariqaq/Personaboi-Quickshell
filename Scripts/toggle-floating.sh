#!/usr/bin/env bash
set -u

# Always keep Super+V functional. Query the active window state when possible,
# but fall back to Hyprland's native toggle if the state cannot be read.
if ! command -v hyprctl >/dev/null 2>&1; then
    exit 1
fi

floating=""
if command -v jq >/dev/null 2>&1; then
    floating="$(hyprctl activewindow -j 2>/dev/null | jq -r '.floating // empty' 2>/dev/null || true)"
fi

case "$floating" in
    false|0)
        # Use the dispatcher sequence documented for classic hyprland.conf.
        # togglefloating happens first so a later resize/center failure cannot
        # leave Super+V completely dead.
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        hyprctl dispatch resizeactive exact 70% 72% >/dev/null 2>&1 || true
        hyprctl dispatch centerwindow 1 >/dev/null 2>&1 || true
        ;;
    true|1)
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        ;;
    *)
        # If JSON/state detection ever changes, preserve the core Super+V
        # behavior instead of silently doing nothing.
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        ;;
esac
