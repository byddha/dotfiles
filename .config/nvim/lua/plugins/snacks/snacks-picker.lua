return {
    "folke/snacks.nvim",
    opts = {
        picker = {
            enabled = true,
            -- every layout preset ships `backdrop = false`; turn it back on for
            -- all pickers so they dim the editor like the lazygit window does
            -- lower blend = darker; 60 is the snacks default and too weak here
            layout = { layout = { backdrop = 40 } },
            formatters = { file = { git_status_hl = false } },
            sources = {
                explorer = {
                    -- inlined `ivy`, only to give the file list more room than
                    -- the preset's 40%. Supplying the box skips preset resolution.
                    layout = {
                        preview = true,
                        layout = {
                            box = "vertical",
                            backdrop = 40,
                            row = -1,
                            width = 0,
                            height = 0.4,
                            border = "top",
                            title = " {title} {live} {flags}",
                            title_pos = "left",
                            { win = "input", height = 1, border = "bottom" },
                            {
                                box = "horizontal",
                                { win = "list", border = "none" },
                                { win = "preview", title = "{preview}", width = 0.5, border = "left" },
                            },
                        },
                    },
                    auto_close = true,
                    jump = { close = true },
                },
            },
        },
    },
    keys = {
        {
            "<leader>,",
            function()
                Snacks.picker.buffers()
            end,
            desc = "Buffers",
        },
        {
            '<leader>f"',
            function()
                Snacks.picker.registers()
            end,
            desc = "Registers",
        },
        {
            "<leader>fh",
            function()
                Snacks.picker.help()
            end,
            desc = "Help Pages",
        },
        {
            "<leader>fr",
            function()
                Snacks.picker.resume()
            end,
            desc = "Resume",
        },
        {
            "<leader>fz",
            function()
                Snacks.picker.zoxide()
            end,
            desc = "Zoxide",
        },
        {
            "<leader>fu",
            function()
                Snacks.picker.undo()
            end,
            desc = "Undo Tree",
        },
        {
            "<leader>uC",
            function()
                Snacks.picker.colorschemes()
            end,
            desc = "Colorschemes",
        },
        -- LSP
        {
            "gd",
            function()
                Snacks.picker.lsp_definitions()
            end,
            desc = "Goto Definition",
        },
        {
            "gD",
            function()
                Snacks.picker.lsp_declarations()
            end,
            desc = "Goto Declaration",
        },
        {
            "gr",
            function()
                Snacks.picker.lsp_references()
            end,
            nowait = true,
            desc = "References",
        },
        {
            "gi",
            function()
                Snacks.picker.lsp_implementations()
            end,
            desc = "Goto Implementation",
        },
        {
            "gy",
            function()
                Snacks.picker.lsp_type_definitions()
            end,
            desc = "Goto T[y]pe Definition",
        },
    },
}
