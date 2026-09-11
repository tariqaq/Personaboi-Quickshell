# Changelog

All notable Personaboi changes are tracked here. Versions describe this Ubuntu 26.04 fork, not upstream Persona-Quickshell releases.

## v1.4 — 2026-09-11

**Focus:** direct brightness control and tougher window-state handling.

### Added
- Persona-styled top-right brightness hotspot. Pushing the pointer into the top-right top edge reveals a small brightness circle; clicking it drops a compact slider panel.
- Brightness slider writes directly through `brightnessctl set N%`, with a short throttle while dragging. The existing Brightness OSD continues to reflect the changed backlight value.
- The brightness hotspot follows the same basic reveal/auto-hide behavior as the left-side Persona drawer, but without the ticket blades.
- Ubuntu `brightness-udev` support and `video` group migration for proper unprivileged backlight control instead of embedding `sudo` or passwordless root access in the UI.

### Changed
- `Super+V` now uses the simpler classic Hyprland batch pattern used successfully by other 0.x users: `togglefloating`, `resizeactive exact 68% 70%`, then `centerwindow` in one compositor batch. Toggling an already-floating window simply returns it to tiled mode.
- The brightness corner now uses a fixed shell surface plus a click-through input mask. This lets the circle animate fully off-screen without clipping while preventing the invisible surface from blocking application clicks.
- The brightness panel now auto-dismisses after pointer inactivity. This applies both when the circle is merely revealed and after the slider is opened or adjusted; the user no longer has to click the brightness circle again to close it.

### Fixed
- Fixed the brightness slider failing on systems where `brightnessctl` required sudo. Ubuntu 26.04 packages the permission rules separately as `brightness-udev`; existing installs now receive that package and the desktop user is added to the `video` group. A logout/login is required once for new supplementary-group membership to take effect.
- Fixed the top-right brightness circle disappearing abruptly during auto-hide. It now reverses the same slide animation used on reveal instead of being clipped by a shrinking PanelWindow.
- Removed the increasingly complex fullscreen-state, monitor-geometry, repeated-resize, and sleep logic from `Super+V`; Hyprland community examples show the float+resize+center sequence working reliably when issued as one `hyprctl --batch` request.

### Notes
- The brightness control only accepts pointer input over the tiny hotspot, visible circle, and open slider. The rest of the fixed top-right shell window is click-through.
- This release keeps the existing unresolved MSI brightness-key issue separate; the brightness slider works through normal unprivileged `brightnessctl` access.
- Personaboi deliberately does not make `brightnessctl` setuid and does not add passwordless sudo rules for it.

## v1.3 — 2026-09-11

**Focus:** richer Persona utilities and more informative system views.

### Added
- Persona-styled intensity control for all three screen shaders: Bluelight, Greyscale, and Inversion.
- Per-shader remembered intensity values in the running Quickshell session.
- Runtime shader rendering helper that creates a user-cache copy with the chosen intensity and switches Hyprland to that copy without modifying the repo shader files.
- Expanded Stats panel telemetry: hostname, kernel, uptime, CPU model, logical CPU count, 1/5/15-minute load average, process count, GPU name, GPU utilization, VRAM usage, GPU temperature, sessions, plus the existing OS/CPU/RAM/disk data.

### Changed
- Calendar view now shows 10 diagonal days instead of 7: three previous days, today, and six upcoming days.
- Calendar entries now use consistent sizing: all ordinary days share the same date, weekday, and moon size, while today alone remains larger as the focal Persona highlight.
- Shifted and tightened the 10-day diagonal leftward so the last date/moon stays fully inside the screen instead of clipping on the right.
- Desktop clock moon and calendar moon icons now use the same shared phase calculation from `Data/Time.qml` instead of two separate approximations.
- Moon calculations use a mean synodic month of 29.53059 days and a common reference new moon; future calendar entries therefore update their phase automatically from their date.
- `Super+V` now explicitly sets the window floating/tiled state and derives an exact numeric floating size from the focused monitor's logical dimensions before centering it.

