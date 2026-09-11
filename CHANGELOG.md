# Changelog

All notable Personaboi changes are tracked here. Versions describe this Ubuntu 26.04 fork, not upstream Persona-Quickshell releases.

## v1.6 — 2026-09-11

**Focus:** native desktop notifications plus the completed wallpaper power/performance optimization pass.

### Added
- Native Quickshell notification daemon using `NotificationServer`, so browser/app notifications arrive through the standard `org.freedesktop.Notifications` D-Bus interface instead of appearing as tiled utility windows.
- Persona-themed notification toasts in the top-right corner using the existing dark navy/cyan palette, app/image icons, summary/body text, urgency accents, dismiss controls, and up to two advertised notification actions.
- Notification toasts auto-expire using the sender timeout when provided, otherwise about 5 seconds for normal notifications and 8 seconds for critical notifications. Hovering pauses expiry.
- Compact Persona notification-history button aligned to the right side of the 24 px workspace strip. It opens a scrollable top-right history panel containing up to the latest 50 notifications for the current Quickshell session, with timestamps, app/image icons, summary/body text, urgency styling, and a Clear control.
- Persistent diagnostic logs for `setup/install.sh`, `setup/update-hook.sh`, `setup/verify.sh`, and `pboi`. Logs are stored under `~/.local/state/personaboi/logs/`; failures record the failing line/command where practical without enabling noisy global shell tracing.

### Changed
- Wallpaper shader time updates are driven by one shared ~60 Hz timer instead of perpetual animations following the high-refresh display. Hyprland, applications, cursor motion, and the rest of the desktop remain free to render at the monitor's native refresh rate.
- Removed the redundant full-screen `s0_bg_out` `ShaderEffectSource`; Stars/Rain now renders directly inside the Stage 1 composite while the two structurally required offscreen passes remain.
- Wallpaper rendering pauses when the active workspace is occupied only by tiled/fullscreen windows. Any floating window keeps the wallpaper live because desktop area is expected to remain visible.
- Coverage checks are event-driven from Hyprland IPC with a short debounce and a slow fallback refresh. Covered wallpaper surfaces use Quickshell `updatesEnabled: false` and stop the shared animation ticker.
- CAVA remains at all 50 bars but Canvas painting is capped to about 30 Hz instead of repainting on every raw audio update.
- CAVA performs one final clear on near-silence and then stops requesting Canvas repaints until meaningful audio returns.
- CAVA capture itself is disabled while the wallpaper is covered and resumes when the desktop becomes visible again.
- CAVA Canvas uses the threaded render strategy where supported, and the old always-updating debug text readout was removed.
- Mouse parallax now stores raw pointer offsets and applies them only on the shared ~60 Hz wallpaper tick, preventing the final parallax shader from being dirtied at pointer event rates above the wallpaper cadence.
- The experimental 80% intermediate texture-size optimization was reverted after visible blur was observed. Both required `ShaderEffectSource` passes remain at native resolution for image sharpness.
- Media capsule selection now ignores metadata-less idle browser MPRIS players. A real paused track, including paused Spotify playback, remains eligible so the capsule stays visible while paused.
- Existing-install migrations are now explicitly cumulative: `pboi update` checks and installs runtime packages that older Personaboi installs may lack (`hyprland-qtutils`, `nautilus`, `brightness-udev`, `libnotify-bin`, and `jq`) before applying current config files.
- The brightness corner is shifted slightly left so its reveal hotspot/circle no longer competes with the new notification-history button at the far top-right.
- `pboi` now logs target/installed version and commit information and writes Hyprland verification output plus the latest Quickshell restart output into the persistent log directory.

### Fixed
- Fixed native notification toasts never becoming visible. Quickshell `ObjectModel` exposes its contents through `.values` and does not provide the `.count` property used by the first implementation; visibility now follows `trackedNotifications.values.length`, and the popup repeater uses a `ScriptModel` backed by the same reactive values list.

