#!/usr/bin/env bash
set -u

pass() { printf '[ OK ] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; }

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then pass "$1 -> $(command -v "$1")"; else fail "$1 not found"; fi
}

for cmd in Hyprland start-hyprland hyprctl qs wpctl brightnessctl playerctl wl-copy grim slurp kitty dolphin nm-applet blueman-applet; do
  check_cmd "$cmd"
done

if command -v pboi >/dev/null 2>&1; then
  pass "pboi -> $(command -v pboi)"
else
  warn 'pboi not found in PATH (fresh installs may need one logout/login for ~/.local/bin)'
fi

if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
  Hyprland --verify-config && pass 'Hyprland config parses' || fail 'Hyprland config has errors'
else
  fail '~/.config/hypr/hyprland.conf missing'
fi

[[ -f "$HOME/.config/quickshell/persona/shell.qml" ]] && pass 'Persona shell.qml installed' || fail 'Persona shell.qml missing'
[[ -f "$HOME/.config/quickshell/persona/Layers/Tray.qml" ]] && pass 'Custom tray installed' || fail 'Tray.qml missing'
[[ -f "$HOME/.config/quickshell/persona/Layers/Workspaces.qml" ]] && pass 'Workspace tracker installed' || fail 'Workspaces.qml missing'
[[ -f "$HOME/.config/quickshell/persona/VERSION" ]] && pass "Personaboi v$(tr -d '[:space:]' < "$HOME/.config/quickshell/persona/VERSION") installed" || warn 'VERSION marker missing'
[[ -f "$HOME/.local/lib/qt6/qml/CavaMonitor/libcavamonitorplugin.so" ]] && pass 'CavaMonitor plugin installed' || fail 'CavaMonitor plugin missing'
[[ -f /usr/local/lib/libcava.so ]] && pass 'libcava.so installed' || fail 'libcava.so missing'

printf '\nVersions:\n'
Hyprland --version 2>/dev/null | head -n 1 || true
qs --version 2>/dev/null || true
fc-match 'JetBrainsMono Nerd Font' | head -n 1 || true

if [[ -r /sys/module/nvidia_drm/parameters/modeset ]]; then
  mode="$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || true)"
  [[ "$mode" == 'Y' ]] && pass 'NVIDIA DRM modeset = Y' || warn "NVIDIA DRM modeset = ${mode:-unknown}"
elif [[ -e /sys/module/nvidia_drm/parameters/modeset ]]; then
  warn 'NVIDIA DRM modeset exists but is not readable as the current user'
else
  warn 'nvidia_drm is not loaded (fine on non-NVIDIA systems)'
fi
