# ==============================================================================
# dotFiles - Universal Bash Configuration
# ==============================================================================

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Custom prompt with colors
PS1='\[\033[01;32m\]\u\[\033[01;31m\]@\[\033[38;5;135m\]\h\[\033[01;31m\]:\[\033[01;33m\]\w\[\033[00m\]\$ '

# Core Aliases
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Universal Package Manager Aliases
if command -v pacman &>/dev/null; then
    alias i='sudo pacman -S'
    alias update='sudo pacman -Syu'
    alias search='pacman -Ss'
elif command -v dnf &>/dev/null; then
    alias i='sudo dnf install'
    alias update='sudo dnf update'
    alias search='dnf search'
elif command -v zypper &>/dev/null; then
    alias i='sudo zypper install'
    alias update='sudo zypper update'
    alias search='zypper search'
elif command -v apt-get &>/dev/null; then
    alias i='sudo apt install'
    alias update='sudo apt update && sudo apt upgrade'
    alias search='apt search'
fi

# Keyboard Backlight Toggle
alias keyboard-light='bash "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/scripts/kbdbacklight.sh" toggle'
alias theme='bash "${XDG_CONFIG_HOME:-$HOME/.config}/scripts/wofi-theme.sh"'
