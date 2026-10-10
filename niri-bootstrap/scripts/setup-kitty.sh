#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$ROOT_DIR/dotfiles/kitty"
DEST_DIR="$HOME/.config/kitty"

DRY_RUN=false
FORCE=false

usage() {
    cat <<'USAGE'
Usage: setup-kitty.sh [--dry-run] [--force]

Options:
  --dry-run  Preview actions without changing anything
  --force    Replace existing Kitty config files, backing them up first
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

for file in kitty.conf catppuccin-mocha.conf; do
    if [[ ! -f "$SOURCE_DIR/$file" ]]; then
        echo "Error: project configuration file is missing: $SOURCE_DIR/$file" >&2
        exit 1
    fi
done

echo "Kitty setup"
echo

if pacman -Q kitty >/dev/null 2>&1; then
    echo "Kitty is already installed."
elif [[ "$DRY_RUN" == true ]]; then
    echo "Would install the Kitty package."
else
    echo "Kitty is not installed; it will be installed with pacman."
fi

echo
for file in kitty.conf catppuccin-mocha.conf; do
    destination="$DEST_DIR/$file"

    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ "$FORCE" == true ]]; then
            echo "Will back up and replace: $destination"
        else
            echo "Will preserve existing file: $destination"
        fi
    else
        echo "Will install: $destination"
    fi
done

if [[ "$DRY_RUN" == true ]]; then
    echo
    echo "Preview complete; no changes were made."
    exit 0
fi

echo
if [[ "$FORCE" == true ]]; then
    echo "Force mode will replace existing files after making backups."
fi
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

if ! pacman -Q kitty >/dev/null 2>&1; then
    sudo pacman -S --needed kitty
fi

install -d "$DEST_DIR"

timestamp="$(date +%Y%m%d-%H%M%S)"

for file in kitty.conf catppuccin-mocha.conf; do
    source="$SOURCE_DIR/$file"
    destination="$DEST_DIR/$file"

    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ "$FORCE" != true ]]; then
            echo "Skipping existing file: $destination"
            continue
        fi

        backup="$destination.backup-$timestamp"
        cp -a -- "$destination" "$backup"
        echo "Backed up: $backup"
    fi

    install -m 644 -- "$source" "$destination"
    echo "Installed: $destination"
done

echo
echo "Kitty setup complete."
echo "Restart Kitty or reload its configuration to apply changes."
