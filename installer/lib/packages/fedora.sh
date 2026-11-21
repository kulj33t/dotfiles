#!/usr/bin/env bash

os_update_system() {
    if [[ "${DOTFILES_UPDATE_SYSTEM:-0}" != 1 ]]; then
        echo 'Skipping the full Fedora system upgrade.'
        echo 'Set DOTFILES_UPDATE_SYSTEM=1 when you want the installer to run dnf upgrade --refresh.'
        return 0
    fi

    echo 'Updating Fedora packages and refreshing repository metadata...'
    if ! sudo dnf upgrade --refresh -y; then
        echo 'Fedora system update failed; no dotfiles were deployed.' >&2
        echo 'Check free disk space, inodes, quotas, and write access for the DNF package cache.' >&2
        local cache_dir
        local -a diagnostic_paths=("$HOME")
        for cache_dir in /var/cache/libdnf5 /var/cache/dnf; do
            [[ -d "$cache_dir" ]] && diagnostic_paths+=("$cache_dir")
        done
        df -h "${diagnostic_paths[@]}" 2>/dev/null || true
        df -i "${diagnostic_paths[@]}" 2>/dev/null || true
        return 1
    fi
}

_install_required_fedora() {
    sudo dnf install -y "$@"
}

_install_optional_fedora() {
    sudo dnf install -y "$1"
}

os_configure_display_manager() {
    local session_dir hyprland_session_found=0
    for session_dir in /usr/share/wayland-sessions /usr/local/share/wayland-sessions; do
        if [[ -d "$session_dir" ]] && \
            find "$session_dir" -maxdepth 1 -type f -iname '*hyprland*.desktop' -print -quit 2>/dev/null | grep -q .; then
            hyprland_session_found=1
            break
        fi
    done
    if (( hyprland_session_found == 0 )); then
        echo 'The Hyprland Wayland session entry is missing; SDDM cannot offer Hyprland in its session picker.' >&2
        echo 'Check that the selected Hyprland package installed a file under /usr/share/wayland-sessions/.' >&2
        return 1
    fi

    if ! sudo install -d -m 0755 /etc/sddm.conf.d; then
        echo 'Could not create /etc/sddm.conf.d for SDDM configuration.' >&2
        return 1
    fi
    if ! printf '[Theme]\nCursorTheme=Adwaita\nCursorSize=24\n' | \
        sudo tee /etc/sddm.conf.d/99-dotfiles-cursor.conf >/dev/null; then
        echo 'Could not set a visible Adwaita cursor for the SDDM greeter.' >&2
        return 1
    fi

    local current_dm_path current_dm previous_target
    current_dm_path="$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)"
    current_dm="${current_dm_path##*/}"
    previous_target="$(systemctl get-default 2>/dev/null || true)"

    if [[ -n "$current_dm" && "$current_dm" != sddm.service ]]; then
        printf 'Disabling the previous display manager service (%s) for the next boot.\n' "$current_dm"
        if ! sudo systemctl disable "$current_dm"; then
            printf 'Could not disable the previous display manager service: %s\n' "$current_dm" >&2
            return 1
        fi
    fi

    if ! sudo systemctl enable --force sddm.service; then
        echo 'Could not set SDDM as the default display manager.' >&2
        if [[ -n "$current_dm" && "$current_dm" != sddm.service ]]; then
            sudo systemctl enable --force "$current_dm" || true
        fi
        return 1
    fi
    if ! sudo systemctl set-default graphical.target; then
        echo 'Could not set graphical.target as the default boot target.' >&2
        sudo systemctl disable sddm.service || true
        if [[ -n "$previous_target" ]]; then
            sudo systemctl set-default "$previous_target" || true
        fi
        if [[ -n "$current_dm" && "$current_dm" != sddm.service ]]; then
            sudo systemctl enable --force "$current_dm" || true
        fi
        return 1
    fi

    echo 'SDDM is enabled as the default display manager for the next boot.'
    echo 'Choose Hyprland or another installed desktop session from SDDM at login.'
    echo 'The previous display manager package remains installed; only its service is disabled.'
}

os_install_packages() {
    # Fedora's base repositories do not provide Hyprland 0.55+ on the supported targets.
    # Enable the COPR that currently publishes the matching architecture/release build.
    local fedora_version="${FEDORA_VERSION:-}"
    if [[ -z "$fedora_version" ]]; then
        # Keep the module safe when it is sourced outside install.sh in diagnostics.
        if [[ ! -r /etc/os-release ]]; then
            echo 'Cannot read /etc/os-release to determine the Fedora release.' >&2
            return 1
        fi
        # shellcheck source=/dev/null
        source /etc/os-release
        fedora_version="${VERSION_ID:-}"
    fi
    fedora_version="${fedora_version%%.*}"
    if [[ ! "$fedora_version" =~ ^[0-9]+$ ]]; then
        printf 'Could not determine a numeric Fedora release from /etc/os-release.\n' >&2
        return 1
    fi
    local machine_arch copr_project repo_pattern hyprland_package
    machine_arch="$(uname -m)"
    case "${fedora_version}:${machine_arch}" in
        43:x86_64|44:x86_64|45:x86_64)
            copr_project='ashbuk/Hyprland-Fedora'
            hyprland_package=hyprland
            ;;
        43:aarch64|44:aarch64)
            copr_project='nett00n/hyprland'
            hyprland_package=Hyprland
            ;;
        45:aarch64)
            copr_project='hermitfeather/hyprland'
            hyprland_package=hyprland
            ;;
        *)
            printf 'No supported Hyprland package source for Fedora %s on %s.\n' \
                "$fedora_version" "$machine_arch" >&2
            return 1
            ;;
    esac

    printf 'Enabling the %s COPR for Hyprland...\n' "$copr_project"
    if ! dnf copr --help >/dev/null 2>&1; then
        if ! sudo dnf install -y dnf5-plugins; then
            echo 'Could not install the DNF5 COPR plugin; stopping before desktop package installation.' >&2
            return 1
        fi
    fi
    if ! dnf copr --help >/dev/null 2>&1; then
        echo 'The DNF5 COPR plugin is still unavailable after installation; stopping before desktop package installation.' >&2
        return 1
    fi
    repo_pattern="${copr_project//\//.*}"
    if ! dnf repolist --enabled 2>/dev/null | grep -iE "$repo_pattern" >/dev/null; then
        if ! sudo dnf copr enable -y "$copr_project"; then
            printf 'Could not enable COPR %s.\n' "$copr_project" >&2
            return 1
        fi
    fi

    local required=(
        "$hyprland_package" waybar wofi SwayNotificationCenter swayidle swaylock swaybg
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-x11-server-Xwayland
        sddm adwaita-cursor-theme adwaita-icon-theme xdg-terminal-exec mate-polkit
    )
    local optional=(
        cliphist wl-clipboard brightnessctl playerctl grim slurp jq
        zsh fastfetch htop thunar xdg-utils libnotify fontconfig ImageMagick
        pavucontrol blueman wireplumber pipewire-pulseaudio curl tar xz procps-ng
        gtklock swappy awww kitty NetworkManager NetworkManager-tui NetworkManager-gnome
    )

    install_required_packages 'Fedora' _install_required_fedora "${required[@]}" || return 1
    install_optional_packages _install_optional_fedora "${optional[@]}"
}
