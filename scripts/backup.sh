#!/usr/bin/env bash

set -e

BACKUP="$HOME/.config-backup-$(date +%Y-%m-%d-%H-%M-%S)"

echo "Creating config backup..."

if [ -d "$HOME/.config" ]; then
    cp -a "$HOME/.config" "$BACKUP"
    echo "Backup created:"
    echo "$BACKUP"
else
    echo "No ~/.config directory found."
fi
