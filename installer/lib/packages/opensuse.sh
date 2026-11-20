#!/usr/bin/env bash
install_packages_opensuse() {
    echo 'Installing required packages from openSUSE Tumbleweed repositories...'
    local required=(
        hyprland waybar wofi kitty SwayNotificationCenter swayidle swaylock swaybg
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xwayland
        cliphist wl-clipboard brightnessctl playerctl grim slurp jq
        zsh fastfetch htop thunar xdg-utils libnotify-tools fontconfig adwaita-icon-theme
        pavucontrol blueman wireplumber pipewire-pulseaudio curl tar xz procps
    )
    sudo zypper --non-interactive install "${required[@]}" || return 1

    local optional
    for optional in gtklock swappy awww NetworkManager NetworkManager-tui NetworkManager-applet polkit-gnome; do
        sudo zypper --non-interactive install "$optional" >/dev/null 2>&1 || \
            printf 'Optional package unavailable or skipped: %s\n' "$optional"
    done
}
