---@type LazySpec
return {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
        -- 👇 in this section, choose your own keymappings!
        {
            "<leader>=o",
            "<cmd>Yazi<cr>",
            desc = "Yazi at buf",
        },
        {
            -- Open in the current working directory
            "<leader>=O",
            "<cmd>Yazi cwd<cr>",
            desc = "Yazi at cwd",
        },
        {
            -- NOTE: this requires a version of yazi that includes
            -- https://github.com/sxyazi/yazi/pull/1305 from 2024-07-18
            "<leader>=r",
            "<cmd>Yazi toggle<cr>",
            desc = "Resume yazi",
        },
    },
    ---@type YaziConfig
    opts = {
        -- if you want to open yazi instead of netrw, see below for more info
        open_for_directories = false,
        keymaps = {
            show_help = "<f1>",
        },
    },
}
