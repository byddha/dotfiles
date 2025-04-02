return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
        return {
            current_line_blame = true,
            current_line_blame_opts = {
                delay = 400,
                virt_text_pos = "eol",
            },
            signs = {
                delete = { text = "󰍵" },
                changedelete = { text = "󱕖" },
            },
        }
    end,
    keys = {
        {
            "<Leader>ghp",
            function()
                require("gitsigns").preview_hunk_inline()
            end,
            desc = "Preview hunk inline",
            noremap = true,
            silent = true,
        },
        {
            "<Leader>ghr",
            function()
                require("gitsigns").reset_hunk()
            end,
            desc = "Reset hunk",
            noremap = true,
            silent = true,
        },
        {
            "<leader>ghR",
            function()
                require("gitsigns").reset_buffer()
            end,
            desc = "Reset Buffer",
            noremap = true,
            silent = true,
        },
        {
            "<leader>ghd",
            function()
                require("gitsigns").diffthis()
            end,
            desc = "Diff This",
            noremap = true,
            silent = true,
        },
        {
            "<leader>ghD",
            function()
                require("gitsigns").diffthis "~"
            end,
            desc = "Diff This ~",
            noremap = true,
            silent = true,
        },
        {
            "]h",
            function()
                if vim.wo.diff then
                    vim.cmd.normal { "]h", bang = true }
                else
                    require("gitsigns").nav_hunk "next"
                end
            end,
            desc = "Next hunk",
            noremap = true,
            silent = true,
        },
        {
            "[h",
            function()
                if vim.wo.diff then
                    vim.cmd.normal { "[h", bang = true }
                else
                    require("gitsigns").nav_hunk "prev"
                end
            end,
            desc = "Previous hunk",
            noremap = true,
            silent = true,
        },
    },
}
