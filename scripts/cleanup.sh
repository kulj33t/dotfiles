#!/usr/bin/env bash

set -e


echo "Cleaning cache..."


rm -rf "$HOME/.cache/thumbnails/"*


echo "Removing old backups..."


find "$HOME" \
-name ".config-backup-*" \
-type d \
-mtime +30 \
-exec rm -rf {} \;


echo "Cleanup finished."
