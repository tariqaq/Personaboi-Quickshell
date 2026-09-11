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
3. Keep the change compatible with Ubuntu 26.04 and the actually installed Hyprland/Quickshell versions.
4. Update `CHANGELOG.md` when the change is user-visible.
5. Do **not** bump `VERSION` unless the user explicitly says to start/bump a new version. Keep stacking normal fixes/features into the current version until then.
6. The user and friend then apply it with `pboi update`.
7. Prefer native Quickshell/Hyprland APIs over shell polling when available.
8. Preserve upstream Persona styling rather than adding generic Waybar-looking UI.

## Research and troubleshooting discipline

Do not over-engineer fixes before checking whether the compositor/shell community already has a simple, proven pattern.

For Hyprland, Quickshell, systemd, brightness/backlight, Wayland input, or similar integration work:

1. Check the **official docs first**, and use docs matching the installed version whenever syntax or behavior changed between releases. The tested Hyprland package is currently in the classic `hyprland.conf` era, so do not blindly copy newer Lua-only examples.
2. Search upstream GitHub issues/discussions and community examples for the exact behavior or failure before inventing a custom workaround.
3. Prefer the **smallest proven solution**. Do not add state machines, repeated sleeps, fullscreen resets, monitor geometry parsing, helper layers, or extra privilege logic unless there is evidence they are actually required.
4. If a fix has already failed once or twice, stop stacking more speculative changes. Reproduce the underlying command manually and inspect its real output first.
5. For CLI-driven behavior, test the exact command that the config/helper will run. Example: for a Hyprland multi-dispatch action, verify the exact `hyprctl` command manually before wrapping it in a script or bind.
6. Distinguish parser/argument problems from compositor behavior. Check the documented argument shape and shell quoting instead of guessing.
7. Do not claim a fix works until the user confirms it on the actual machine when the issue depends on compositor/runtime behavior.
8. Preserve working behavior while debugging. If the base toggle/action works but an enhancement does not, keep the base action reliable and isolate the enhancement.
9. Be careful with boolean data in shell/JQ glue. `jq`'s `//` operator treats `false` like a missing/null value, so do not use expressions like `.floating // empty` when `false` is a meaningful state. Read `.floating` directly or test for field existence explicitly.
10. In QML, do not animate `x`/`y` on an axis already controlled by anchors and expect it to move. Animate the relevant anchor margin (for example `anchors.topMargin`) or use a `Translate` transform instead. This mattered for the top-right brightness pill.

Hyprland's own documentation supports batching multiple control calls through `hyprctl --batch`, and versioned dispatcher docs should be consulted for the exact `togglefloating`, `resizeactive`, `centerwindow`, etc. syntax before patching.

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

If a future release needs a dependency/package migration, add it to `setup/update-hook.sh` so existing clients can prepare during `pboi update`. Migrations must be release-specific and idempotent; `pboi update` is not a general-purpose package upgrade command.

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
- `Super+V` toggles tiled/floating. The intended enhancement is that a newly floating window becomes visibly smaller and centered. The correct state read is `jq -r '.floating'`; do not use `.floating // empty`, because that turns the meaningful boolean `false` into no output and skips the resize branch. The current simple community-style action is `togglefloating; resizeactive exact 68% 70%; centerwindow` in one `hyprctl --batch` call.
- Brightness hotkeys remain under investigation on the tested MSI Stealth. `brightnessctl` works, and `evtest` shows `KEY_BRIGHTNESSDOWN/UP` from the ACPI `Video Bus`, but those events are not currently reaching Hyprland's bind path. Keep normal XF86 binds and the current fallback until a proper input-stack fix is confirmed; do not keep guessing new keycodes.
- The top-right brightness corner is a Quickshell overlay backed by `brightnessctl`. Ubuntu brightness permissions are handled through `brightness-udev` / normal group permissions rather than setuid or passwordless sudo. Its circle is top-anchored, so reveal/hide motion must use `anchors.topMargin` (or a transform), not `y`.

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

The tracker sits at the top-left in a thin full-width reserved shell strip so tiled windows remain below it. The Hyprland top outer gap is intentionally smaller than the other three edges to avoid excessive empty space below the tracker. The full-width strip is click-through except for the visible workspace pill, so it must not block application UI beneath it.

## Shared Hyprland controls

```text
Super+Q             Kitty
Super+E             GNOME Files / Nautilus
Super+B             default XDG browser
Super+C             close focused window
Super+V             tiled <-> floating; intended floating state is smaller + centered
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
- `setup/update-hook.sh` should only request sudo when a specific release migration genuinely requires a system-level package/file/group change.
- Release migration logic must check whether work is already complete before invoking privileged operations where practical.
- Avoid broad root shells and avoid `sudo` around `git`, `rsync` to `$HOME`, Quickshell, or Hyprland config operations.
- Do not solve desktop-runtime permission problems with setuid binaries or blanket passwordless sudo when a normal udev/group/polkit mechanism exists.

## User preferences for this project

- Work step-by-step and avoid repeating already completed commands.
- Keep instructions concise and practical.
- Before changing the repo, inspect the latest version of the target file.
- Check current official/versioned docs and search upstream/community solutions before inventing custom behavior.
- Prefer simple, already-proven community patterns over elaborate bespoke logic.
- When a local test is needed, give the exact command/file edit first; after confirmation, preserve it in the repo.
- When repeated fixes fail, stop guessing and collect direct runtime output from the smallest reproducible command.
- For shared changes, prefer updating GitHub and telling the user to run `pboi update` rather than asking both users to manually edit files.
- Personal-only app tweaks (for example Spotify/Discord launch flags or one-off screen recording setup) should not be added to Personaboi unless explicitly requested.
- Keep stacking changes into the current release version until the user explicitly asks for a version bump.

## New-chat instruction

If this file is being read in a new ChatGPT conversation, use it as the project handoff context, then inspect the current GitHub files before making changes because the repository may have advanced since this document was written.
