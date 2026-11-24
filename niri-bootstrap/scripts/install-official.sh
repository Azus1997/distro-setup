#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGE_FILE="$ROOT_DIR/packages/official.txt"

if [[ ! -f /etc/arch-release ]]; then
    echo "Error: this script is intended for Arch Linux." >&2
    exit 1
fi

if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "Error: package list not found: $PACKAGE_FILE" >&2
    exit 1
fi

mapfile -t packages < <(
    grep -Ev '^[[:space:]]*(#|$)' "$PACKAGE_FILE"
)

if (( ${#packages[@]} == 0 )); then
    echo "Error: package list is empty." >&2
    exit 1
fi

printf 'Packages to install:\n'
printf '  %s\n' "${packages[@]}"
printf '\n'

echo "This will synchronize repositories and upgrade the system."
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

sudo pacman -Syu --needed "${packages[@]}" --noconfirm
