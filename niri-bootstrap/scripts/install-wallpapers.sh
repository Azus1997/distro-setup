#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Azus1997/wallpapers"
TARGET_DIR="$HOME/Pictures/wallpapers"

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is missing. Install official packages first." >&2
    exit 1
fi

if [[ -e "$TARGET_DIR" ]]; then
    if git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        existing_origin="$(git -C "$TARGET_DIR" remote get-url origin 2>/dev/null || true)"

        if [[ "$existing_origin" == "$REPO_URL" ]]; then
            echo "Wallpaper repository already exists: $TARGET_DIR"
            echo "Skipping clone; existing files will not be changed."
            exit 0
        fi
    fi

    echo "Error: destination already exists but is not the expected wallpaper repository:" >&2
    echo "  $TARGET_DIR" >&2
    echo "No files were changed. Back up or move this directory before retrying." >&2
    exit 1
fi

mkdir -p "$(dirname "$TARGET_DIR")"

echo "Cloning wallpapers into: $TARGET_DIR"
git clone "$REPO_URL" "$TARGET_DIR"

echo "Wallpaper repository cloned successfully."
