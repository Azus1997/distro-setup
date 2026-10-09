#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /etc/arch-release ]]; then
echo "Error: this script is intended for Arch Linux." >&2
exit 1
fi

if [[ $EUID -eq 0 ]]; then
echo "Error: run this script as your normal user, not root." >&2
exit 1
fi

for package in networkmanager coolercontrol-bin; do
if ! pacman -Q "$package" >/dev/null 2>&1; then
echo "Error: required package '$package' is not installed." >&2
echo "Install the official and AUR packages first." >&2
exit 1
fi
done

echo "The following system services will be enabled:"
echo "  NetworkManager.service"
echo "  coolercontrold.service"
echo
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now coolercontrold.service

echo "System services enabled and started."
