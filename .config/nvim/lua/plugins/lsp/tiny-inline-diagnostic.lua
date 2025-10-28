return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    keys = {
        {
            "<leader>ux",
            "<cmd>TinyInlineDiag toggle<cr>",
            desc = "Toggle Inline Diagnostics",
        },
    },
    config = function()
        require("tiny-inline-diagnostic").setup {
            options = {
                show_source = {
                    enabled = true,
                },
                add_messages = {
                    display_count = true,
                },
                multilines = {
                    enabled = true,
                },
            },
        }
        vim.diagnostic.config { virtual_text = false } -- Disable Neovim's default virtual text diagnostics
    end,
}
