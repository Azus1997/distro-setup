#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE="$ROOT_DIR/dotfiles/swaylock/config"
DEST_DIR="$HOME/.config/swaylock"
DEST="$DEST_DIR/config"

DRY_RUN=false
FORCE=false

usage() {
    cat <<'USAGE'
Usage: setup-swaylock.sh [--dry-run] [--force]

Options:
  --dry-run  Preview actions without changing anything
  --force    Replace existing config, backing it up first
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

for command in pacman install cp date; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Error: required command is missing: %s\n' "$command" >&2
        exit 1
    fi
done

if [[ ! -f "$SOURCE" ]]; then
    printf 'Error: project config is missing: %s\n' "$SOURCE" >&2
    exit 1
fi

echo "Swaylock setup"
echo "--------------"

if pacman -Q swaylock-effects >/dev/null 2>&1; then
    echo "Package: swaylock-effects is already installed."
else
    echo "Package: swaylock-effects needs to be installed from the AUR."
    if ! command -v yay >/dev/null 2>&1; then
        echo "Error: yay is required to install swaylock-effects." >&2
        exit 1
    fi
fi

if [[ -e "$DEST" || -L "$DEST" ]]; then
    if cmp -s "$SOURCE" "$DEST"; then
        echo "Config already matches: $DEST"
    elif [[ "$FORCE" == true ]]; then
        echo "Will back up and replace: $DEST"
    else
        echo "Will preserve existing config: $DEST"
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
    echo "Force mode will replace the existing config after backing it up."
fi
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || {
    echo "Cancelled."
    exit 0
}

if ! pacman -Q swaylock-effects >/dev/null 2>&1; then
    yay -S --needed swaylock-effects
fi

install -d "$DEST_DIR"

if [[ -e "$DEST" || -L "$DEST" ]]; then
    if cmp -s "$SOURCE" "$DEST"; then
        echo "Config already matches; no replacement needed."
        exit 0
    fi

    if [[ "$FORCE" != true ]]; then
        echo "Preserving existing config: $DEST"
        exit 0
    fi

    backup="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
    cp -a -- "$DEST" "$backup"
    echo "Backed up: $backup"
fi

install -m 644 -- "$SOURCE" "$DEST"
echo "Installed: $DEST"
echo
echo "Swaylock setup complete."
