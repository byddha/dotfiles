return {
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1500,
        config = function()
            require("kanagawa").setup {
                overrides = function(_)
                    return {
                        DapStopped = { bg = "#2a2a37" }, -- LineNr
                        SnacksPickerTree = { bg = "#16161D", fg = "#727169" }, -- NormalFloat, Comment
                    }
                end,
            }
            vim.cmd.colorscheme "kanagawa"
        end,
    },
    { import = "plugins.ai" },
    { import = "plugins.coding" },
    { import = "plugins.debugging" },
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.ui" },
    { import = "plugins.utils" },
    { import = "plugins.snacks" },
}
