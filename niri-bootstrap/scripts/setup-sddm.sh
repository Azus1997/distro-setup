#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Keyitdev/sddm-astronaut-theme.git"
THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
CONFIG_DIR="/etc/sddm.conf.d"
CONFIG_FILE="$CONFIG_DIR/10-niri-bootstrap.conf"
PRESET="Themes/purple_leaves.conf"

if [[ ! -f /etc/arch-release ]]; then
    echo "Error: this script requires Arch Linux or an Arch-based distribution." >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    echo "Error: run this script as your normal user, not root." >&2
    exit 1
fi

for command in git sudo systemctl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command is missing: $command" >&2
        exit 1
    fi
done

# Detect enabled display managers that could conflict with SDDM.
other_dms=()
running_dms=()

for service in gdm.service lightdm.service greetd.service ly.service lxdm.service; do
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        other_dms+=("$service")
    fi

    if systemctl is-active --quiet "$service" 2>/dev/null; then
        running_dms+=("$service")
    fi
done

# Refuse to overwrite an unrelated directory.
if [[ -e "$THEME_DIR" ]]; then
    existing_origin="$(git -C "$THEME_DIR" remote get-url origin 2>/dev/null || true)"
    if [[ "${existing_origin%.git}" != "${REPO_URL%.git}" ]]; then
        echo "Error: theme destination exists but is not the expected repository:" >&2
        echo "  $THEME_DIR" >&2
        echo "No changes were made. Inspect or move it before retrying." >&2
        exit 1
    fi
fi

echo "SDDM setup: Astronaut theme — Purple Leaves"
echo
echo "The script will install SDDM and the required Qt packages,"
echo "install the theme and fonts, configure Purple Leaves,"
echo "and enable SDDM for the next boot."
echo "It will not start or stop a display manager in this session."

if (( ${#other_dms[@]} > 0 )); then
    echo
    echo "Other enabled display managers will be disabled for future boots:"
    printf '  %s\n' "${other_dms[@]}"
fi

if (( ${#running_dms[@]} > 0 )); then
    echo
    echo "WARNING: These display managers are currently active:"
    printf '  %s\n' "${running_dms[@]}"
    echo "This script will not stop them during the current session."
    echo "Switching display managers may require a reboot."
fi

echo
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

sudo pacman -S --needed sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg

# Clone into a temporary directory before installing system-wide.
if [[ ! -e "$THEME_DIR" ]]; then
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT

    git clone --depth 1 "$REPO_URL" "$temp_dir/theme"

    if [[ ! -f "$temp_dir/theme/$PRESET" ||
          ! -d "$temp_dir/theme/Fonts" ||
          ! -f "$temp_dir/theme/metadata.desktop" ]]; then
        echo "Error: the downloaded theme is missing required files." >&2
        exit 1
    fi

    sudo install -d "$(dirname "$THEME_DIR")"
    sudo cp -a "$temp_dir/theme" "$THEME_DIR"
else
    echo "Theme repository already exists; skipping clone."
fi

if [[ ! -f "$THEME_DIR/$PRESET" ||
      ! -d "$THEME_DIR/Fonts" ||
      ! -f "$THEME_DIR/metadata.desktop" ]]; then
    echo "Error: the installed theme is missing required files." >&2
    exit 1
fi

if ! grep -q '^ConfigFile=' "$THEME_DIR/metadata.desktop"; then
    echo "Error: ConfigFile setting not found in theme metadata." >&2
    exit 1
fi

if ! grep -Fxq "ConfigFile=$PRESET" "$THEME_DIR/metadata.desktop"; then
    sudo cp -a "$THEME_DIR/metadata.desktop" \
        "$THEME_DIR/metadata.desktop.backup-$(date +%Y%m%d-%H%M%S)"
    sudo sed -i "s|^ConfigFile=.*|ConfigFile=$PRESET|" \
        "$THEME_DIR/metadata.desktop"
fi

# Install fonts without overwriting fonts already present.
sudo install -d /usr/share/fonts/sddm-astronaut-theme
sudo cp -an "$THEME_DIR/Fonts/." /usr/share/fonts/sddm-astronaut-theme/
sudo fc-cache -f

# Write our own drop-in and back it up only if it needs changing.
sudo install -d "$CONFIG_DIR"
if [[ -e "$CONFIG_FILE" ]] &&
   ! sudo grep -Fxq 'Current=sddm-astronaut-theme' "$CONFIG_FILE"; then
    sudo cp -a "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
fi

if [[ ! -e "$CONFIG_FILE" ]] ||
   ! sudo grep -Fxq 'Current=sddm-astronaut-theme' "$CONFIG_FILE" ||
   ! sudo grep -Fxq 'InputMethod=qtvirtualkeyboard' "$CONFIG_FILE"; then
    sudo tee "$CONFIG_FILE" >/dev/null <<'CONFIG'
[Theme]
Current=sddm-astronaut-theme

[General]
InputMethod=qtvirtualkeyboard
CONFIG
fi

# Switch the default manager for the next boot, without stopping this session.
for service in "${other_dms[@]}"; do
    sudo systemctl disable "$service"
done
sudo systemctl enable sddm.service

echo
echo "SDDM is configured with the Purple Leaves theme."
echo "Reboot to use it as your login screen."
echo "To preview the theme from your current session:"
echo "  sddm-greeter-qt6 --test-mode --theme $THEME_DIR/"
