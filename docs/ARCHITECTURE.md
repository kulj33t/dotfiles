# dotFiles architecture and package plan

This repository builds a portable Hyprland desktop around distro packages and user-level configuration. The target systems are x86_64 Arch Linux, openSUSE Tumbleweed, Debian 13 (Trixie), and package-managed Fedora 43–45 on x86_64 or aarch64, including Fedora Asahi Remix. Fedora uses a community COPR for a Hyprland release that supports Lua configuration. Fedora Atomic editions and openSUSE MicroOS, Aeon, and Kalpa are outside this installer because they use a different system deployment model.

## Runtime flow

```text
Login session
└── Hyprland 0.55+ (Lua config)
    ├── Waybar ── notification toggle ── SwayNC
    ├── Wofi ── apps, power, clipboard, theme, wallpaper menus
    ├── swayidle ── GTKLock (-d) ── swaylock fallback
    ├── theme switcher ── Hyprland / Waybar / Wofi / GTK / GTKLock / SwayNC / Kitty
    └── wallpaper switcher ── awww transitions, swaybg fallback
```

`config/hypr/hyprland.lua` is the entry point. Its `lua/` modules own environment, monitor defaults, appearance, rules, binds, and session startup. Shell utilities live in `scripts/`; user interface settings live in `config/`; curated palettes and their surface-specific CSS live in `themes/`.

## Chosen components

| Area | Choice | Reason and behavior |
|---|---|---|
| Compositor | Hyprland 0.55+ with Lua | The current config uses the Lua API; older hyprlang-only builds are rejected by the installer. |
| Application launcher | Wofi | Native Wayland launcher with GTK CSS. The centered 640×380 layout uses a macOS Spotlight style, application icons, and a blue selection state. |
| Bar | Waybar | Native packages on all four targets; JSONC modules and CSS are reused across distributions. |
| Notifications | SwayNC | The notification daemon and history/control-center panel share theme colors with the bar. Super+N or the bell module opens the panel. |
| Locker and idle | GTKLock when installed; swaylock fallback; swayidle coordinator | GTKLock supplies CSS customization and detaches for idle/suspend hooks. swaylock remains the lower-overhead fallback. Neither locker is pre-warmed, avoiding a resident GTK process. A custom lock binary is out of scope because it must correctly implement Wayland session-lock and PAM authentication. |
| Wallpaper | swaybg baseline; awww when available | swaybg is the required fallback. awww supplies animated transitions when the package is available; an existing swww installation is supported for compatibility. The installer does not build either tool from source. |
| Terminal and file manager | Kitty and Thunar | Both are launched directly from Hyprland binds. |
| Audio | PipeWire, WirePlumber, PipeWire PulseAudio compatibility, pavucontrol | Supports Waybar's PulseAudio module, the volume control panel, and `wpctl` binds. |
| Clipboard history | cliphist and wl-clipboard | Stores text and image clipboard entries and exposes a Wofi picker. |
| Screenshots | grim, slurp, wl-clipboard; swappy optional | Supports whole-screen, active-window, and selected-region captures. |

## Package sources and names

The installer uses the system package manager. It does not compile compositor, wallpaper, or theme tools from source.

| System | Hyprland source | SwayNC package name | PipeWire Pulse package name | Notes |
|---|---|---|---|---|
| Arch Linux x86_64 | Official repositories | `swaync` | `pipewire-pulse` | `pacman-contrib` provides `checkupdates` for the Waybar update module. |
| openSUSE Tumbleweed | Official Tumbleweed repositories | `SwayNotificationCenter` | `pipewire-pulseaudio` | Hyprland versions are rolling; the installer checks the installed version. |
| Debian 13 Trixie | Official `trixie-backports` for Hyprland | `sway-notification-center` | `pipewire-pulse` | The installer adds the signed official backports source if it is missing. |
| Fedora 43–45 x86_64 | `ashbuk/Hyprland-Fedora` COPR | `SwayNotificationCenter` | `pipewire-pulseaudio` | COPR packages Hyprland 0.55+ with the Lua runtime it needs. |
| Fedora 43–44 aarch64 | `nett00n/hyprland` COPR | `SwayNotificationCenter` | `pipewire-pulseaudio` | Architecture-specific COPR builds cover Fedora Asahi Remix; package and compositor version checks still run before dotfiles are deployed. |
| Fedora 45 aarch64 | `hermitfeather/hyprland` COPR | `SwayNotificationCenter` | `pipewire-pulseaudio` | Uses the successful Fedora 45 ARM64 build; the installer checks the installed compositor version before deploying configs. |

