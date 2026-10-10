#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_FILE="$ROOT_DIR/dotfiles/fuzzel/fuzzel.ini"
DEST_DIR="$HOME/.config/fuzzel"
DEST_FILE="$DEST_DIR/fuzzel.ini"

DRY_RUN=false
FORCE=false

usage() {
    cat <<'USAGE'
Usage: setup-fuzzel.sh [--dry-run] [--force]

Options:
  --dry-run  Preview actions without changing anything
  --force    Replace existing Fuzzel config, backing it up first
  --help     Show this help
USAGE
}

while (($# > 0)); do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
        --help|-h) usage; exit 0 ;;
        *)
            echo "Error: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ ! -f /etc/arch-release ]]; then
    echo "Error: this script requires Arch Linux or an Arch-based distribution." >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    echo "Error: run this script as your normal user, not root." >&2
    exit 1
fi

for command in pacman sudo install cp date; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command is missing: $command" >&2
        exit 1
    fi
done

if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Error: project configuration file is missing: $SOURCE_FILE" >&2
    exit 1
fi

echo "Fuzzel setup"
echo

if pacman -Q fuzzel >/dev/null 2>&1; then
    echo "Fuzzel is already installed."
elif [[ "$DRY_RUN" == true ]]; then
    echo "Would install the Fuzzel package."
else
    echo "Fuzzel is not installed; it will be installed with pacman."
fi

echo
if [[ -e "$DEST_FILE" || -L "$DEST_FILE" ]]; then
    if [[ "$FORCE" == true ]]; then
        echo "Will back up and replace: $DEST_FILE"
    else
        echo "Will preserve existing file: $DEST_FILE"
    fi
else
    echo "Will install: $DEST_FILE"
fi

if [[ "$DRY_RUN" == true ]]; then
    echo
    echo "Preview complete; no changes were made."
    exit 0
fi

echo
if [[ "$FORCE" == true ]]; then
    echo "Force mode will replace the existing file after making a backup."
fi
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

if ! pacman -Q fuzzel >/dev/null 2>&1; then
    sudo pacman -S --needed fuzzel
fi

install -d "$DEST_DIR"

if [[ -e "$DEST_FILE" || -L "$DEST_FILE" ]]; then
    if [[ "$FORCE" != true ]]; then
        echo "Skipping existing file: $DEST_FILE"
        echo "Fuzzel setup complete."
        exit 0
    fi

    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup="$DEST_FILE.backup-$timestamp"
    cp -a -- "$DEST_FILE" "$backup"
    echo "Backed up: $backup"
fi

install -m 644 -- "$SOURCE_FILE" "$DEST_FILE"
echo "Installed: $DEST_FILE"
echo
echo "Fuzzel setup complete."
