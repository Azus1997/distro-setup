#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$ROOT_DIR/dotfiles"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

deploy_file() {
    local source="$1"
    local destination="$2"

    if [[ ! -f "$source" ]]; then
        echo "Warning: source file not found: $source" >&2
        return 1
    fi

    if [[ -e "$destination" ]]; then
        echo "Skipping existing file: $destination"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "Would install: $destination"
        return 0
    fi

    mkdir -p "$(dirname "$destination")"
    cp -- "$source" "$destination"
    echo "Installed: $destination"
}

deploy_file \
    "$DOTFILES_DIR/niri/config.kdl" \
    "$HOME/.config/niri/config.kdl"

for file in "$DOTFILES_DIR"/noctalia/*.json; do
    [[ -f "$file" ]] || continue
    deploy_file "$file" "$HOME/.config/noctalia/$(basename "$file")"
done

for file in "$DOTFILES_DIR"/kitty/*; do
    [[ -f "$file" ]] || continue
    deploy_file "$file" "$HOME/.config/kitty/$(basename "$file")"
done

if [[ "$DRY_RUN" == true ]]; then
    echo "Preview complete; no files were changed."
else
    echo "Dotfile deployment complete."
fi
