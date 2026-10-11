#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE="$ROOT_DIR/dotfiles/niri/config.kdl"
DEST_DIR="$HOME/.config/niri"
DEST="$DEST_DIR/config.kdl"

DRY_RUN=false
FORCE=false

usage() {
    cat <<'USAGE'
Usage: setup-niri.sh [--dry-run] [--force]

Options:
  --dry-run  Preview actions without changing anything
  --force    Back up and replace an existing Niri config
  --help     Show this help
USAGE
}

while (($# > 0)); do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
        --help|-h) usage; exit 0 ;;
        *)
            printf 'Error: unknown option: %s\n' "$1" >&2
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
        printf 'Error: required command is missing: %s\n' "$command" >&2
        exit 1
    fi
done

if [[ ! -f "$SOURCE" ]]; then
    printf 'Error: project config is missing: %s\n' "$SOURCE" >&2
    exit 1
fi

echo "Niri setup"
echo "----------"

if pacman -Q niri >/dev/null 2>&1; then
    echo "Package: Niri is already installed."
else
    echo "Package: Niri needs to be installed from the official repositories."
fi

if [[ -e "$DEST" || -L "$DEST" ]]; then
    if cmp -s "$SOURCE" "$DEST"; then
        echo "Config already matches: $DEST"
    elif [[ "$FORCE" == true ]]; then
        echo "Will back up and replace: $DEST"
    else
        echo "Will preserve existing config: $DEST"
        echo "Use --force to back it up and replace it with the project config."
    fi
else
    echo "Will install: $DEST"
fi

if [[ "$DRY_RUN" == true ]]; then
    echo
    echo "Preview complete; no changes were made."
    exit 0
fi

echo
if [[ "$FORCE" == true ]]; then
    echo "Force mode will replace the existing config after making a backup."
fi
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || {
    echo "Cancelled."
    exit 0
}

if ! pacman -Q niri >/dev/null 2>&1; then
    sudo pacman -S --needed niri
fi

install -d "$DEST_DIR"

if [[ -e "$DEST" || -L "$DEST" ]]; then
    if cmp -s "$SOURCE" "$DEST"; then
        echo "Config already matches; no replacement needed."
        exit 0
    fi

    if [[ "$FORCE" != true ]]; then
        echo "Preserving existing config: $DEST"
        echo "Use --force to replace it with the project config."
        exit 0
    fi

    backup="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
    if [[ -e "$backup" || -L "$backup" ]]; then
        printf 'Error: backup already exists: %s\n' "$backup" >&2
        exit 1
    fi

    cp -a -- "$DEST" "$backup"
    echo "Backed up: $backup"
fi

install -m 644 -- "$SOURCE" "$DEST"
echo "Installed: $DEST"
echo
echo "Niri setup complete."
echo "The new config takes effect when Niri reloads its configuration."
