#!/usr/bin/env bash

os_update_system() {
    echo 'Updating Arch Linux before installing packages (full sync and upgrade avoids partial upgrades)...'
    if ! sudo pacman -Syu --noconfirm; then
        echo 'Arch system update failed; no dotfiles were deployed.' >&2
        return 1
    fi
}

_install_required_arch() {
    sudo pacman -S --needed --noconfirm "$@"
}

_install_optional_arch() {
    sudo pacman -S --needed --noconfirm "$1"
}

os_install_packages() {
    local required=(
        hyprland waybar wofi kitty swaync swayidle swaylock swaybg
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xwayland
    )
    local optional=(
        cliphist wl-clipboard brightnessctl playerctl grim slurp jq
        zsh fastfetch htop thunar xdg-utils libnotify fontconfig adwaita-icon-theme adwaita-cursors
        pavucontrol blueman wireplumber pipewire pipewire-pulse curl tar procps-ng pacman-contrib
        gtklock swappy awww networkmanager polkit-gnome
    )

    install_required_packages 'Arch Linux' _install_required_arch "${required[@]}" || return 1
    install_optional_packages _install_optional_arch "${optional[@]}"
}
