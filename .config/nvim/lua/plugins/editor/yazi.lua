---@type LazySpec
return {
    "mikavilpas/yazi.nvim",
    keys = {
        {
            "<leader>=o",
            "<cmd>Yazi<cr>",
            desc = "Yazi at buf",
        },
        {
            "<leader>=O",
            "<cmd>Yazi cwd<cr>",
            desc = "Yazi at cwd",
        },
        {
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
