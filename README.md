<h1 align="center">Personaboi Quickshell — Ubuntu 26.04</h1>

A reproducible Ubuntu 26.04 + Hyprland setup based on **Yujon Pradhananga's Persona-Quickshell**, with the practical fixes and shared configuration used on this setup.

> Upstream project: [Yujonpradhananga/Persona-Quickshell](https://github.com/Yujonpradhananga/Persona-Quickshell)
>
> This repository remains a fork and keeps the original project's credits and MIT license. The goal here is to make the theme straightforward to reproduce and keep multiple machines in sync.

## Current version

**v1.1** — workspace tracking + shared updater workflow.

See the full release history in **[`CHANGELOG.md`](CHANGELOG.md)**.

### v1.1 focus

- New Persona-styled workspace tracker in the top-left.
- Workspaces `1 2 3 4 5` stay visible at all times.
- If the active workspace is `6`–`10`, it becomes `1 2 3 4 5 ... N`, with `N` highlighted.
- Workspace numbers are clickable.
- New `pboi update` command keeps the live Persona files, Hyprland config, and Qt environment config synced with this repository.
- Updates are backed up before applying, Hyprland config is verified, Quickshell is restarted when appropriate, and the pulled commit messages are shown afterward.

## What this fork adds

- Ubuntu 26.04 installation/bootstrap scripts.
- A tested Hyprland configuration with 125% display scaling.
- Persona autostart plus NetworkManager, Blueman, and Polkit session pieces.
- NVIDIA settings used on the tested RTX 4060 laptop.
- A Quickshell system tray with left-click and native right-click menus.
- `UseQApplication` so tray context menus actually work.
- Persona workspace tracker and click-to-switch workspaces.
- The media capsule hides itself when no MPRIS player exists.
- Proper previous/next media symbols instead of missing-font placeholder text.
- Clock sizing and Linux font substitutions for the 1920x1200 @ 1.25 layout.
- JetBrainsMono Nerd Font installation for battery/icon glyphs.
- Standard `hyprland.conf` shader switching with `hyprctl keyword` instead of Lua-only `hyprctl eval`.
- A documented fix for the stationary duplicate NVIDIA cursor.
- `pboi` updater for keeping multiple installs on the same repo version.
- A troubleshooting record of the issues encountered during the Ubuntu setup.

## Tested environment

| Component | Tested value |
|---|---|
| OS | Ubuntu 26.04 (Resolute) |
| Hyprland | 0.53.3 / Ubuntu package `0.53.3+ds-4` |
| Quickshell | 0.3.1 / PPA package `0.3.1ppa1` |
| GPU | NVIDIA GeForce RTX 4060 Laptop GPU |
| NVIDIA driver | 595.91.07 open-kernel stack |
| Display | 1920x1200 @ 165 Hz |
| Scale | 1.25 |

Hyprland is installed from Ubuntu's **Universe** repository. Quickshell is installed from the **AvengeMedia/DankLinux PPA**.

## Fresh-install quick path

Keep the normal Ubuntu GNOME desktop installed as a fallback.

```bash
git clone https://github.com/tariqaq/Personaboi-Quickshell.git
cd Personaboi-Quickshell
chmod +x setup/install.sh setup/verify.sh
./setup/install.sh
```

The installer also installs the updater to:

```text
~/.local/bin/pboi
```

After the normal logout/login into Hyprland, `pboi` should be available directly in the terminal.

Full instructions: **[`docs/UBUNTU-26.04-INSTALL.md`](docs/UBUNTU-26.04-INSTALL.md)**

## Updating an existing Personaboi install

Once `pboi` is installed, keeping machines synced is simply:

```bash
pboi update
```

The updater:

1. Fetches the latest `main` branch from this repository.
2. Detects the newest Personaboi version and commit.
3. Backs up the previous live configuration to `~/.local/share/personaboi/backups/previous/`.
4. Applies the latest Persona tree to `~/.config/quickshell/persona/`.
5. Applies the shared `hyprland.conf` template and `qt.conf`.
6. Verifies the Hyprland configuration before finishing.
7. Reloads Hyprland and restarts Quickshell when they are running.
8. Prints the new version and recent commit messages that were pulled.

Useful updater commands:

```bash
pboi version
pboi update
pboi changelog
```

### One-time updater bootstrap for installs made before v1.1

If the machine was installed before `pboi` existed but still has a clone of this repository:

```bash
cd ~/Personaboi-Quickshell
git pull
mkdir -p ~/.local/bin
install -Dm755 setup/pboi ~/.local/bin/pboi
export PATH="$HOME/.local/bin:$PATH"
pboi update
```

After that, future changes only need `pboi update`.

## Workspace tracker

The top-left tracker is intentionally compact instead of adding a full conventional bar.

On workspaces 1–5:

```text
1  2  [3]  4  5
```

On workspaces 6–10:

```text
1  2  3  4  5  ...  [9]
```

The active workspace uses the existing Persona cyan/blue palette. Clicking any displayed workspace number switches to it directly through Quickshell's Hyprland service.

## Important controls

| Binding / gesture | Action |
|---|---|
| `Super+Q` | Kitty terminal |
| `Super+E` | Dolphin file manager |
| `Super+C` | Close focused window |
| `Super+V` | Toggle tiled/floating |
| `Super+R` | Persona launcher |
| `Super+M` | Leave Hyprland |
| `Super+Print` | Select area and copy screenshot |
| Drag Persona blade right | Activate Calendar / Stats / Shaders / Power |

The Persona Power screen is opened by expanding the left-side blades and **dragging the Power blade to the right**. It is not activated by a normal click.

## Repository layout

```text
VERSION                    Current Personaboi version
CHANGELOG.md               Version history and release focus
Assets/                    Original Persona visual assets
Data/                      Persona data/services
Layers/                    Persona UI layers + custom Tray/Workspaces
Widgets/                   Persona widgets
shell.qml                  Quickshell root
setup/install.sh           Fresh Ubuntu 26.04 installer
setup/pboi                 Shared updater command
setup/verify.sh            Post-install sanity checker
setup/hyprland.conf.in     Tested Hyprland config template
setup/qt.conf              CavaMonitor/QML environment paths
docs/UBUNTU-26.04-INSTALL.md
docs/CUSTOMIZATIONS.md
docs/TROUBLESHOOTING.md
```

## CAVA visualizer

The wallpaper visualizer uses Yujon Pradhananga's custom Qt6 CAVA plugin. The installer builds both the CAVA core library and the plugin automatically.

Manual upstream plugin repository:

- <https://github.com/Yujonpradhananga/Qt6-Cava-plugin>

## System tray

This fork adds `Layers/Tray.qml` using Quickshell's StatusNotifier support. It appears only when tray items exist and supports application activation plus native right-click menus. `shell.qml` uses `//@ pragma UseQApplication`, which is required for those platform menus. The shared layout currently places it in the bottom-right.

## Notes about NVIDIA

The supplied Hyprland config contains the NVIDIA environment settings that worked on the tested laptop. `nvidia_drm` modesetting was enabled (`Y`).

**Do not blindly install `libnvidia-egl-gbm1`.** On the tested Ubuntu 26.04 NVIDIA 595 packages, doing so caused APT to remove the NVIDIA driver metapackage and `libnvidia-gl-595`; the driver stack then had to be restored. See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## Upstream credits

Original Persona-Quickshell by **Yujon Pradhananga**.

The original project credits:

- Wallpaper: Steam Workshop item 3151551777.
- Greyscale shader: `snes19xx/surface-dots`.
- Media-player album-art implementation: `Rexcrazy804/Zaphkiel`.
- Persona website inspiration: `blairxu13/persona3-website`.

## License

MIT, following the upstream project. See the repository license/history for the original work and attribution.
