# Troubleshooting

## A second cursor is frozen in the middle of the screen

On the tested NVIDIA laptop, forcing software cursors did not help. The working configuration was:

```ini
cursor {
    no_hardware_cursors = 0
}
```

Reload with `hyprctl reload`, or log out and back in if the old hardware cursor plane remains visible.

## Tray icons show but right-click menus do not open

Make sure the first lines of `shell.qml` include:

```qml
//@ pragma UseQApplication
```

Without this, Quickshell logs an error saying `QsMenuAnchor.open()` cannot be called because Quickshell was not started in QApplication mode.

## Tray is empty

Check whether the StatusNotifier watcher has items:

```bash
busctl --user get-property \
  org.kde.StatusNotifierWatcher \
  /StatusNotifierWatcher \
  org.kde.StatusNotifierWatcher \
  RegisteredStatusNotifierItems
```

NetworkManager and Blueman should normally register when their applets are running.

## Persona power menu does not open

The Power blade is drag-to-activate. Expand the left-side blade menu, drag `Power` to the right by roughly 50 pixels or more, then release. The power screen itself uses `loginctl` for poweroff, reboot, and logout.

## Media capsule says No Media

This fork intentionally hides the capsule when no MPRIS player exists. Start Spotify or another MPRIS-capable player and it should appear.

## NVIDIA package warning

Do **not** blindly install `libnvidia-egl-gbm1` on Ubuntu 26.04. On the tested NVIDIA 595 stack, APT proposed removing `nvidia-driver-595-open` and `libnvidia-gl-595`. If APT proposes removing your active driver metapackage, answer `n` and keep the normal Ubuntu NVIDIA driver stack.

Tested driver snapshot: NVIDIA 595.91.07 with `nvidia_drm` modeset set to `Y`.

## Quickshell CAVA warnings

The CAVA visualizer requires both the CAVA core library and the custom Qt6 CavaMonitor plugin. Re-run `setup/install.sh`, or verify these exist:

```text
/usr/local/lib/libcava.so
/usr/local/include/cava/cavacore.h
~/.local/lib/qt6/qml/CavaMonitor/libcavamonitorplugin.so
```

## Known upstream font warnings

The exported working setup still contains upstream QML references to local `Assets/fonts/BebasNeue-Regular.ttf` and `Assets/fonts/Montserrat-Light.ttf`, but those files are not present in the upstream repository. Quickshell may therefore log FontLoader warnings in the Options/Stats UI. The main clock in this fork was changed to Noto Sans/Noto Sans Condensed so it does not rely on Microsoft YaHei or Bahnschrift.
