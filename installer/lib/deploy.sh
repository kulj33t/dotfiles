#!/usr/bin/env bash
# Deploy source configs as writable copies. Theme outputs and state stay outside the repo.

deploy_configs() {
    local repo_dir="$1"
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

    mkdir -p "$config_home"
    cp -a "$repo_dir/config/." "$config_home/"
    rm -rf "$config_home/scripts" "$config_home/themes"
    cp -a "$repo_dir/scripts" "$config_home/scripts"
    cp -a "$repo_dir/themes" "$config_home/themes"
    mkdir -p "$config_home/dotfiles"

    local file target
    for file in "$repo_dir/home"/.*; do
        [[ -f "$file" ]] || continue
        target="$HOME/$(basename "$file")"
        rm -f "$target"
        ln -s "$file" "$target"
    done

    find "$config_home/scripts" "$config_home/waybar/scripts" -type f -name '*.sh' -exec chmod 0755 {} + 2>/dev/null || true
    echo "Copied configuration, scripts, and themes into $config_home."
}
