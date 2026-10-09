#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/arch-release ]]; then
    echo "Error: this script is intended for Arch Linux." >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    echo "Error: do not run this script as root." >&2
    exit 1
fi

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Error: Flatpak is missing. Run ./bootstrap.sh official first." >&2
    exit 1
fi

echo "This will configure Flathub and install Stremio."
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

sudo flatpak remote-add --system --if-not-exists \
    flathub https://dl.flathub.org/repo/flathub.flatpakrepo

sudo flatpak install --system --assumeyes \
    flathub com.stremio.Stremio

echo "Stremio installation complete."
