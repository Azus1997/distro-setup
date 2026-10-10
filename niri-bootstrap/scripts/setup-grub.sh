#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/dracula/grub.git"
THEME_DIR="/boot/grub/themes/dracula"
THEME_PATH="$THEME_DIR/theme.txt"
GRUB_DEFAULT="/etc/default/grub"
GRUB_CONFIG="/boot/grub/grub.cfg"

if [[ ! -f /etc/arch-release ]]; then
    echo "Error: this script requires Arch Linux or an Arch-based distribution." >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    echo "Error: run this script as your normal user, not root." >&2
    exit 1
fi

for command in git sudo pacman grub-mkconfig mountpoint awk; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command is missing: $command" >&2
        exit 1
    fi
done

if ! pacman -Q grub >/dev/null 2>&1; then
    echo "Error: GRUB is not installed." >&2
    echo "This script themes an existing GRUB installation; it does not install a bootloader." >&2
    exit 1
fi

if [[ ! -f "$GRUB_DEFAULT" || ! -f "$GRUB_CONFIG" ]]; then
    echo "Error: expected GRUB configuration files are missing." >&2
    echo "Expected: $GRUB_DEFAULT and $GRUB_CONFIG" >&2
    echo "Check your GRUB installation and boot layout before continuing." >&2
    exit 1
fi

# If fstab defines a separate /boot mount, require it to be mounted.
if awk '$1 !~ /^#/ && $2 == "/boot" { found=1 } END { exit !found }' /etc/fstab; then
    if ! mountpoint -q /boot; then
        echo "Error: /etc/fstab defines a separate /boot, but it is not mounted." >&2
        echo "Mount the correct boot filesystem before retrying." >&2
        exit 1
    fi
fi

validate_theme() {
    local directory="$1"
    local required

    for required in \
        theme.txt \
        font.pf2 \
        background.png \
        logo.png \
        select_c.png \
        select_e.png \
        select_ne.png \
        select_n.png \
        select_nw.png \
        select_se.png \
        select_s.png \
        select_sw.png \
        select_w.png
    do
        if [[ ! -s "$directory/$required" ]]; then
            echo "Error: required Dracula theme file is missing or empty:" >&2
            echo "  $directory/$required" >&2
            return 1
        fi
    done

    if [[ ! -d "$directory/icons" ]]; then
        echo "Error: Dracula theme icons directory is missing:" >&2
        echo "  $directory/icons" >&2
        return 1
    fi
}

if [[ -e "$THEME_DIR" && ! -d "$THEME_DIR" ]]; then
    echo "Error: theme destination exists but is not a directory:" >&2
    echo "  $THEME_DIR" >&2
    exit 1
fi

if [[ -d "$THEME_DIR" ]]; then
    validate_theme "$THEME_DIR" || {
        echo "Inspect or repair the existing theme before retrying." >&2
        exit 1
    }
fi

echo "This will install the Dracula GRUB theme and regenerate grub.cfg."
echo "It will not install GRUB or change your bootloader choice."
echo
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

if [[ ! -d "$THEME_DIR" ]]; then
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT

    git clone --depth 1 "$REPO_URL" "$temp_dir/repo"

    validate_theme "$temp_dir/repo/dracula"

    sudo install -d "$(dirname "$THEME_DIR")"
    sudo cp -a "$temp_dir/repo/dracula" "$THEME_DIR"
fi

# Validate the installed copy before touching GRUB configuration.
validate_theme "$THEME_DIR"

timestamp="$(date +%Y%m%d-%H%M%S)"
sudo cp -a "$GRUB_DEFAULT" "$GRUB_DEFAULT.backup-$timestamp"
sudo cp -a "$GRUB_CONFIG" "$GRUB_CONFIG.backup-$timestamp"

# Replace active or commented GRUB_THEME assignments with one setting.
# Preserve unrelated settings and comments.
sudo sed -i -E \
    '/^[[:space:]]*#?[[:space:]]*GRUB_THEME=/d' \
    "$GRUB_DEFAULT"

printf '\nGRUB_THEME="%s"\n' "$THEME_PATH" |
    sudo tee -a "$GRUB_DEFAULT" >/dev/null

if ! sudo grub-mkconfig -o "$GRUB_CONFIG"; then
    echo "Error: grub-mkconfig failed." >&2
    echo "Backups are available at:" >&2
    echo "  $GRUB_DEFAULT.backup-$timestamp" >&2
    echo "  $GRUB_CONFIG.backup-$timestamp" >&2
    echo "Review the error and restore the configuration if needed." >&2
    exit 1
fi

echo
echo "Dracula GRUB theme configured."
echo "Backups:"
echo "  $GRUB_DEFAULT.backup-$timestamp"
echo "  $GRUB_CONFIG.backup-$timestamp"
echo "Reboot to see the themed boot menu."
