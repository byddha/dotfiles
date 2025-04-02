return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
        routes = {
            {
                filter = {
                    event = "notify",
                    find = "No information available",
                },

                opts = {
                    skip = true,
                },
            },
            {
                -- copilot garbage
                filter = {
                    event = "msg_show",
                    any = {
                        { find = "Agent service not initialized" },
                    },
                },
                opts = { skip = true },
            },
        },
        lsp = {
            signature = {
                enabled = false,
            },
            hover = {
                enabled = false,
                silent = true,
            },
        },
        presets = {
            bottom_search = true,
            command_palette = true,
            long_message_to_split = true,
            inc_rename = true,
            lsp_doc_border = false,
        },
    },
    dependencies = {
        "MunifTanjim/nui.nvim",
        -- "rcarriga/nvim-notify",
    },
}
