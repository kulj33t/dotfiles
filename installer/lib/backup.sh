#!/usr/bin/env bash
# Preserve existing config directories and shell files before deployment.

backup_existing_configs() {
    local repo_dir="$1"
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local timestamp backup_dir backed_up=0 item source_path
    timestamp=$(date +'%Y%m%d_%H%M%S')
    backup_dir=$(mktemp -d "$HOME/.dotfiles-backup.$timestamp.XXXXXX") || return 1

    # Back up every top-level config this checkout deploys so new config folders
    # cannot silently overwrite a user's files when the package map grows.
    for source_path in "$repo_dir"/config/* "$repo_dir"/config/.[!.]* "$repo_dir"/config/..?*; do
        [[ -e "$source_path" || -L "$source_path" ]] || continue
        item="${source_path##*/}"
        if [[ -e "$config_home/$item" || -L "$config_home/$item" ]]; then
            mkdir -p "$backup_dir/config"
            mv "$config_home/$item" "$backup_dir/config/$item"
            backed_up=$((backed_up + 1))
        fi
    done

    for item in scripts themes dotfiles; do
        if [[ -e "$config_home/$item" || -L "$config_home/$item" ]]; then
            mkdir -p "$backup_dir/config"
            mv "$config_home/$item" "$backup_dir/config/$item"
            backed_up=$((backed_up + 1))
        fi
    done

    # Back up home files this checkout replaces. The managed ~/.zshenv redirects
    # ZDOTDIR, so preserve an existing ~/.zshrc too even though it is not replaced.
    for source_path in "$repo_dir"/home/.[!.]* "$repo_dir"/home/..?*; do
        [[ -f "$source_path" ]] || continue
        item="${source_path##*/}"
        if [[ -e "$HOME/$item" || -L "$HOME/$item" ]]; then
            mkdir -p "$backup_dir/home"
            mv "$HOME/$item" "$backup_dir/home/$item"
            backed_up=$((backed_up + 1))
        fi
    done
    if [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
        mkdir -p "$backup_dir/home"
        mv "$HOME/.zshrc" "$backup_dir/home/.zshrc"
        backed_up=$((backed_up + 1))
    fi

    if (( backed_up > 0 )); then
        printf 'Backed up %s existing items to %s\n' "$backed_up" "$backup_dir"
    else
        rmdir "$backup_dir" 2>/dev/null || true
        echo 'No existing dotfile conflicts found.'
    fi
}
