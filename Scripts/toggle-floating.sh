#!/usr/bin/env bash
set -u

if ! command -v hyprctl >/dev/null 2>&1; then
    exit 1
fi

window_json="$(hyprctl activewindow -j 2>/dev/null || true)"
floating=""
if command -v jq >/dev/null 2>&1 && [[ -n "$window_json" ]]; then
    floating="$(printf '%s' "$window_json" | jq -r '.floating // empty' 2>/dev/null || true)"
fi

case "$floating" in
    false|0)
        # Set floating explicitly, then overwrite the inherited tiled geometry
        # with numeric logical-pixel dimensions derived from the focused monitor.
        hyprctl dispatch setfloating active >/dev/null 2>&1 || exit 1
        sleep 0.12

        target_w=""
        target_h=""
        if command -v jq >/dev/null 2>&1; then
            monitor_json="$(hyprctl monitors -j 2>/dev/null || true)"
            if [[ -n "$monitor_json" ]]; then
                target_w="$(printf '%s' "$monitor_json" | jq -r '[.[] | select(.focused == true)][0] | if . then ((.width / .scale) * 0.68 | floor) else empty end' 2>/dev/null || true)"
                target_h="$(printf '%s' "$monitor_json" | jq -r '[.[] | select(.focused == true)][0] | if . then ((.height / .scale) * 0.70 | floor) else empty end' 2>/dev/null || true)"
            fi
        fi

        if [[ "$target_w" =~ ^[0-9]+$ && "$target_h" =~ ^[0-9]+$ ]]; then
            hyprctl dispatch resizeactive "exact $target_w $target_h" >/dev/null 2>&1 || true
            # Some clients restore their previous floating size one frame later.
            sleep 0.10
            hyprctl dispatch resizeactive "exact $target_w $target_h" >/dev/null 2>&1 || true
        else
            # Generic fallback when monitor JSON is unavailable.
            hyprctl dispatch resizeactive "exact 68% 70%" >/dev/null 2>&1 || true
            sleep 0.10
            hyprctl dispatch resizeactive "exact 68% 70%" >/dev/null 2>&1 || true
        fi

        sleep 0.03
        hyprctl dispatch centerwindow 1 >/dev/null 2>&1 || true
        ;;
    true|1)
        hyprctl dispatch settiled active >/dev/null 2>&1 || exit 1
        ;;
    *)
        # Preserve native behavior if JSON state detection ever changes.
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        ;;
esac
