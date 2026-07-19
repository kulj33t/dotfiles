#!/usr/bin/env bash

set -e

echo "Running post installation..."

echo "Updating font cache..."
fc-cache -fv

echo "Creating directories..."

mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/.local/bin"

echo "Reloading user services..."

systemctl --user daemon-reload || true

echo "Post installation complete."
