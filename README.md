<h1 align="center">Personaboi Quickshell — Ubuntu 26.04</h1>

A reproducible Ubuntu 26.04 + Hyprland setup based on **Yujon Pradhananga's Persona-Quickshell**, with the practical fixes and shared configuration used on this setup.

> Upstream project: [Yujonpradhananga/Persona-Quickshell](https://github.com/Yujonpradhananga/Persona-Quickshell)
>
> This repository remains a fork and keeps the original project's credits and MIT license. The goal here is to make the theme straightforward to reproduce and keep multiple machines in sync.

## Current version

**v1.6** — native Persona notifications plus the completed wallpaper performance/power optimization pass.

See the full release history in **[`CHANGELOG.md`](CHANGELOG.md)**.

For continuing this project in a fresh ChatGPT/agent conversation, start by reading **[`AGENTS.md`](AGENTS.md)**.

### v1.6 focus

- Native Quickshell notification daemon using the standard desktop D-Bus notification interface.
- Persona-themed top-right notification toasts with icons/images, urgency styling, actions, hover-paused timeout, and dismiss controls.
- Browser/app notifications are handled by the shell instead of appearing as tiled helper windows.
- Wallpaper animation work is capped near 60 Hz while Hyprland/apps remain at native refresh.
- Wallpaper rendering and CAVA pause while tiled/fullscreen windows cover the desktop; floating windows keep it live.
- CAVA keeps all 50 bars, paints at about 30 Hz, sleeps on silence, and pauses capture while covered.
- Mouse parallax is applied on the wallpaper cadence rather than every raw pointer event.
- Required wallpaper intermediate textures remain native-resolution after the 80% experiment was reverted for visible blur.
- Media capsule ignores metadata-less idle browser MPRIS players but stays visible for real paused tracks.

## What this fork adds

- Ubuntu 26.04 installation/bootstrap scripts.
- Tested Hyprland configuration with 125% display scaling.
- Persona autostart plus NetworkManager, Blueman, and Polkit session pieces.
- NVIDIA settings used on the tested RTX 4060 laptop.
- Quickshell system tray with native right-click menus.
- Persona workspace tracker and click-to-switch workspaces.
- Media capsule that hides when no meaningful MPRIS media exists, while preserving paused tracks.
- Native Persona notification daemon and top-right notification toasts.
- Clock sizing and Linux font substitutions for 1920x1200 @ 1.25.
- JetBrainsMono Nerd Font installation for icon/battery glyphs.
- Standard `hyprland.conf` shader switching via `hyprctl keyword` instead of upstream Lua-only runtime commands.
- Per-shader intensity controls implemented through runtime-generated cache shaders.
- 10-day Persona calendar with locally calculated moon phases.
- Expanded system telemetry panel.
- Top-right Persona brightness control backed by `brightnessctl`.
- Auto-dismissing left Persona drawer.
- Optimized live wallpaper/CAVA pipeline for lower idle GPU power without reducing native image sharpness.
- `pboi` updater for keeping multiple installs on the same repo version.

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

Run the installer as your normal user, not with `sudo`; it requests sudo only for system-level steps.

The installer also installs the updater to `~/.local/bin/pboi`.

Full instructions: **[`docs/UBUNTU-26.04-INSTALL.md`](docs/UBUNTU-26.04-INSTALL.md)**

## Updating an existing Personaboi install

```bash
pboi update
```

Run `pboi` as the normal desktop user, never with `sudo`.

The updater fetches `main`, runs any release migration hook, backs up the live configuration, applies the repo Persona/Hyprland/Qt files, verifies the Hyprland config, reloads Hyprland, restarts Quickshell when appropriate, and records the installed version/commit.

Useful commands:

```bash
pboi version
pboi update
pboi changelog
```

### One-time updater bootstrap for installs made before v1.1

```bash
cd ~/Personaboi-Quickshell
git pull
mkdir -p ~/.local/bin
install -Dm755 setup/pboi ~/.local/bin/pboi
export PATH="$HOME/.local/bin:$PATH"
pboi update
```

## Native notifications

`Layers/Notifications.qml` registers Quickshell as the desktop notification server using `org.freedesktop.Notifications`. Applications such as browsers and messaging clients can therefore send normal desktop notifications directly to Personaboi.

Notifications appear as Persona-styled top-right layer-shell toasts rather than normal Hyprland client windows, so they do not enter the tiling layout. Toasts use the existing navy/cyan palette, show an app/image icon where available, support advertised actions, pause timeout while hovered, and can be dismissed manually.

Only one notification daemon should own the desktop notification D-Bus service. Do not autostart dunst, mako, swaync, or another notification daemon alongside the native Personaboi notification layer unless the Personaboi layer is disabled.

## Wallpaper optimization

The live wallpaper keeps Hyprland and applications at the display's native refresh rate while its own animated shader state is updated near 60 Hz. When the active workspace contains only tiled/fullscreen windows, Quickshell wallpaper updates and CAVA capture pause; if any floating window is present, the wallpaper stays live.

CAVA retains all 50 bars but paints its Canvas at about 30 Hz, sleeps after near-silence, and resumes automatically when meaningful audio returns. Mouse parallax input is collected immediately but applied only on the wallpaper cadence. The two required shader intermediate textures remain native-resolution because the tested 80% scale produced visible blur.

## Workspace tracker

On workspaces 1–5:

```text
1  2  [3]  4  5
```

On workspaces 6–10:

```text
1  2  3  4  5  ...  [9]
```

The reserved full-width top strip only accepts pointer input over the visible workspace pill; the rest passes clicks through to applications below.

## Shader intensity

The shader menu keeps the original Persona layout and adds an intensity rail for all three effects. Hyprland's classic configuration exposes `decoration:screen_shader` as a file path. Personaboi therefore generates a temporary shader at:

```text
~/.cache/personaboi/shaders/active.glsl
```

with the selected intensity baked into a constant, then points Hyprland at that runtime file. The source shaders in the repository remain unchanged at runtime.

## Top-right brightness control

A tiny hotspot sits on the top-right edge. Pushing the pointer into it reveals a Persona-style circular brightness control. Clicking the circle expands a compact slider below it. Dragging the slider calls `brightnessctl set N%`; because the existing Brightness OSD reads the backlight device directly, it also reflects slider-driven changes.

The hidden state occupies only a very small edge trigger and reserves no workspace area.

## Moon phase model

Both the desktop clock moon and the calendar moon icons use `Data/Time.qml`. The model uses the mean synodic month (29.53059 days) from a reference new moon and calculates phase from the requested date. It is lightweight, offline, and suitable for the visual indicator, but it is not intended as a high-precision astronomical ephemeris.

## Important controls

| Binding / gesture | Action |
|---|---|
| `Super+Q` | Kitty terminal |
| `Super+E` | GNOME Files (`nautilus`) |
| `Super+B` | Default web browser |
| `Super+C` | Close focused window |
| `Super+V` | Toggle tiled/floating; newly floating windows are forced smaller and centered |
| `Super+R` | Persona launcher |
| `Super+M` | Leave Hyprland |
| `Super+Print` | Select area and copy screenshot |
| Drag Persona blade right | Activate Calendar / Stats / Shaders / Power |
| Push pointer to top-right edge | Reveal brightness control |

## Repository layout

```text
VERSION                    Current Personaboi version
CHANGELOG.md               Version history
AGENTS.md                  ChatGPT/agent project handoff context
Assets/                    Original Persona assets + screen shaders
Data/                      Persona data/services including shared time/moon model
Layers/                    Persona UI layers, including Notifications.qml
Scripts/                   Runtime helpers such as floating/shader controls
Widgets/                   Persona widgets and system-info providers
shell.qml                  Quickshell root
setup/install.sh           Fresh Ubuntu 26.04 installer
setup/pboi                 Shared updater command
setup/update-hook.sh       Release migration hook
setup/verify.sh            Post-install sanity checker
setup/hyprland.conf.in     Tested Hyprland config template
setup/qt.conf              CavaMonitor/QML environment paths
```

## CAVA visualizer

The wallpaper visualizer uses Yujon Pradhananga's custom Qt6 CAVA plugin. The installer builds both the CAVA core library and the plugin automatically.

## System tray

`Layers/Tray.qml` uses Quickshell's StatusNotifier support. It appears only when tray items exist and supports application activation plus native right-click menus. `shell.qml` uses `//@ pragma UseQApplication` for those platform menus.

## Notes about NVIDIA

The supplied Hyprland config contains the NVIDIA environment settings that worked on the tested laptop. `nvidia_drm` modesetting was enabled (`Y`).

**Do not blindly install `libnvidia-egl-gbm1`.** On the tested Ubuntu 26.04 NVIDIA 595 packages, doing so caused APT to remove the NVIDIA driver metapackage and `libnvidia-gl-*` packages.

## Upstream credits

Original Persona-Quickshell by **Yujon Pradhananga**.

The original project credits include the Steam Workshop wallpaper, `snes19xx/surface-dots` greyscale shader inspiration, `Rexcrazy804/Zaphkiel` media-player implementation, and `blairxu13/persona3-website` inspiration.

## License

MIT, following the upstream project.
