return {
    "folke/persistence.nvim",
    event = "BufReadPre",
    keys = {
        {
            "<leader>qs",
            function()
                require("persistence").load()
            end,
            desc = "Restore Session",
        },
        {
            "<leader>qS",
            function()
                require("persistence").select()
            end,
            desc = "Select Session",
        },
        {
            "<leader>ql",
            function()
                require("persistence").load { last = true }
            end,
            desc = "Restore Last Session",
        },
        {
            "<leader>qd",
            function()
                require("persistence").stop()
            end,
            desc = "Don't Save Current Session",
        },
    },
    opts = {},
    config = function(_, opts)
        require("persistence").setup(opts)

        vim.api.nvim_create_autocmd("User", {
            pattern = "PersistenceSavePre",
            callback = function()
                require("nvim-tree.view").close()
                require("dapui").close()
            end,
        })
    end
}
