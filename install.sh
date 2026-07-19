#!/usr/bin/env bash

set -euo pipefail


############################################
# DotFiles Hyprland Installer
############################################


VERSION="1.0"


############################################
# Colors
############################################

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"


info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}


success() {
    echo -e "${GREEN}[ OK ]${RESET} $1"
}


warning() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}


error() {
    echo -e "${RED}[ERROR]${RESET} $1"
    exit 1
}


############################################
# Paths
############################################

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG="$HOME/.config"


############################################
# Root Check
############################################

if [ "$EUID" -eq 0 ]; then
    error "Do not run this installer as root."
fi


############################################
# Detect Linux Distribution
############################################

if [ ! -f /etc/os-release ]; then
    error "Cannot detect Linux distribution."
fi


source /etc/os-release


DISTRO="$ID"


ASAHI=false


if grep -qi "asahi" /etc/os-release; then
    ASAHI=true
fi


info "Detected system: $PRETTY_NAME"



############################################
# Update System
############################################

update_system()
{

case "$DISTRO" in


    fedora)

        info "Updating Fedora..."

        sudo dnf upgrade --refresh -y

        ;;


    arch)

        info "Updating Arch Linux..."

        sudo pacman -Syu --noconfirm

        ;;


    ubuntu|debian)

        info "Updating Debian/Ubuntu..."

        sudo apt update
        sudo apt upgrade -y

        ;;


    *)

        error "Unsupported distribution: $DISTRO"

        ;;

esac


success "System updated."

}


update_system



############################################
# Install Packages
############################################

install_packages()
{


info "Installing packages..."


COMMON="$DOTFILES/packages/common.txt"


if [ ! -f "$COMMON" ]; then
    error "packages/common.txt missing."
fi



case "$DISTRO" in


fedora)


    sudo dnf install -y \
    $(grep -v '^#' "$COMMON") \
    $(grep -v '^#' "$DOTFILES/packages/fedora.txt")


;;


arch)


    sudo pacman -S --needed --noconfirm \
    $(grep -v '^#' "$COMMON") \
    $(grep -v '^#' "$DOTFILES/packages/arch.txt")


;;


ubuntu|debian)


    sudo apt install -y \
    $(grep -v '^#' "$COMMON") \
    $(grep -v '^#' "$DOTFILES/packages/debian.txt")


;;


esac


success "Packages installed."

}



install_packages



############################################
# Backup Existing Config
############################################

backup_config()
{


if [ -d "$CONFIG" ]; then


    BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"


    info "Backing up existing ~/.config..."


    cp -a "$CONFIG" "$BACKUP"


    success "Backup created:"
    echo "$BACKUP"


fi


mkdir -p "$CONFIG"


}



backup_config



############################################
# Copy DotFiles
############################################

install_configs()
{


info "Copying configuration files..."


for ITEM in "$DOTFILES"/*;
do


    NAME=$(basename "$ITEM")



    case "$NAME" in


        install.sh)
            continue
            ;;


        packages)
            continue
            ;;


        fonts)
            continue
            ;;


        wallpaper)
            continue
            ;;


        scripts)
            continue
            ;;


    esac



    cp -a "$ITEM" "$CONFIG/"


done



success "Configuration installed."

}



install_configs



############################################
# Install Fonts
############################################

install_fonts()
{


if [ -d "$DOTFILES/fonts" ]; then


    info "Installing fonts..."


    mkdir -p "$HOME/.local/share/fonts"


    cp -a "$DOTFILES/fonts/." \
    "$HOME/.local/share/fonts/"


    fc-cache -fv >/dev/null



    success "Fonts installed."


fi


}


install_fonts



############################################
# Install Wallpapers
############################################

install_wallpaper()
{


if [ -d "$DOTFILES/wallpaper" ]; then


    info "Installing wallpapers..."


    mkdir -p "$HOME/Pictures/Wallpapers"


    cp -a "$DOTFILES/wallpaper/." \
    "$HOME/Pictures/Wallpapers/"


    success "Wallpapers installed."


fi


}


install_wallpaper



############################################
# Script Permissions
############################################

make_scripts_executable()
{


info "Setting script permissions..."


if [ -d "$DOTFILES/scripts" ]; then


    find "$DOTFILES/scripts" \
    -type f \
    -name "*.sh" \
    -exec chmod +x {} \;


fi


success "Permissions updated."


}



make_scripts_executable



############################################
# Enable Services
############################################

enable_services()
{


info "Enabling services..."


sudo systemctl enable NetworkManager || true


sudo systemctl enable bluetooth || true



systemctl --user enable pipewire.service || true


systemctl --user enable wireplumber.service || true



success "Services enabled."


}



enable_services



############################################
# Fedora Asahi
############################################

if [ "$ASAHI" = true ]; then


    warning "Fedora Asahi detected."

    echo "Using Fedora Asahi compatibility mode."


fi



############################################
# Post Install
############################################

if [ -f "$DOTFILES/scripts/post-install.sh" ]; then


    info "Running post install script..."


    "$DOTFILES/scripts/post-install.sh"


fi



############################################
# Complete
############################################

echo

echo -e "${GREEN}"
echo "======================================="
echo "       DotFiles Installation Done"
echo "======================================="
echo -e "${RESET}"


echo
echo "Installed:"
echo "  Hyprland configuration"
echo "  Kitty"
echo "  Waybar"
echo "  Wofi"
echo "  SwayNC"
echo "  Swaylock"
echo "  Fastfetch"
echo "  CopyQ"
echo "  Fonts"
echo "  Wallpapers"
echo


echo "Backup location:"
echo "$BACKUP"


echo

echo "Restart your session and select Hyprland."
