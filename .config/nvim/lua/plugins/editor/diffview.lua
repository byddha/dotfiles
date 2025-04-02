return {
    "sindrets/diffview.nvim",
    lazy = true,
    opts = {
        enhanced_diff_hl = true,
        view = {
            merge_tool = {
                layout = "diff3_mixed",
            },
        },
    },
    keys = {
        {
            "<Leader>gtt",
            function()
                if next(require("diffview.lib").views) == nil then
                    vim.cmd "DiffviewOpen"
                else
                    vim.cmd "DiffviewClose"
                end
            end,
            desc = "Toggle DiffView",
            noremap = true,
            silent = true,
        },
        {
            "<Leader>gtf",
            "<Cmd>DiffviewFileHistory %<CR>",
            desc = "File history",
            noremap = true,
            silent = true,
        },
        {
            "<Leader>gtb",
            "<Cmd>DiffviewFileHistory<CR>",
            desc = "Branch history",
            noremap = true,
            silent = true,
        },
    },
    config = function(_, opts)
        require("diffview").setup(opts)
    end,
}
