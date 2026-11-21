# dotFiles

A modular Hyprland desktop setup for x86_64 Arch Linux, openSUSE Tumbleweed, Debian 13 (Trixie), and package-managed Fedora 43–45 on x86_64 or aarch64, including Fedora Asahi Remix. It includes a macOS Spotlight-style Wofi launcher, Waybar, SwayNC notifications, GTKLock with a swaylock fallback, idle and suspend locking, curated desktop-wide palettes, and wallpaper switching.

The compositor config uses Hyprland's Lua API and requires Hyprland 0.55 or newer. Fedora x86_64 uses the `ashbuk/Hyprland-Fedora` COPR; Fedora 43–44 aarch64 uses `nett00n/hyprland`, and Fedora 45 aarch64 uses `hermitfeather/hyprland`. Debian support is Trixie with official backports.

## Install

```bash
./install.sh
```

Run as your regular user. After one confirmation, the installer installs core packages, tries optional packages individually, and deploys the configs. Fedora installs SDDM and sets it as the default graphical display manager for the next boot; the full system upgrade is skipped by default. To request that upgrade, run `DOTFILES_UPDATE_SYSTEM=1 ./install.sh`. Arch and Tumbleweed run their full system upgrade. Missing optional packages are skipped and logged to `~/.local/state/dotfiles-installer/optional-packages.log`; if a core package transaction fails, deployment stops before replacing configs. Existing config folders and replaced shell startup files are moved to `~/.dotfiles-backup.<timestamp>.<suffix>`; an existing `.zshrc` is included because the managed `.zshenv` redirects Zsh to the config directory. Configs, scripts, and theme assets are copied to `$XDG_CONFIG_HOME` (usually `~/.config`), so edits to the installed config do not change the checkout. Bash/Zsh startup files are linked from this repository.

On Fedora, SDDM becomes the default display manager and the machine's default boot target becomes `graphical.target`; this takes effect after reboot. The installer disables the previous display-manager service for the next boot but leaves its package installed, so its desktop session can still be selected in SDDM. The SDDM greeter gets the Adwaita cursor theme at 24px. GTKLock remains the in-session screen locker and uses swaylock as a fallback. Other distro modules leave display-manager settings alone. The installer leaves network-service and GPU-driver settings unchanged. Fedora uses a third-party COPR because current Fedora base packages do not provide the Lua-compatible Hyprland build; Debian installs Hyprland from official Trixie backports. Fedora Atomic editions and openSUSE MicroOS, Aeon, and Kalpa are rejected because their deployment model needs a different installer.

## Desktop components

- **Hyprland 0.55+** — modular Lua configuration in `config/hypr/`.
- **Wofi** — centered Spotlight-style app search and menus, styled with GTK CSS.
- **Waybar** — workspaces, system metrics, battery, audio, network, updates, clipboard, and notification controls.
- **SwayNC** — notification daemon and history/control center, opened with Super+N or the Waybar bell.
- **GTKLock / swaylock / swayidle** — GTKLock provides the themed lock screen when installed; swaylock is the fast fallback and shares the active palette. swayidle locks after 3 minutes idle, turns displays off after 5 minutes, and locks before suspend. GTKLock is started on demand rather than kept resident.
- **swaybg / awww** — swaybg works as the baseline wallpaper backend. awww adds animated transitions when available as a package; existing swww installations also work.
- **Default terminal and Thunar** — Super+T launches the system-selected terminal through `xdg-terminal-exec`, with common terminal fallbacks. Kitty is optional.
- **PipeWire, WirePlumber, and PipeWire PulseAudio** — audio controls and Waybar audio status.
- **cliphist, wl-clipboard, grim, slurp, jq** — clipboard and screenshots.

## Themes and wallpapers

The bundled themes are Tokyo Night, Catppuccin Mocha, Gruvbox, Nord, and Everforest. Switch with **Super+Shift+T**; choose a wallpaper with **Super+Shift+W**. Theme colors are applied to Hyprland borders, Waybar, Wofi, GTK3 apps, GTKLock, SwayNC, and Kitty. Each theme can include its own `wallpapers/` directory; the wallpaper menu finds images recursively.

Generated CSS and selected theme/wallpaper state are stored in the active user config tree, not in the repository. Curated color palettes are implemented now. Automatic wallpaper color extraction is a later feature.

## Package and architecture details

See [the architecture guide](docs/ARCHITECTURE.md) for the stack diagram, package-source decisions, per-distribution package names, optional components, and runtime validation checklist.

## Key controls

| Shortcut | Action |
|---|---|
| Super+Space | App launcher |
| Super+T | System-selected terminal |
| Super+E | Thunar |
| Super+N | SwayNC control center |
| Super+L | Lock screen |
| Super+Shift+L | Power menu |
| Super+Shift+S | Screenshot menu |
| Super+Shift+T | Theme picker |
| Super+Shift+W | Wallpaper picker |
| Super+V | Clipboard history |

On Fedora, choose Hyprland or another installed session from SDDM's session picker. You can also log in through Bash on TTY1 to use the included auto-start profile. Other distro modules keep the existing display-manager setup.
