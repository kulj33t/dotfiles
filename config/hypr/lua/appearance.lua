hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 3,
        resize_on_border = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 0.90,
        dim_inactive = true,
        dim_strength = 0.1,
        shadow = {
            enabled = true,
            range = 15,
            render_power = 3,
            color = "rgba(1a1b26ee)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            new_optimizations = true,
            vibrancy = 0.1696,
        },
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo = true,
        session_lock_blur = true,
        session_lock_xray = true,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            scroll_factor = 1.5,
        },
    },
})
hl.config({
    general = {
        col = {
            active_border = {
                colors = { "rgba(7aa2f7ee)", "rgba(bb9af7ee)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
    },
})

hl.curve("fluent", {
    type = "bezier",
    points = { { 0.05, 0.9 }, { 0.1, 1.0 } },
})

for _, animation in ipairs({ "windows", "windowsIn", "windowsOut" }) do
    hl.animation({ leaf = animation, enabled = true, speed = 4, bezier = "fluent", style = "popin 80%" })
end
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "fluent", style = "slide" })
