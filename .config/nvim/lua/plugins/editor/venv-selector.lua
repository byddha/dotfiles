return {
    "linux-cultist/venv-selector.nvim",
    ft = { "python" },
    dependencies = { "neovim/nvim-lspconfig" },
    opts = { name = { "venv", ".venv" } },
    keys = {
        { "<leader>cp", "<cmd>VenvSelect<cr>", desc = "Python Venv" },
        { "<leader>cP", "<cmd>VenvSelectCached<cr>", desc = "Python Cached Venv" },
    },
}
