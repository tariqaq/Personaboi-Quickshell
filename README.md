<h1 align="center">Personaboi Quickshell — Ubuntu 26.04</h1>

A reproducible Ubuntu 26.04 + Hyprland setup based on **Yujon Pradhananga's Persona-Quickshell**, with the exact practical changes used on my 1920x1200 / 125% scaled NVIDIA laptop setup.

> Upstream project: [Yujonpradhananga/Persona-Quickshell](https://github.com/Yujonpradhananga/Persona-Quickshell)
>
> This repository remains a fork and keeps the original project's credits and MIT license. The goal here is to make the theme straightforward to reproduce on a fresh Ubuntu 26.04 Desktop install.

## What this fork adds

- Ubuntu 26.04 installation/bootstrap scripts.
- A tested Hyprland configuration with 125% display scaling.
- Persona autostart plus NetworkManager, Blueman, and Polkit session pieces.
- NVIDIA settings used on the tested RTX 4060 laptop.
- A Quickshell system tray with left-click and native right-click menus.
- `UseQApplication` so tray context menus actually work.
- The media capsule hides itself when no MPRIS player exists.
- Clock sizing and Linux font substitutions for the 1920x1200 @ 1.25 layout.
- JetBrainsMono Nerd Font installation for the battery/icon glyphs.
- A documented fix for the stationary duplicate NVIDIA cursor.
- A full troubleshooting record of the issues encountered during the Ubuntu setup.

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

Read the NVIDIA warning printed by the installer before the first Hyprland login, then log out, choose **Hyprland** in GDM, and sign in.

Full instructions: **[`docs/UBUNTU-26.04-INSTALL.md`](docs/UBUNTU-26.04-INSTALL.md)**

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
Assets/                     Original Persona visual assets
Data/                       Persona data/services
Layers/                     Persona UI layers + custom Tray.qml
Widgets/                    Persona widgets
shell.qml                   Quickshell root; includes UseQApplication + tray
setup/install.sh            Fresh Ubuntu 26.04 installer
setup/verify.sh             Post-install sanity checker
setup/hyprland.conf.in      Tested Hyprland config template
setup/qt.conf               CavaMonitor/QML environment paths
docs/UBUNTU-26.04-INSTALL.md
docs/CUSTOMIZATIONS.md
docs/TROUBLESHOOTING.md
```

## CAVA visualizer

The wallpaper visualizer uses Yujon Pradhananga's custom Qt6 CAVA plugin. The installer builds both the CAVA core library and the plugin automatically.

Manual upstream plugin repository:

- <https://github.com/Yujonpradhananga/Qt6-Cava-plugin>

## System tray

This fork adds `Layers/Tray.qml` using Quickshell's StatusNotifier support. It appears only when tray items exist and supports application activation plus native right-click menus. `shell.qml` uses `//@ pragma UseQApplication`, which is required for those platform menus.

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
