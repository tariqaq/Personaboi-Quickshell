# Tested snapshot

This fork was captured from the working Ubuntu 26.04 installation used to prepare the reproducible setup.

## Display

```text
Monitor: eDP-1
Panel: AU Optronics 0x15A7
Physical size: 300x190 mm
Mode: 1920x1200 @ 165.002 Hz
Scale: 1.25
Available modes:
  1920x1200 @ 165.00 Hz
  1920x1200 @ 60.02 Hz
```

The shipped Hyprland template intentionally uses `preferred` rather than hard-coding `eDP-1`, so it can survive a different connector name while preserving the 1.25 scale.

## Hyprland

```text
Hyprland 0.53.3
Ubuntu package: 0.53.3+ds-4
```

## Quickshell

```text
Quickshell 0.3.1
Ubuntu/PPA package: 0.3.1ppa1
```

## NVIDIA

```text
GPU: NVIDIA GeForce RTX 4060 Laptop GPU
Driver: 595.91.07
Kernel-module DRM modeset: Y
Ubuntu driver package: nvidia-driver-595-open 595.91.07-0ubuntu0.26.04.1
libnvidia-egl-wayland1: 1.1.21-1
```

## Other captured package versions

```text
blueman                     2.4.4-1build1
brightnessctl               0.5.1-3.1build1
dolphin                     4:25.12.3-0ubuntu1
grim                        1.4.0+ds-2build3
kitty                       0.45.0-1build1
network-manager-gnome       1.36.0-4ubuntu1
pavucontrol                 6.1-1build1
playerctl                   2.4.1-3build1
polkit-kde-agent-1          4:6.6.4-0ubuntu1
qt6-wayland                 6.10.2-4
slurp                       1.6.0-1
wl-clipboard                2.2.1-2build1
xdg-desktop-portal-hyprland 1.3.11-1build2
```

These versions are a **reference snapshot**, not strict pins. The installer uses Ubuntu 26.04 repositories and the configured Quickshell PPA so security/point updates can still be received.
