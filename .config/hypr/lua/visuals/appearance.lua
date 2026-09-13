local theme = require("lua.core.theme")

hl.config({
    general    = {
        gaps_in           = 5,
        gaps_out          = 20,
        border_size       = 2,
        col               = {
            active_border   = theme.active_border,
            inactive_border = theme.inactive_border,
        },
        resize_on_border  = false,
        allow_tearing     = false,
        layout            = "scrolling",
        no_focus_fallback = true,
    },
    decoration = {
        rounding         = 10,
        rounding_power   = 2,
        active_opacity   = 1,
        inactive_opacity = 1,
        dim_special      = 0.6,
        shadow           = {
            enabled      = true,
            range        = 2,
            render_power = 3,
            color        = theme.shadow,
        },
        blur             = {
            enabled  = true,
            size     = 2,
            passes   = 1,
            special  = true,
            vibrancy = 0.1696,
        },
    },
    misc       = {
        force_default_wallpaper    = -1,
        disable_hyprland_logo      = true,
        background_color           = "rgba(0, 0, 0, 1.0)",
        initial_workspace_tracking = 0,
    },
})
