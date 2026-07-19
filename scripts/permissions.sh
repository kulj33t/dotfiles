#!/usr/bin/env bash


DIR="$(cd "$(dirname "$0")" && pwd)"


find "$DIR" \
-type f \
-name "*.sh" \
-exec chmod +x {} \;


echo "All scripts are executable."
