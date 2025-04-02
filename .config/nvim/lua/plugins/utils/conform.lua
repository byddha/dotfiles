return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            css = { "prettier" },
            html = { "prettier" },
            typescript = { "eslint" },
            python = {},
            cs = { "csharpier" },
        },

        format_on_save = {
            timeout_ms = 2000,
            lsp_fallback = true,
        },

        formatters = {
            csharpier = {
                command = "dotnet-csharpier",
                args = { "--write-stdout" },
            },
        },
    },
}