The shared required set also includes Waybar, Wofi, Kitty, swayidle, swaylock, swaybg, desktop portals, XWayland, cliphist, wl-clipboard, brightnessctl, playerctl, grim, slurp, jq, Zsh, Fastfetch, htop, Thunar, xdg-utils, libnotify, fontconfig, Adwaita icons/cursors, pavucontrol, blueman, WirePlumber, curl, tar, xz, and procps. Package spellings are mapped in `installer/lib/packages/`.

Optional packages are GTKLock, swappy, awww, NetworkManager UI tools, and a Polkit authentication agent. When GTKLock is unavailable, swaylock remains usable; when awww is unavailable, wallpaper changes use swaybg without an animated transition. The Nerd Font is installed per user from the upstream JetBrainsMono Nerd Font release.

## Theme and wallpaper model

Each theme directory contains a `colors.conf` palette and CSS/config outputs for Waybar, Wofi, GTK3, GTKLock, SwayNC, and Kitty. `scripts/theme-switch.sh` copies the selected outputs into the active XDG config tree, generates matching swaylock colors, updates Hyprland border colors through IPC, and reloads supported running applications. New themes can add a `wallpapers/` directory and set `THEME_WALLPAPER_DEFAULT` to a file within it.

The wallpaper picker scans all theme wallpaper folders. The selected path is stored under `$XDG_CONFIG_HOME/dotfiles/`; generated CSS and current wallpaper state stay outside this repository. If no wallpaper is selected, Tokyo Night's `blue.png` is the shared fallback.

Curated palettes are the first implementation. Automatic palette extraction (for example, Matugen) is deferred until a package and template workflow can be maintained consistently across all four target systems.

## Installation and ownership

Run `./install.sh` as a normal user with an absolute `XDG_CONFIG_HOME` if overriding the default. After a single confirmation it installs required/optional packages, checks Hyprland version, backs up conflicting dotfile directories into `~/.dotfiles-backup.<timestamp>.<suffix>`, copies config/scripts/themes into `$XDG_CONFIG_HOME`, links the Bash/Zsh startup files, downloads the Nerd Font, and seeds the initial theme.

The Bash profile auto-starts Hyprland on TTY1; the installer does not configure a display manager, enable a network service, change boot settings, or force GPU environment variables. GPU detection is informational so Mesa, NVIDIA, and Asahi defaults remain under the distro's control.

## Current validation stage

The architecture and source files have been aligned. Runtime validation still needs to happen in a real Hyprland session on each target distribution, especially Fedora COPR installation, GTKLock layer matching, notification-panel behavior, awww package availability, and the desktop portal's screen-sharing flow.

## References

- [Hyprland Lua configuration and module loading](https://wiki.hypr.land/configuring/core/)
- [Debian Trixie backports Hyprland package](https://packages.debian.org/trixie-backports/hyprland)
- [Fedora Hyprland COPR build files](https://github.com/AshBuk/Hyprland-Fedora)
- [Fedora 43–44 aarch64 Hyprland COPR build files](https://github.com/nett00n/hyprland-copr)
- [Fedora 45 aarch64 Hyprland COPR](https://copr.fedorainfracloud.org/coprs/hermitfeather/hyprland/)
- [Fedora DNF5 plugins package](https://packages.fedoraproject.org/pkgs/dnf5/dnf5-plugins/)
- [GTKLock command options, including daemon mode](https://man.archlinux.org/man/gtklock.1.en)
- [Hyprland wallpaper utility guidance for swaybg and awww](https://wiki.hypr.land/useful-utilities/wallpapers/)
