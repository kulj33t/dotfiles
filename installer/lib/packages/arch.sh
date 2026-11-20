#!/usr/bin/env bash
install_packages_arch() {
    if [[ "$(uname -m)" != x86_64 ]]; then
        printf 'The official Arch package map is validated for x86_64; detected %s.\n' "$(uname -m)" >&2
        return 1
    fi

    echo 'Installing required packages from Arch repositories...'
    local required=(
        hyprland waybar wofi kitty swaync swayidle swaylock swaybg
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xwayland
        cliphist wl-clipboard brightnessctl playerctl grim slurp jq
        zsh fastfetch htop thunar xdg-utils libnotify fontconfig adwaita-icon-theme adwaita-cursors
        pavucontrol blueman wireplumber pipewire pipewire-pulse curl tar xz procps-ng pacman-contrib
    )
    sudo pacman -S --needed --noconfirm "${required[@]}" || return 1

    local optional
    for optional in gtklock swappy awww networkmanager polkit-gnome; do
        sudo pacman -S --needed --noconfirm "$optional" >/dev/null 2>&1 || \
            printf 'Optional package unavailable or skipped: %s\n' "$optional"
    done
}