### Notes
- Hyprland itself intentionally does not act as a full desktop notification daemon; Personaboi now provides that service natively through Quickshell instead of adding dunst/mako/swaync as another UI stack.
- Only one service can own `org.freedesktop.Notifications` at a time. Do not autostart another notification daemon alongside Personaboi unless the native layer is disabled.
- Normal notification body text is rendered as plain text; rich body markup and inline replies are intentionally not advertised yet.
- Notification history is intentionally session-local for now; it survives toast expiry/dismissal but resets when Quickshell itself restarts.
- Wallpaper optimization prioritizes power savings without sacrificing native image sharpness. The user can benchmark GPU wattage independently.
- The cumulative update hook is intentionally idempotent, so an early pre-`pboi` install can bootstrap the current updater and jump directly to v1.6 instead of replaying every intermediate release.

## v1.5 — 2026-09-11

**Focus:** consistent auto-dismiss behavior across Persona edge controls.

### Changed
- The left-side Persona `:3` drawer now follows the same inactivity behavior as the top-right brightness control.
- Revealing the drawer, opening its blades, or hovering/dragging a blade keeps it alive while actively interacting.
- After leaving the drawer inactive for about 1.4 seconds, it collapses the blades and slides the main circle back off-screen automatically.
- Dragging a Calendar / Stats / Shaders / Power blade still activates the selected ticket immediately and dismisses the drawer afterward.

### Notes
- This change intentionally reuses the proven Timer + hover/interacting pattern already working in `BrightnessCorner.qml` rather than adding a new animation/state system.

## v1.4 — 2026-09-11

**Focus:** direct brightness control and tougher window-state handling.

### Added
- Persona-styled top-right brightness hotspot. Pushing the pointer into the top-right top edge reveals a small brightness circle; clicking it drops a compact slider panel.
- Brightness slider writes directly through `brightnessctl set N%`, with a short throttle while dragging. The existing Brightness OSD continues to reflect the changed backlight value.
- The brightness hotspot follows the same basic reveal/auto-hide behavior as the left-side Persona drawer, but without the ticket blades.
- Ubuntu `brightness-udev` support and `video` group migration for proper unprivileged backlight control instead of embedding `sudo` or passwordless root access in the UI.

### Changed
- `Super+V` uses the simple classic Hyprland batch pattern: `togglefloating`, `resizeactive exact 68% 70%`, then `centerwindow` in one compositor batch. Toggling an already-floating window simply returns it to tiled mode.
- The brightness corner uses a fixed shell surface plus a click-through input mask so the overlay does not block unrelated application UI.
- The brightness control now auto-dismisses after about 1.4 seconds of inactivity, both when merely revealed and after opening/adjusting the slider. Slider dragging temporarily pauses dismissal.
- The brightness circle now animates through `anchors.topMargin` rather than `y`, because its top anchor owns vertical positioning.

### Fixed
- Fixed the brightness slider failing on systems where `brightnessctl` required sudo. Ubuntu 26.04 packages the permission rules separately as `brightness-udev`; existing installs receive that package and the desktop user is added to the `video` group. A logout/login is required once for new supplementary-group membership to take effect.
- Fixed the top-right brightness circle remaining permanently visible. The previous implementation tried to animate `y` while the item was anchored to the top; the anchor controlled the position, so the `y` animation could not move it off-screen.
- Fixed `Super+V` never reaching the resize path for tiled windows. The helper used `jq -r '.floating // empty'`; jq's `//` operator treats boolean `false` like a missing value, so a tiled window produced an empty string and fell through to plain `togglefloating`. It now reads `.floating` directly, allowing the float+resize+center branch to execute.

### Notes
- The brightness control only accepts pointer input over the tiny hotspot, visible circle, and open slider. The rest of the fixed top-right shell window is click-through.
- This release keeps the unresolved MSI brightness-key issue separate; the brightness slider works through normal unprivileged `brightnessctl` access.
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

## v1.1 — 2026-09-11

**Focus:** shared configuration updates and a cleaner day-to-day Hyprland workflow.

- See repository history for earlier v1.1 details.

## v1.0 — 2026-09-10

**Focus:** make Persona-Quickshell reproducible on a fresh Ubuntu 26.04 Desktop installation.

- Ubuntu 26.04 installation/bootstrap scripts.
- Quickshell installation through the DankLinux PPA.
- CAVA core and Qt6 CavaMonitor plugin build/install steps.
- JetBrainsMono Nerd Font installation.
- Tested Hyprland config with 1920x1200 at 1.25 scaling.
- NVIDIA environment settings and documented package-conflict warning.
- Persona autostart, NetworkManager, Blueman and Polkit setup.
