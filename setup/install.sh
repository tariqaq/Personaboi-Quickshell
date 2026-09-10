#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run setup/install.sh with sudo or as root." >&2
  echo "Run it as your normal user; the script will request sudo only for system-level steps." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_QS="$HOME/.config/quickshell/persona"
TARGET_HYPR="$HOME/.config/hypr"
TARGET_ENV="$HOME/.config/environment.d"
STATE_DIR="$HOME/.local/share/personaboi"
WORKDIR="${TMPDIR:-/tmp}/personaboi-setup-$USER"

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify the operating system." >&2
  exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "26.04" ]]; then
  echo "This installer is tested for Ubuntu 26.04 only." >&2
  echo "Detected: ${PRETTY_NAME:-unknown}" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required for the system installation steps." >&2
  exit 1
fi

echo "Requesting administrator privileges for package and /usr/local installation steps..."
sudo -v

printf '\n[1/7] Enabling Ubuntu Universe and installing Hyprland/runtime packages...\n'
sudo add-apt-repository -y universe
sudo apt update
sudo apt install -y \
  hyprland xdg-desktop-portal-hyprland hyprland-qtutils \
  git curl wget unzip rsync build-essential cmake \
  kitty nautilus \
  brightnessctl playerctl wl-clipboard grim slurp pavucontrol \
  network-manager-gnome blueman upower polkit-kde-agent-1 \
  xdg-user-dirs xdg-utils libnotify-bin jq \
  qt6-wayland qtwayland5 \
  qt6-svg-plugins qt6-image-formats-plugins \
  qml6-module-qtmultimedia qml6-module-qt5compat-graphicaleffects \
  qt6-base-dev qt6-declarative-dev libpipewire-0.3-dev libfftw3-dev \
  fonts-noto fonts-noto-color-emoji

printf '\n[2/7] Installing Quickshell from the DankLinux Ubuntu PPA...\n'
sudo add-apt-repository -y ppa:avengemedia/danklinux
sudo apt update
sudo apt install -y quickshell

printf '\n[3/7] Building and installing the CAVA core library...\n'
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
git clone --depth 1 https://github.com/karlstav/cava.git "$WORKDIR/cava"
(
  cd "$WORKDIR/cava"
  gcc -shared -fPIC -o libcava.so cavacore.c -lm -lfftw3 -I.
  sudo install -Dm755 libcava.so /usr/local/lib/libcava.so
  sudo install -Dm644 cavacore.h /usr/local/include/cava/cavacore.h
)
sudo ldconfig

printf '\n[4/7] Building and installing the Qt6 CavaMonitor plugin...\n'
git clone --depth 1 https://github.com/Yujonpradhananga/Qt6-Cava-plugin.git "$WORKDIR/Qt6-Cava-plugin"
cmake -S "$WORKDIR/Qt6-Cava-plugin" -B "$WORKDIR/Qt6-Cava-plugin/build" \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local/lib/qt6/qml"
cmake --build "$WORKDIR/Qt6-Cava-plugin/build" -j"$(nproc)"
cmake --install "$WORKDIR/Qt6-Cava-plugin/build"

printf '\n[5/7] Installing JetBrainsMono Nerd Font...\n'
mkdir -p "$WORKDIR/fonts" "$HOME/.local/share/fonts/JetBrainsMono"
curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  -o "$WORKDIR/fonts/JetBrainsMono.zip"
unzip -oq "$WORKDIR/fonts/JetBrainsMono.zip" -d "$WORKDIR/fonts/JetBrainsMono"
find "$WORKDIR/fonts/JetBrainsMono" -maxdepth 1 -type f -name '*.ttf' \
  -exec cp -f {} "$HOME/.local/share/fonts/JetBrainsMono/" \;
fc-cache -f

printf '\n[6/7] Installing Personaboi Quickshell, dotfiles, and updater...\n'
mkdir -p "$TARGET_QS" "$TARGET_HYPR" "$TARGET_ENV" "$STATE_DIR" "$HOME/.local/bin"
rsync -a --delete \
  --exclude '.git/' \
  --exclude 'setup/' \
  --exclude 'docs/' \
  "$REPO_ROOT/" "$TARGET_QS/"

sed "s#__HOME__#$HOME#g" "$REPO_ROOT/setup/hyprland.conf.in" > "$TARGET_HYPR/hyprland.conf"
cp "$REPO_ROOT/setup/qt.conf" "$TARGET_ENV/qt.conf"
install -Dm755 "$REPO_ROOT/setup/pboi" "$HOME/.local/bin/pboi"

if [[ -f "$REPO_ROOT/VERSION" ]]; then
  tr -d '[:space:]' < "$REPO_ROOT/VERSION" > "$STATE_DIR/version"
  printf '\n' >> "$STATE_DIR/version"
fi
if git -C "$REPO_ROOT" rev-parse HEAD >/dev/null 2>&1; then
  git -C "$REPO_ROOT" rev-parse HEAD > "$STATE_DIR/commit"
fi

printf '\n[7/7] Verifying the configuration...\n'
Hyprland --verify-config
printf '\nInstalled Personaboi: v'; cat "$REPO_ROOT/VERSION" 2>/dev/null || echo 'unknown'
printf 'Installed Quickshell: '; qs --version || true
printf 'Installed Hyprland: '; Hyprland --version | head -n 1 || true
printf 'Nerd Font match: '; fc-match 'JetBrainsMono Nerd Font' | head -n 1 || true

cat <<'EOF2'

Installation files are in place.

Before first Hyprland login:
  1. If you use NVIDIA, make sure your normal Ubuntu NVIDIA driver is installed.
  2. Verify: cat /sys/module/nvidia_drm/parameters/modeset
     It should print Y on the tested NVIDIA setup.
  3. DO NOT install libnvidia-egl-gbm1 separately if APT proposes removing your NVIDIA driver metapackage.
  4. Log out of GNOME, choose Hyprland in GDM, and sign in.

Useful keys:
  Super+Q       terminal
  Super+E       GNOME Files
  Super+C       close focused window
  Super+V       toggle floating/tiled
  Super+R       Persona app launcher
  Super+M       leave Hyprland
  Super+Print   select screenshot area and copy to clipboard

The Persona side blades are drag-to-activate: drag a blade right and release it.

Updates:
  pboi update      pull and apply the newest shared setup
  pboi version     show the installed Personaboi version
  pboi changelog   show the installed changelog

Run pboi as your normal user, never with sudo.

If pboi is not found in the current shell immediately after this fresh install,
log out and back in once so Ubuntu adds ~/.local/bin to PATH.
EOF2
