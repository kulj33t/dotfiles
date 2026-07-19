#!/usr/bin/env bash

set -e


DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"


echo "Updating dotFiles..."


cd "$DOTFILES"


git pull


echo "Running installer..."


./install.sh
