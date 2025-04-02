return {
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1500,
        config = function()
            require("kanagawa").setup {}
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
