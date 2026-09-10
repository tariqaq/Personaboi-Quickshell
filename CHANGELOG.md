# Changelog

All notable Personaboi changes are tracked here. Versions describe this Ubuntu 26.04 fork, not upstream Persona-Quickshell releases.

## v1.2 — 2026-09-11

**Focus:** input handling, launcher convenience, and power/session reliability.

### Added
- `Super+B` launches the browser currently registered as the XDG default.
- MSI brightness-key fallback binds while preserving the normal `XF86MonBrightnessUp/Down` binds.

### Changed
- `Super+E` now opens GNOME Files (`nautilus`) instead of Dolphin, and fresh installs explicitly install `nautilus`.
- Corrected the MSI brightness fallback from Linux evdev codes 224/225 to their XKB keycodes 232/233, which are the values Hyprland's `code:` binding expects.
- Power-menu shutdown/reboot now call `systemctl poweroff` / `systemctl reboot`, while logout exits the current Hyprland session with `hyprctl dispatch exit`.
- `Super+V` now makes a newly-floating window visibly smaller (70% x 72% of the monitor) and centers it; pressing `Super+V` again returns it to normal tiled layout control.

### Fixed
- Fixed the Persona power menu using unsupported `loginctl poweroff` / `loginctl reboot` commands.
- Fixed the workspace shell strip blocking clicks on application UI underneath it. The strip still reserves the top edge, but its input mask now only covers the visible workspace pill, so the rest of the top strip is click-through.

### Known / investigating
- On the tested MSI Stealth laptop, brightness hotkeys emit `KEY_BRIGHTNESSDOWN/UP` on the ACPI `Video Bus` device and work in GNOME, but are still not reaching Hyprland's bind path. `brightnessctl` itself works correctly. Further input-stack diagnosis is required rather than adding more guessed keycodes.

## v1.1 — 2026-09-11

**Focus:** shared configuration updates and a cleaner day-to-day Hyprland workflow.

### Added
- Persona-styled workspace tracker in the top-left.
- Workspaces `1 2 3 4 5` are always shown.
- When the active workspace is `6`–`10`, the tracker becomes `1 2 3 4 5 ... N`, with `N` highlighted.
- Workspace numbers are clickable and switch directly through Quickshell's Hyprland integration.
- `pboi` command-line updater.
- `pboi update` pulls the latest `main` branch, safely backs up the current configuration, applies the repo's Persona/Hyprland/Qt files, verifies the Hyprland config, restarts Quickshell when needed, and prints the version plus recent pulled commit messages.
- `pboi version` and `pboi changelog` helpers.
- A root `VERSION` marker for straightforward release tracking.
- Root `AGENTS.md` handoff guide with the project workflow, live paths, updater behavior, compatibility lessons, privilege model, and rules for continuing Personaboi work in a fresh ChatGPT conversation.

### Changed
- Made the workspace tracker smaller and moved it tighter to the top-left corner.
- Reduced the reserved workspace strip from 30px to 24px.
- Reduced only the Hyprland **top** outer gap to 6px while keeping right/bottom/left outer gaps at 20px, so tiled windows sit much closer to the workspace tracker without changing the other screen edges.
- Fresh installation now validates sudo once up front with `sudo -v`; privileged operations remain limited to system package/repository work and `/usr/local` CAVA installation.
- `setup/verify.sh` no longer invokes sudo for the NVIDIA DRM check when the sysfs value is readable as the current user.

### Fixed
- Fixed `pboi update` exiting with `tmpdir: unbound variable` after an otherwise successful update. Temporary update cleanup now uses a script-level path that remains valid when the EXIT trap runs under `set -u`.

### Included fixes since the initial fork setup
- System tray with native right-click menus and `UseQApplication`.
- Tray moved to the bottom-right.
- Media capsule hidden when no MPRIS player exists.
- Media previous/next placeholders replaced with proper symbols.
- 1.25-scale clock/font corrections.
- Standard `hyprland.conf` shader switching via `hyprctl keyword decoration:screen_shader` instead of Lua-only `hyprctl eval`.
- NVIDIA duplicate-cursor workaround used on the tested system.
- `hyprland-qtutils` added to the Ubuntu 26.04 bootstrap package set.

## v1.0 — 2026-09-10

**Focus:** make Persona-Quickshell reproducible on a fresh Ubuntu 26.04 Desktop installation.

- Ubuntu 26.04 Hyprland bootstrap and supporting session packages.
- Quickshell installation through the DankLinux PPA.
- CAVA core and Qt6 CavaMonitor plugin build/install steps.
- JetBrainsMono Nerd Font installation.
- Tested Hyprland config with 1920x1200 at 1.25 scaling.
- NVIDIA environment settings and documented package-conflict warning.
- Persona autostart, NetworkManager, Blueman and Polkit setup.
- Fresh-install and troubleshooting documentation.
