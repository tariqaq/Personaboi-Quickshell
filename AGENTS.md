# Personaboi ChatGPT / Agent Handoff Guide

This file is the persistent project context for continuing Personaboi work in a new ChatGPT conversation.

## Project identity

- Repository: `tariqaq/Personaboi-Quickshell`
- Upstream: `Yujonpradhananga/Persona-Quickshell`
- Target OS: Ubuntu 26.04 Desktop
- Desktop stack: Hyprland + Quickshell
- Current fork version: read root `VERSION`
- Shared user workflow: both Tariq and his friend run the same repo-managed configuration.

## Core rule for future changes

Treat the GitHub repository as the source of truth.

Do **not** make a one-off local-only customization unless the user explicitly says it is personal-only. For shared Personaboi changes:

1. Inspect the current repo file(s) first.
2. Patch the repo directly on `main` unless the user asks for a branch/PR.
3. Keep the change compatible with Ubuntu 26.04 and standard `hyprland.conf` syntax.
4. Update `CHANGELOG.md` when the change is user-visible.
5. Bump `VERSION` only when the user explicitly declares a new release/version or the change clearly belongs to a new release.
6. The user and friend then apply it with `pboi update`.
7. Prefer native Quickshell/Hyprland APIs over shell polling when available.
8. Preserve upstream Persona styling rather than adding generic Waybar-looking UI.

## Update workflow

The normal update command is:

```bash
pboi update
```

The updater lives at `setup/pboi` and is installed to:

```text
~/.local/bin/pboi
```

It:

- clones the latest `main` branch,
- runs `setup/update-hook.sh` if present,
- backs up the current live Personaboi/Hyprland/Qt config,
- applies the repo version of the shared config,
- installs the newest `pboi` updater over itself,
- verifies the Hyprland config,
- reloads Hyprland,
- restarts Quickshell when it was already running,
- records the installed commit/version,
- prints pulled commit messages.

State/backups live under:

```text
~/.local/share/personaboi/
```

If a future release needs a dependency/package migration, add it to `setup/update-hook.sh` so existing clients can prepare during `pboi update`.

## Fresh install workflow

Fresh machines use:

```bash
git clone https://github.com/tariqaq/Personaboi-Quickshell.git
cd Personaboi-Quickshell
chmod +x setup/install.sh setup/verify.sh
./setup/install.sh
```

The installer:

- enables Ubuntu Universe,
- installs Hyprland and session/runtime packages,
- installs Quickshell from `ppa:avengemedia/danklinux`,
- builds `libcava.so`,
- builds the Qt6 CavaMonitor plugin,
- installs JetBrainsMono Nerd Font,
- installs Personaboi into `~/.config/quickshell/persona`,
- writes the shared Hyprland config from `setup/hyprland.conf.in`,
- writes `~/.config/environment.d/qt.conf`,
- installs `pboi`.

## Important live paths

```text
~/.config/quickshell/persona/
~/.config/hypr/hyprland.conf
~/.config/environment.d/qt.conf
~/.local/bin/pboi
```

Repo equivalents:

```text
Layers/
shell.qml
setup/hyprland.conf.in
setup/qt.conf
setup/pboi
setup/install.sh
setup/update-hook.sh
setup/verify.sh
VERSION
CHANGELOG.md
```

## Current important customizations

- `shell.qml` uses `//@ pragma UseQApplication` so native tray context menus work.
- `Layers/Tray.qml` is a custom Quickshell StatusNotifier tray, currently bottom-right.
- `Layers/Capsule.qml` hides when no MPRIS player exists.
- Previous/next media controls use Unicode symbols instead of the missing Material Symbols font.
- `Layers/Clock.qml` was resized for 1920x1200 at 1.25 scaling and uses Linux-available fonts.
- JetBrainsMono Nerd Font is installed for icon/battery glyphs.
- `Layers/OptionsList.qml` uses normal Hyprland runtime config commands:

```text
hyprctl keyword decoration:screen_shader ...
```

  Do **not** revert this to upstream's Lua-only `hyprctl eval hl.config(...)` form.
- NVIDIA duplicate cursor on the tested setup is fixed with:

```ini
cursor {
    no_hardware_cursors = 0
}
```

  Do not change this back to `1` for this tested configuration unless troubleshooting a different GPU.
- Do not install standalone `libnvidia-egl-gbm1` if APT proposes removing the Ubuntu NVIDIA driver metapackage / `libnvidia-gl-*` packages.

## Workspace tracker

`Layers/Workspaces.qml` is the Personaboi workspace indicator.

Behavior:

```text
1 2 3 4 5
```

The active workspace is highlighted. If the current workspace is 6-10:

```text
1 2 3 4 5 ... [N]
```

Example:

```text
1 2 3 4 5 ... [9]
```

Numbers are clickable and switch workspace via Quickshell's `Hyprland.dispatch()`.

The tracker sits at the top-left in a thin full-width reserved shell strip so tiled windows remain below it. The Hyprland top outer gap is intentionally smaller than the other three edges to avoid excessive empty space below the tracker.

## Shared Hyprland controls

```text
Super+Q             Kitty
Super+E             Dolphin
Super+C             close focused window
Super+V             tiled <-> floating
Super+R             Persona launcher
Super+M             leave Hyprland
Super+Arrow         focus direction
Super+1..9          workspace 1..9
Super+0             workspace 10
Super+Shift+1..9    move window to workspace 1..9
Super+Shift+0       move window to workspace 10
Super+Print         select screenshot area and copy to clipboard
```

Persona side blades are drag-to-activate: expand `:3`, drag Calendar / Stats / Shaders / Power to the right, then release.

## Lua compatibility lesson

Upstream's README/config examples use a Lua Hyprland provider in places. This fork uses a standard text `hyprland.conf`.

The previously discovered runtime Lua dependency was shader switching in `OptionsList.qml`; it has already been converted to `hyprctl keyword`.

Workspace switching, Wi-Fi controls, brightness, MPRIS, and the power menu do not depend on Lua in the current fork.

## Privilege model

- Normal Personaboi runtime and `pboi update` should run as the regular user.
- `pboi` must **not** be run with `sudo`.
- Repo-managed user config belongs under `$HOME`; do not create those files as root.
- Fresh install requires sudo only for system package/repository operations and `/usr/local` CAVA installation.
- `setup/update-hook.sh` should only request sudo when a future migration genuinely requires a system-level package/file change.
- Avoid broad root shells and avoid `sudo` around `git`, `rsync` to `$HOME`, Quickshell, or Hyprland config operations.

## User preferences for this project

- Work step-by-step and avoid repeating already completed commands.
- Keep instructions concise and practical.
- Before changing the repo, inspect the latest version of the target file.
- When a local test is needed, give the exact command/file edit first; after confirmation, preserve it in the repo.
- For shared changes, prefer updating GitHub and telling the user to run `pboi update` rather than asking both users to manually edit files.
- Personal-only app tweaks (for example Spotify/Discord launch flags or one-off screen recording setup) should not be added to Personaboi unless explicitly requested.

## New-chat instruction

If this file is being read in a new ChatGPT conversation, use it as the project handoff context, then inspect the current GitHub files before making changes because the repository may have advanced since this document was written.
