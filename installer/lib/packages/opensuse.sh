#!/usr/bin/env bash

os_update_system() {
    echo 'Updating openSUSE Tumbleweed with a distribution upgrade...'
    if ! sudo zypper --non-interactive --auto-agree-with-licenses dup; then
        echo 'openSUSE system update failed; no dotfiles were deployed.' >&2
        return 1
    fi
}

_install_required_opensuse() {
    sudo zypper --non-interactive install "$@"
}

_install_optional_opensuse() {
    sudo zypper --non-interactive install "$1"
}

os_install_packages() {
    local required=(
        hyprland waybar wofi kitty SwayNotificationCenter swayidle swaylock swaybg
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xwayland
    )
    local optional=(
        cliphist wl-clipboard brightnessctl playerctl grim slurp jq
        zsh fastfetch htop thunar xdg-utils libnotify-tools fontconfig adwaita-icon-theme
        pavucontrol blueman wireplumber pipewire-pulseaudio curl tar xz procps
        gtklock swappy awww NetworkManager NetworkManager-tui NetworkManager-applet polkit-gnome
    )

    install_required_packages 'openSUSE Tumbleweed' _install_required_opensuse "${required[@]}" || return 1
    install_optional_packages _install_optional_opensuse "${optional[@]}"
}
