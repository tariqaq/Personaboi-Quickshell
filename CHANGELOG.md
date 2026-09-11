# Changelog

All notable Personaboi changes are tracked here. Versions describe this Ubuntu 26.04 fork, not upstream Persona-Quickshell releases.

## v1.5 — 2026-09-11

**Focus:** consistent auto-dismiss behavior across Persona edge controls.

### Changed
- The left-side Persona `:3` drawer now follows the same inactivity behavior as the top-right brightness control.
- Revealing the drawer, opening its blades, or hovering/dragging a blade keeps it alive while actively interacting.
- After leaving the drawer inactive for about 1.4 seconds, it collapses the blades and slides the main circle back off-screen automatically.
- Dragging a Calendar / Stats / Shaders / Power blade still activates the selected ticket immediately and dismisses the drawer afterward.
- Wallpaper shader time updates are now driven by one shared ~60 Hz timer instead of three perpetual `NumberAnimation`s that can advance with a high-refresh display. The original ripple, stars/rain, and bars-motion animation speeds are preserved using elapsed wall-clock time; Hyprland and normal application rendering remain untouched at the monitor's native refresh rate.
- Wallpaper render pipeline step 2 removes the redundant full-screen `s0_bg_out` `ShaderEffectSource`. The Stars/Rain shader now renders directly inside the Stage 1 composite, while the two offscreen passes that are still structurally required remain: Ripple -> texture for Stars/Rain, and complete composite -> texture for final Parallax.
- Wallpaper optimization step 3 now pauses the wallpaper surface whenever the active workspace on that monitor is covered only by tiled/fullscreen windows. If any floating window is present, the wallpaper remains live because some desktop area is expected to stay visible.
- Coverage checks are event-driven from Hyprland IPC with a small debounce, plus a slow 5-second fallback check. When covered, both the wallpaper 60 Hz ticker and the Quickshell window's render updates are paused; the surface redraws immediately when it becomes visible again.
- Wallpaper optimization step 4 keeps all 50 CAVA bars but decouples Canvas painting from raw audio-value callbacks. CAVA now paints at most about 30 Hz (`33 ms`) while audio is active instead of repainting on every value update.
- CAVA now detects near-silence from the incoming bar values. It performs one final clear when audio activity drops to zero, then stops requesting Canvas repaints until meaningful audio returns.
- When step 3 marks the wallpaper covered, CAVA capture itself is disabled in addition to the wallpaper render surface/ticker being paused. It resumes automatically when the wallpaper becomes visible again.
- The CAVA Canvas now uses Qt's threaded render strategy so Canvas painting work can be performed away from the main UI thread where supported.
- Removed the old always-updating CAVA debug text readout from the wallpaper visualizer.
- Wallpaper optimization step 5 now throttles mouse-parallax state application to the same ~60 Hz wallpaper cadence. Raw pointer motion only updates pending coordinates, preventing the final parallax shader from being dirtied at pointer/display event rates above the wallpaper cap.
- The two still-required `ShaderEffectSource` textures now render at 80% linear resolution with smooth sampling. The visible wallpaper surface remains full-size, while each offscreen texture processes about 64% of the native pixel count.

### Notes
- This change intentionally reuses the proven Timer + hover/interacting pattern already working in `BrightnessCorner.qml` rather than adding a new animation/state system.
- Wallpaper 60 Hz throttling is the first performance-optimization step and should be measured on the target machine before applying the later render-pipeline/CAVA optimizations.
- Qt warns that `ShaderEffectSource` adds an offscreen FBO render and extra video-memory usage, so step 2 removes only the clearly redundant intermediate pass without reducing texture resolution or changing shader quality.
- Step 3 uses Quickshell 0.3.1 `updatesEnabled` on the wallpaper window. This is specifically intended for static/hidden shell surfaces and prevents visual updates from forcing redraws while the wallpaper is covered.
- A single tiled window, multiple tiled windows, or a fullscreen/maximized tiled window pauses wallpaper rendering. A normal floating window keeps wallpaper rendering enabled.
- Step 4 deliberately leaves CAVA at 50 bars. Only repaint cadence, silence handling, covered-wallpaper activity, and Canvas execution strategy were changed.
- Step 5 deliberately limits resolution reduction to offscreen intermediate textures. The final output, Hyprland compositor, applications, and cursor remain at native display resolution/refresh.

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
