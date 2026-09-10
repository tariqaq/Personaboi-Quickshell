#!/usr/bin/env bash
set -u

if ! command -v hyprctl >/dev/null 2>&1; then
    exit 1
fi

# Capture the focused window before changing state so we can target the same
# client even if focus/order changes while Hyprland animates the transition.
window_json="$(hyprctl activewindow -j 2>/dev/null || true)"
address=""
floating=""
if command -v jq >/dev/null 2>&1 && [[ -n "$window_json" ]]; then
    address="$(printf '%s' "$window_json" | jq -r '.address // empty' 2>/dev/null || true)"
    floating="$(printf '%s' "$window_json" | jq -r '.floating // empty' 2>/dev/null || true)"
fi

case "$floating" in
    false|0)
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        # The old floating geometry may be remembered by Hyprland/app state.
        # Wait for float state to settle, then explicitly overwrite geometry.
        sleep 0.16

        if [[ -n "$address" ]]; then
            # resizewindowpixel targets the exact window and accepts screen
            # percentages in the classic dispatcher syntax used by 0.53.x.
            hyprctl dispatch resizewindowpixel "exact 70% 72%,address:$address" >/dev/null 2>&1 || true
            sleep 0.03
        else
            hyprctl dispatch resizeactive "exact 70% 72%" >/dev/null 2>&1 || true
        fi

        # Center only after the explicit resize has landed.
        hyprctl dispatch centerwindow 1 >/dev/null 2>&1 || true
        ;;
    true|1)
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        ;;
    *)
        # Preserve native toggle behavior if JSON output changes unexpectedly.
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        ;;
esac
