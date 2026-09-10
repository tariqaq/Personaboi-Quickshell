# Changelog

All notable Personaboi changes are tracked here. Versions describe this Ubuntu 26.04 fork, not upstream Persona-Quickshell releases.

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

### Changed
- Made the workspace tracker smaller and moved it tight to the top-left corner.
- The workspace layer now reserves a thin 30px strip across the top of the monitor, so tiled windows begin below the tracker instead of rendering underneath it.

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
