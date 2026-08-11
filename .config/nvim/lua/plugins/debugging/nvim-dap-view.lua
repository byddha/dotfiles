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
                breakpoints = { label = " Breakpoints" },
                scopes = { label = "󰂥 Scopes" },
                exceptions = { label = "󰢃 Exceptions" },
                watches = { label = "󰛐 Watches" },
                threads = { label = "󱉯 Threads" },
                repl = { label = "󰯃 REPL" },
                console = { label = "󰆍 Console" },
            },
        },
        auto_toggle = true,
        windows = { terminal = { position = "right" } },
    },
}
