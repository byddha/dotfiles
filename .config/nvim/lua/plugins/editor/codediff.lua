return {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    opts = {
        explorer = {
            view_mode = "tree",
        },
    },
    keys = {
        { "<leader>g=", "<cmd>CodeDiff<cr>", desc = "Compare with last commit" },
        { "<leader>gg", "<cmd>CodeDiff history<cr>", desc = "View history" },
        { "<leader>gf", "<cmd>CodeDiff history %<cr>", desc = "File history" },
    },
}
