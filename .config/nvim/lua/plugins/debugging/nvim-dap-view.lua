return {
    "igorlfs/nvim-dap-view",
    event = "VeryLazy",
    keys = {
        {
            "<leader>du",
            function()
                require("dap-view").toggle(true)
            end,
            desc = "Toggle Debug UI",
        },
    },
    opts = {
        winbar = {
            default_section = "scopes",
            controls = { enabled = true },

            base_sections = {
                breakpoints = { label = " Breakpoints [B]" },
                scopes = { label = "󰂥 Scopes [S]" },
                exceptions = { label = "󰢃 Exceptions [E]" },
                watches = { label = "󰛐 Watches [W]" },
                threads = { label = "󱉯 Threads [T]" },
                repl = { label = "󰯃 REPL [R]" },
                console = { label = "󰆍 Console [C]" },
            },
        },
        auto_toggle = true,
        windows = { terminal = { position = "right" } },
    },
}
