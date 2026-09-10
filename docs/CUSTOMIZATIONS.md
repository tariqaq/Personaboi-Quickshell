# Changes in Personaboi

This fork starts from Yujon Pradhananga's Persona-Quickshell and keeps the original visual design, while adding the changes used on the tested Ubuntu 26.04 laptop setup.

## Quickshell changes

### Native system tray

`Layers/Tray.qml` adds a StatusNotifier/AppIndicator tray. It supports:

- Discord, Steam, NetworkManager, Blueman, and other compatible tray items.
- left-click activation;
- middle-click secondary activation;
- right-click native context menus through `QsMenuAnchor`;
- automatic hiding when no tray items exist.

The tray uses `WlrLayer.Bottom`, so ordinary application windows cover it instead of the tray floating above every application.

`shell.qml` includes `//@ pragma UseQApplication`. This is required for Qt platform/native menus such as the tray context menus.

### Media capsule

`Layers/Capsule.qml` hides the entire media capsule when there is no MPRIS player instead of leaving the large `No Media` panel on the desktop.

### 125% clock layout

`Layers/Clock.qml` is adjusted for the tested 1920x1200 laptop panel at Hyprland scale `1.25`:

- the original 500x200 clock surface is 400x160;
- the internal `vw` factor is divided by 1.25;
- Microsoft YaHei is replaced with Noto Sans;
- Bahnschrift Condensed is replaced with Noto Sans Condensed;
- the battery/icon line continues to use JetBrainsMono Nerd Font.

## Hyprland changes

The supplied `setup/hyprland.conf.in` reproduces the working configuration:

- generic preferred display mode at 125% scale;
- Kitty and Dolphin defaults;
- Persona autostart;
- NetworkManager, Blueman, and KDE Polkit agent autostart;
- NVIDIA environment variables used on the tested RTX 4060 laptop;
- `cursor:no_hardware_cursors = 0`, which fixed a stationary duplicate cursor on the tested NVIDIA setup;
- Super+R opens the Persona launcher;
- Super+Print selects an area with `slurp`, captures it with `grim`, and copies it with `wl-copy`.

## Persona blade interaction

The left-side Calendar / Stats / Shaders / Power controls are not ordinary buttons. Expand the blade menu, then drag the desired blade to the right and release it. A normal click does not trigger the action.
