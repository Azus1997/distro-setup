#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

errors=0

for file in \
    "$ROOT_DIR/bootstrap.sh" \
    "$SCRIPT_DIR/install-official.sh" \
    "$SCRIPT_DIR/install-aur.sh" \
    "$SCRIPT_DIR/deploy-dotfiles.sh" \
    "$SCRIPT_DIR/install-flatpaks.sh" \
    "$SCRIPT_DIR/setup-services.sh" \
    "$SCRIPT_DIR/install-wallpapers.sh" \
    "$SCRIPT_DIR/setup-sddm.sh" \
    "$SCRIPT_DIR/setup-kitty.sh" \
    "$SCRIPT_DIR/setup-thunar.sh" \
    "$SCRIPT_DIR/setup-eww.sh" \
    "$SCRIPT_DIR/setup-fuzzel.sh" \
    "$SCRIPT_DIR/setup-gtk.sh" \
    "$SCRIPT_DIR/setup-grub.sh" \
    "$SCRIPT_DIR/setup-niri.sh" \
    "$SCRIPT_DIR/setup-swaylock.sh"
do
    if bash -n "$file"; then
        echo "OK: syntax $file"
    else
        echo "FAIL: syntax $file"
        errors=$((errors + 1))
    fi
done

for file in \
    "$ROOT_DIR/packages/official.txt" \
    "$ROOT_DIR/packages/aur.txt" \
    "$ROOT_DIR/dotfiles/niri/config.kdl" \
    "$ROOT_DIR/dotfiles/noctalia/colors.json" \
    "$ROOT_DIR/dotfiles/noctalia/plugins.json" \
    "$ROOT_DIR/dotfiles/noctalia/settings.json" \
    "$ROOT_DIR/dotfiles/kitty/kitty.conf" \
    "$ROOT_DIR/dotfiles/kitty/catppuccin-mocha.conf" \
    "$SCRIPT_DIR/install-flatpaks.sh" \
    "$SCRIPT_DIR/setup-services.sh" \
    "$SCRIPT_DIR/install-wallpapers.sh" \
    "$SCRIPT_DIR/setup-sddm.sh" \
    "$SCRIPT_DIR/setup-kitty.sh" \
    "$SCRIPT_DIR/setup-thunar.sh" \
    "$ROOT_DIR/dotfiles/Thunar/uca.xml" \
    "$ROOT_DIR/dotfiles/Thunar/accels.scm" \
    "$ROOT_DIR/dotfiles/eww/eww.yuck" \
    "$ROOT_DIR/dotfiles/eww/eww.scss" \
    "$ROOT_DIR/dotfiles/fuzzel/fuzzel.ini" \
    "$SCRIPT_DIR/setup-gtk.sh" \
    "$ROOT_DIR/dotfiles/nwg-look/config" \
    "$ROOT_DIR/dotfiles/gtk-3.0/settings.ini" \
    "$ROOT_DIR/dotfiles/gtk-4.0/settings.ini" \
    "$SCRIPT_DIR/setup-swaylock.sh" \
    "$ROOT_DIR/dotfiles/swaylock/config" \
    "$SCRIPT_DIR/setup-niri.sh" \
    "$SCRIPT_DIR/setup-grub.sh"
do
    if [[ -f "$file" ]]; then
        echo "OK: found $file"
    else
        echo "FAIL: missing $file"
        errors=$((errors + 1))
    fi
done

if (( errors > 0 )); then
    echo "Check failed: $errors problem(s) found."
    exit 1
fi

echo "All project checks passed."
