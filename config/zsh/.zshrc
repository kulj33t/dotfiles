# ==============================================================================
# dotFiles - Universal Zsh Configuration
# ==============================================================================

# User PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# History Configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Auto-completion
autoload -Uz compinit
compinit -d "$HOME/.cache/zcompdump"

# High-Visibility Colored Prompt
autoload -Uz colors && colors
PROMPT='%F{green}%n%f%F{red}@%f%F{magenta}%m%f%F{red}:%f%F{yellow}%~%f%F{cyan}$%f '

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

# Keyboard Backlight Toggle & Theme Selector
alias keyboard-light='bash ~/.config/waybar/scripts/kbdbacklight.sh toggle'
alias theme='bash ~/.config/scripts/wofi-theme.sh'

# Source syntax highlighting and autosuggestions if installed
for file in \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    if [ -f "$file" ]; then
        source "$file"
    fi
done
