#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'USAGE'
Usage: ./bootstrap.sh <command>

Commands:
  all            Install packages, Flatpaks, and configuration
  official       Install official Arch packages
  aur            Install AUR packages
  dotfiles       Deploy missing configuration files
  dotfiles-check Preview dotfile deployment without changes
  niri           Install Niri and deploy its configuration
  wallpapers     Clone the wallpaper repository if needed
  sddm           Install and configure SDDM with Purple Leaves
  grub           Configure the Dracula theme for an existing GRUB install
  swaylock       Install swaylock-effects and deploy its config
  thunar         Install Thunar and configure its settings
  eww            Install Eww and configure its widgets
  fuzzel         Install Fuzzel and configure its launcher
  kitty          Install Kitty and configure its terminal settings
  gtk            Install nwg-look and deploy GTK settings
  services       Enable and start required system services
  check          Check script syntax and required project files
  help           Show this help
  flatpaks       Install Flatpak applications
USAGE
}

command="${1:-help}"

case "$command" in
    all)
        "$SCRIPT_DIR/scripts/install-official.sh"
        "$SCRIPT_DIR/scripts/install-aur.sh"
        "$SCRIPT_DIR/scripts/install-flatpaks.sh"
        "$SCRIPT_DIR/scripts/install-wallpapers.sh"
        "$SCRIPT_DIR/scripts/deploy-dotfiles.sh"
        "$SCRIPT_DIR/scripts/setup-services.sh"
        "$SCRIPT_DIR/scripts/setup-niri.sh"
        "$SCRIPT_DIR/scripts/setup-sddm.sh"
        "$SCRIPT_DIR/scripts/setup-grub.sh"
        "$SCRIPT_DIR/scripts/setup-swaylock.sh"
        "$SCRIPT_DIR/scripts/setup-thunar.sh"
        "$SCRIPT_DIR/scripts/setup-eww.sh"
        "$SCRIPT_DIR/scripts/setup-fuzzel.sh"
        "$SCRIPT_DIR/scripts/setup-kitty.sh"
        "$SCRIPT_DIR/scripts/setup-gtk.sh"
        ;;
    official)
        exec "$SCRIPT_DIR/scripts/install-official.sh"
        ;;
    aur)
        exec "$SCRIPT_DIR/scripts/install-aur.sh"
        ;;
    niri)
        shift
        exec "$SCRIPT_DIR/scripts/setup-niri.sh" "$@"
        ;;
    dotfiles)
        exec "$SCRIPT_DIR/scripts/deploy-dotfiles.sh"
        ;;
    dotfiles-check)
        exec "$SCRIPT_DIR/scripts/deploy-dotfiles.sh" --dry-run
        ;;
    wallpapers)
        exec "$SCRIPT_DIR/scripts/install-wallpapers.sh"
        ;;
    sddm)
        exec "$SCRIPT_DIR/scripts/setup-sddm.sh"
        ;;
    grub)
        exec "$SCRIPT_DIR/scripts/setup-grub.sh"
        ;;
    swaylock)
        shift
        exec "$SCRIPT_DIR/scripts/setup-swaylock.sh" "$@"
        ;;
    thunar)
        shift
        exec "$SCRIPT_DIR/scripts/setup-thunar.sh" "$@"
        ;;
     eww)
        shift
        exec "$SCRIPT_DIR/scripts/setup-eww.sh" "$@"
        ;;
    fuzzel)
        shift
        exec "$SCRIPT_DIR/scripts/setup-fuzzel.sh" "$@"
        ;;
    kitty)
        shift
        exec "$SCRIPT_DIR/scripts/setup-kitty.sh" "$@"
        ;;
    gtk)
        shift
        exec "$SCRIPT_DIR/scripts/setup-gtk.sh" "$@"
        ;;
    services)
        exec "$SCRIPT_DIR/scripts/setup-services.sh"
        ;;
    flatpaks)
        exec "$SCRIPT_DIR/scripts/install-flatpaks.sh"
        ;;
    check)
        exec "$SCRIPT_DIR/scripts/check.sh"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        echo "Unknown command: $command" >&2
        usage >&2
        exit 2
        ;;
esac
