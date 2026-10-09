#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGE_FILE="$ROOT_DIR/packages/aur.txt"

if [[ ! -f /etc/arch-release ]]; then
    echo "Error: this script is intended for Arch Linux." >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    echo "Error: do not run this script as root." >&2
    exit 1
fi

if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "Error: AUR package list not found: $PACKAGE_FILE" >&2
    exit 1
fi

mapfile -t packages < <(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGE_FILE")

if (( ${#packages[@]} == 0 )); then
    echo "No AUR packages listed; nothing to do."
    exit 0
fi

if ! command -v yay >/dev/null 2>&1; then
    echo "yay is missing; installing its build dependencies."
    sudo pacman -S --needed git base-devel

    build_dir="$(mktemp -d)"
    trap 'rm -rf "$build_dir"' EXIT

    git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
    (
        cd "$build_dir/yay"
        makepkg -si
    )
fi

printf 'AUR packages to install:\n'
printf '  %s\n' "${packages[@]}"
printf '\n'

read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

# yay itself may be listed; --needed avoids reinstalling it.
yay -S --needed "${packages[@]}"
