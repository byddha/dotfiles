return {
    "nvim-mini/mini.animate",
    version = "*",
    event = "VeryLazy",
    config = function()
        local animate = require "mini.animate"

        -- same black the float backdrops use, so a new split and a new picker
        -- share one visual language: surfaces emerge out of shadow
        vim.api.nvim_set_hl(0, "MiniAnimateNormalFloat", { bg = "#000000" })

        -- `static` never moves, so the fade *is* the animation: start opaque and
        -- dissolve to reveal the window
        -- "out" easing burns through the early steps and lingers on the late
        -- ones, so the tint is brief and the tail is nearly invisible; linear
        -- held it at peak for the whole first half, which is what read as loud
        local timing = animate.gen_timing.quadratic { easing = "out", duration = 220, unit = "total" }
        -- `from` is the peak tint (0 = full colour, 100 = invisible). Higher than
        -- the blue tint needed: black shifts luminance, which the eye picks up
        -- more readily than the hue shift a dark blue produces.
        local blend = animate.gen_winblend.linear { from = 72, to = 100 }

        animate.setup {
            open = {
                enable = true,
                timing = timing,
                winconfig = animate.gen_winconfig.static { n_steps = 25 },
                winblend = blend,
            },
            close = {
                enable = true,
                timing = timing,
                winconfig = animate.gen_winconfig.static { n_steps = 25 },
                winblend = blend,
            },

            scroll = { enable = false },
            cursor = { enable = false },
            resize = { enable = false },
        }
    end,
}
