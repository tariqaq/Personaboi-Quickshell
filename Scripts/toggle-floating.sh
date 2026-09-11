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
        # Clear any internal/client maximize/fullscreen state first. Some apps
        # otherwise keep a maximized geometry even after becoming floating.
        hyprctl dispatch fullscreenstate 0 0 >/dev/null 2>&1 || true
        hyprctl dispatch setfloating active >/dev/null 2>&1 || exit 1
        sleep 0.18
        hyprctl dispatch fullscreenstate 0 0 >/dev/null 2>&1 || true

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
            # Use the documented resizeactive syntax directly with separate
            # arguments, then repeat once in case the client restores geometry.
            hyprctl dispatch resizeactive exact "$target_w" "$target_h" >/dev/null 2>&1 || true
            sleep 0.14
            hyprctl dispatch resizeactive exact "$target_w" "$target_h" >/dev/null 2>&1 || true
        else
            hyprctl dispatch resizeactive exact 68% 70% >/dev/null 2>&1 || true
            sleep 0.14
            hyprctl dispatch resizeactive exact 68% 70% >/dev/null 2>&1 || true
        fi

        sleep 0.04
        hyprctl dispatch centerwindow 1 >/dev/null 2>&1 || true
        ;;
    true|1)
        hyprctl dispatch settiled active >/dev/null 2>&1 || exit 1
        ;;
    *)
        hyprctl dispatch togglefloating >/dev/null 2>&1 || exit 1
        ;;
esac