### Fixed
- Fixed `Super+V` cases where the window entered floating mode but retained an almost-fullscreen inherited geometry. The helper now reapplies the exact numeric size after the state transition instead of relying on the earlier percentage/address-targeted resize path.

### Notes
- Moon phases are calculated locally; Personaboi does not call a weather or astronomy API for them. The display is an approximation based on the mean synodic cycle, not a high-precision astronomical ephemeris.
- Hyprland exposes `decoration:screen_shader` as a shader path rather than an arbitrary custom-uniform control, so shader intensity is implemented by generating a temporary shader in `~/.cache/personaboi/shaders/` with the chosen constant baked in, then switching Hyprland to that file.

## v1.2 — 2026-09-11

**Focus:** input handling, launcher convenience, and power/session reliability.

### Added
- `Super+B` launches the browser currently registered as the XDG default.
- MSI brightness-key fallback binds while preserving the normal `XF86MonBrightnessUp/Down` binds.

### Changed
- `Super+E` now opens GNOME Files (`nautilus`) instead of Dolphin, and fresh installs explicitly install `nautilus`.
- Corrected the MSI brightness fallback from Linux evdev codes 224/225 to their XKB keycodes 232/233, which are the values Hyprland's `code:` binding expects.
- Power-menu shutdown/reboot now call `systemctl poweroff` / `systemctl reboot`, while logout exits the current Hyprland session with `hyprctl dispatch exit`.
- `Super+V` makes a newly-floating window visibly smaller (70% x 72% of the monitor) and centers it; pressing `Super+V` again returns it to normal tiled layout control.

### Fixed
- Fixed the Persona power menu using unsupported `loginctl poweroff` / `loginctl reboot` commands.
- Fixed the workspace shell strip blocking clicks on application UI underneath it. The strip still reserves the top edge, but its input mask now only covers the visible workspace pill, so the rest of the top strip is click-through.
- Fixed `Super+V` becoming unresponsive after the first floating-resize implementation embedded shell logic directly inside Hyprland's comma-delimited bind line. The state check now lives in `Scripts/toggle-floating.sh`, while the Hyprland bind simply launches that helper.
- Hardened the `Super+V` helper so it accepts both boolean (`true`/`false`) and numeric (`1`/`0`) floating-state values, and falls back to Hyprland's native `togglefloating` if state detection ever fails. Resize/center failures can no longer make the toggle itself silently do nothing.
- Added a short post-toggle delay before resize/center so the floating geometry is applied after Hyprland commits the tiled-to-floating transition.

### Known / investigating
- On the tested MSI Stealth laptop, brightness hotkeys emit `KEY_BRIGHTNESSDOWN/UP` on the ACPI `Video Bus` device and work in GNOME, but are still not reaching Hyprland's bind path. `brightnessctl` itself works correctly. Further input-stack diagnosis is required rather than adding more guessed keycodes.

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
- Root `AGENTS.md` handoff guide with the project workflow, live paths, updater behavior, compatibility lessons, privilege model, and rules for continuing Personaboi work in a fresh ChatGPT conversation.

### Changed
- Made the workspace tracker smaller and moved it tighter to the top-left corner.
- Reduced the reserved workspace strip from 30px to 24px.
- Reduced only the Hyprland **top** outer gap to 6px while keeping right/bottom/left outer gaps at 20px, so tiled windows sit much closer to the workspace tracker without changing the other screen edges.
- Fresh installation now validates sudo once up front with `sudo -v`; privileged operations remain limited to system package/repository work and `/usr/local` CAVA installation.
- `setup/verify.sh` no longer invokes sudo for the NVIDIA DRM check when the sysfs value is readable as the current user.

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

- Ubuntu 26.04 installation/bootstrap scripts.
- Quickshell installation through the DankLinux PPA.
- CAVA core and Qt6 CavaMonitor plugin build/install steps.
- JetBrainsMono Nerd Font installation.
- Tested Hyprland config with 1920x1200 at 1.25 scaling.
- NVIDIA environment settings and documented package-conflict warning.
- Persona autostart, NetworkManager, Blueman and Polkit setup.
