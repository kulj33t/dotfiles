#!/usr/bin/env bash
install_packages_fedora() {
    # The Fedora base repositories do not currently provide Hyprland 0.55+.
    # Use a maintained COPR with architecture-specific builds.
    # shellcheck source=/dev/null
    source /etc/os-release
    local fedora_version="${VERSION_ID%%.*}"
    local machine_arch copr_project repo_pattern hyprland_package
    machine_arch="$(uname -m)"
    case "${fedora_version}:${machine_arch}" in
        43:x86_64|44:x86_64|45:x86_64)
            copr_project='ashbuk/Hyprland-Fedora'
            hyprland_package=hyprland
            ;;
        43:aarch64|44:aarch64)
            # nett00n publishes ARM64 builds for Fedora 43 and 44.
            copr_project='nett00n/hyprland'
            hyprland_package=Hyprland
            ;;
        45:aarch64)
            # Fedora 45 ARM64 Hyprland is currently published by this project.
            copr_project='hermitfeather/hyprland'
            hyprland_package=hyprland
            ;;
        *)
            printf 'Fedora %s on %s is outside the packaged Hyprland 0.55+ targets (Fedora 43-45 on x86_64 or aarch64).\n' \
                "$fedora_version" "$machine_arch" >&2
            return 1
            ;;
    esac

    echo "Enabling the $copr_project COPR for Hyprland 0.55+..."
    if ! dnf copr --help >/dev/null 2>&1; then
        sudo dnf install -y dnf5-plugins || return 1
    fi
    repo_pattern="${copr_project//\//.*}"
    if ! dnf repolist --enabled 2>/dev/null | grep -iE "$repo_pattern" >/dev/null; then
        sudo dnf copr enable -y "$copr_project" || return 1
    fi

    echo 'Installing required Fedora packages...'
    local required=(
        "$hyprland_package" waybar wofi kitty SwayNotificationCenter swayidle swaylock swaybg
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-x11-server-Xwayland
        cliphist wl-clipboard brightnessctl playerctl grim slurp jq
        zsh fastfetch htop thunar xdg-utils libnotify fontconfig adwaita-icon-theme adwaita-cursor-theme
        pavucontrol blueman wireplumber pipewire-pulseaudio curl tar xz procps-ng
    )
    sudo dnf install -y "${required[@]}" || return 1

    local optional
    for optional in gtklock swappy awww NetworkManager NetworkManager-tui NetworkManager-gnome polkit-gnome; do
        sudo dnf install -y "$optional" >/dev/null 2>&1 || \
            printf 'Optional package unavailable or skipped: %s\n' "$optional"
    done
}
