return {
    "nvim-mini/mini.animate",
    version = "*",
    event = "VeryLazy",
    config = function()
        local animate = require "mini.animate"

        vim.api.nvim_set_hl(0, "MiniAnimateNormalFloat", { link = "Visual" })

        local timing = animate.gen_timing.quadratic { easing = "out", duration = 300, unit = "total" }
        local blend = animate.gen_winblend.linear { from = 65, to = 100 }

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
