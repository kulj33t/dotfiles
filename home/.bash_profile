# ==============================================================================
# dotFiles - Bash Login Profile
# ==============================================================================

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Autostart Hyprland on TTY1 login
if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && [ -t 0 ] && [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; then
    exec Hyprland
fi
