hl.config({
    dwindle   = {
        preserve_split         = true,
        split_width_multiplier = 1.3,
        force_split            = 2,
    },
    master    = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = false,
        column_width             = 0.5,
        focus_fit_method         = 1, -- 0 = center, 1 = fit
        wrap_focus               = false,
    },
})
