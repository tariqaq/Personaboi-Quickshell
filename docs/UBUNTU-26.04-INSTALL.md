# Ubuntu 26.04 installation

This guide reproduces the tested Personaboi desktop on a fresh **Ubuntu 26.04 Desktop** install.

Current Personaboi release: **v1.1**. See [`../CHANGELOG.md`](../CHANGELOG.md) for release notes.

## Tested snapshot

- Ubuntu 26.04 (Resolute)
- Hyprland 0.53.3 (`0.53.3+ds-4` from Ubuntu Universe)
- Quickshell 0.3.1 (`0.3.1ppa1` from `ppa:avengemedia/danklinux`)
- NVIDIA 595.91.07 open-kernel driver on an RTX 4060 Laptop GPU
- internal panel: 1920x1200 @ 165 Hz
- Hyprland scale: 1.25

The setup keeps GNOME installed as a fallback session.

## Recommended: scripted install

From the cloned repository:

```bash
chmod +x setup/install.sh setup/verify.sh
./setup/install.sh
```

Read the NVIDIA notes printed at the end before logging into Hyprland.

## What the installer does

### 1. Hyprland and desktop utilities

It enables Ubuntu Universe and installs Hyprland plus the pieces a bare compositor session does not provide by itself: portal support, Hyprland Qt utilities, terminal, file manager, brightness/media controls, screenshots, NetworkManager/Blueman applets, Polkit authentication, Qt Wayland support, and fonts.

### 2. Quickshell

It enables the DankLinux PPA and installs the stable `quickshell` package plus the Qt/QML modules used by Persona.

### 3. CAVA core library

It clones `karlstav/cava`, builds `libcava.so`, and installs:

```text
/usr/local/lib/libcava.so
/usr/local/include/cava/cavacore.h
```

### 4. Qt6 CavaMonitor plugin

It builds Yujon Pradhananga's `Qt6-Cava-plugin` into:

```text
~/.local/lib/qt6/qml/CavaMonitor/
```

### 5. JetBrainsMono Nerd Font

It downloads the current JetBrainsMono Nerd Font release into the user's local font directory and refreshes Fontconfig.

### 6. Dotfiles and updater

It installs this repository as:

```text
~/.config/quickshell/persona/
```

and installs:

```text
~/.config/hypr/hyprland.conf
~/.config/environment.d/qt.conf
~/.local/bin/pboi
```

The stored Hyprland file is a template; the installer substitutes the current user's home directory so the setup is not tied to `/home/trq`.

The installer also records the installed Personaboi version/commit under:

```text
~/.local/share/personaboi/
```

## NVIDIA before first login

If Ubuntu already has a working NVIDIA driver, keep it. Confirm DRM modesetting:

```bash
sudo cat /sys/module/nvidia_drm/parameters/modeset
```

The tested setup prints:

```text
Y
```

Do not install `libnvidia-egl-gbm1` if APT says doing so will remove your NVIDIA driver metapackage or `libnvidia-gl-*` packages.

## First Hyprland login

Log out of GNOME. In GDM choose the **Hyprland** session and sign in.

Useful bindings in the supplied configuration:

| Binding | Action |
|---|---|
| `Super+Q` | Kitty |
| `Super+E` | Dolphin |
| `Super+C` | Close focused window |
| `Super+V` | Toggle floating/tiled |
| `Super+R` | Persona app launcher |
| `Super+M` | Exit Hyprland |
| `Super+Arrow` | Move focus |
| `Super+1..0` | Switch workspace |
| `Super+Shift+1..0` | Move window to workspace |
| `Super+Print` | Select screenshot area and copy it |

Laptop brightness and media keys use `brightnessctl`, `wpctl`, and `playerctl`.

## Workspace tracker

Personaboi v1.1 adds a compact workspace tracker in the top-left.

For workspaces 1–5 it shows the fixed set:

```text
1  2  [3]  4  5
```

If workspace 6–10 is active, it dynamically appends that workspace:

```text
1  2  3  4  5  ...  [9]
```

Each displayed number can also be clicked to switch workspace.

## Persona controls

The left-side Persona blades are **drag-to-activate**. Click the `:3` control to expand them, drag Calendar / Stats / Shaders / Power to the right, then release.

The Power blade opens the animated Persona power screen; its actions use `loginctl`.

## Keeping multiple machines in sync

Personaboi v1.1 includes a small updater command. After installation, use:

```bash
pboi update
```

It downloads the latest `main` branch, backs up the current live setup, applies the new Persona/Hyprland/Qt configuration, verifies Hyprland, reloads/restarts the relevant session pieces, and prints the recent commit messages pulled.

Other commands:

```bash
pboi version
pboi changelog
```

If a machine was installed before v1.1, install the updater once from an existing repo clone:

```bash
cd ~/Personaboi-Quickshell
git pull
mkdir -p ~/.local/bin
install -Dm755 setup/pboi ~/.local/bin/pboi
export PATH="$HOME/.local/bin:$PATH"
pboi update
```

After that, the normal workflow on both machines is simply `pboi update`.

## Verify after installation

Run:

```bash
./setup/verify.sh
```

See `docs/TROUBLESHOOTING.md` for the exact issues encountered while building this Ubuntu setup.
