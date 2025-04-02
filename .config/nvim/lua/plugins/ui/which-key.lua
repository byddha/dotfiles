return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    opts = {
        preset = "helix",
        defaults = {},
        spec = {
            {
                mode = { "n", "v" },
                { "<leader>c", group = "code" },
                { "<leader>d", group = "debug" },
                { "<leader>f", group = "find" },
                { "<leader>g", group = "git" },
                { "<leader>gh", group = "hunks" },
                { "<leader>gt", group = "diffview" },
                { "<leader>=", group = "file browser" },
                { "<leader><leader>", group = "terminal" },
                { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
                { "<leader>n", group = "notifications" },
                { "<leader><tab>", group = "tabs" },
                { "<leader>q", group = "quit/session" },
                { "<leader>u", group = "ui" },

                { "[", group = "prev" },
                { "]", group = "next" },
                { "g", group = "goto" },
                { "z", group = "fold" },
                {
                    "<leader>b",
                    group = "buffer",
                    expand = function()
                        return require("which-key.extras").expand.buf()
                    end,
                },
                {
                    "<leader>w",
                    group = "windows",
                    proxy = "<c-w>",
                    expand = function()
                        return require("which-key.extras").expand.win()
                    end,
                },
            },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show { global = false }
            end,
            desc = "Buffer Keymaps (which-key)",
        },
        {
            "<c-w><space>",
            function()
                require("which-key").show { keys = "<c-w>", loop = true }
            end,
            desc = "Window Hydra Mode (which-key)",
        },
    },
    config = function(_, opts)
        local wk = require "which-key"
        wk.setup(opts)
        if not vim.tbl_isempty(opts.defaults) then
            print "which-key: opts.defaults is deprecated. Please use opts.spec instead."
            wk.register(opts.defaults)
        end
    end,
}
