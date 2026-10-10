#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

DRY_RUN=false
FORCE=false

usage() {
    cat <<'EOF'
Usage: setup-gtk.sh [OPTIONS]

Deploy nwg-look and GTK 3/GTK 4 settings.

Options:
  --dry-run   Show planned actions without changing anything
  --force     Back up and replace existing configuration files
  --help      Show this help message
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'Error: Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ ! -f /etc/arch-release ]]; then
    printf 'Error: This script is intended for Arch Linux.\n' >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    printf 'Error: Run this script as your normal user, not root.\n' >&2
    exit 1
fi

for cmd in pacman sudo install cp date mkdir; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: Required command not found: %s\n' "$cmd" >&2
        exit 1
    fi
done

declare -a SOURCES=(
    "$PROJECT_DIR/dotfiles/nwg-look/config"
    "$PROJECT_DIR/dotfiles/gtk-3.0/settings.ini"
    "$PROJECT_DIR/dotfiles/gtk-4.0/settings.ini"
)

declare -a TARGETS=(
    "$HOME/.config/nwg-look/config"
    "$HOME/.config/gtk-3.0/settings.ini"
    "$HOME/.config/gtk-4.0/settings.ini"
)

for source in "${SOURCES[@]}"; do
    if [[ ! -f "$source" ]]; then
        printf 'Error: Source file not found: %s\n' "$source" >&2
        exit 1
    fi
done

if pacman -Q nwg-look >/dev/null 2>&1; then
    PACKAGE_INSTALLED=true
else
    PACKAGE_INSTALLED=false
fi

printf '%s\n' 'GTK / nwg-look setup'
printf '%s\n' '---------------------'

if [[ $PACKAGE_INSTALLED == true ]]; then
    printf '%s\n' 'Package: nwg-look is already installed.'
else
    printf '%s\n' 'Package: nwg-look needs to be installed.'
fi

for i in "${!SOURCES[@]}"; do
    source="${SOURCES[$i]}"
    target="${TARGETS[$i]}"

    if [[ -e "$target" ]]; then
        if cmp -s "$source" "$target"; then
            printf 'Already matches: %s\n' "$target"
        elif [[ $FORCE == true ]]; then
            printf 'Replace with backup: %s\n' "$target"
        else
            printf 'Preserve existing: %s\n' "$target"
        fi
    else
        printf 'Deploy: %s\n' "$target"
    fi
done

if [[ $DRY_RUN == true ]]; then
    printf '\n%s\n' 'Dry run complete. No changes made.'
    exit 0
fi

if [[ $FORCE == false ]]; then
    printf '\n%s\n' \
        'Existing configuration files will be preserved. Use --force to replace them.'
fi

read -r -p 'Continue? [y/N] ' answer
case "$answer" in
    [yY]|[yY][eE][sS]) ;;
    *)
        printf '%s\n' 'Cancelled.'
        exit 0
        ;;
esac

if [[ $PACKAGE_INSTALLED == false ]]; then
    sudo pacman -S --needed nwg-look
fi

backup_timestamp="$(date +%Y%m%d-%H%M%S)"

for i in "${!SOURCES[@]}"; do
    source="${SOURCES[$i]}"
    target="${TARGETS[$i]}"

    if [[ -e "$target" ]]; then
        if cmp -s "$source" "$target"; then
            printf 'Unchanged: %s\n' "$target"
            continue
        fi

        if [[ $FORCE == false ]]; then
            printf 'Preserving existing file: %s\n' "$target"
            continue
        fi

        backup="${target}.bak.${backup_timestamp}"
        if [[ -e "$backup" ]]; then
            printf 'Error: Backup already exists: %s\n' "$backup" >&2
            exit 1
        fi

        cp -a -- "$target" "$backup"
        printf 'Backup created: %s\n' "$backup"
    fi

    install -Dm644 -- "$source" "$target"
    printf 'Installed: %s\n' "$target"
done

printf '\n%s\n' 'GTK / nwg-look setup complete.'
