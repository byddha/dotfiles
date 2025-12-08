return {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    event = "VeryLazy",
    config = function()
        local defaults = require "plugins.lsp.configs.defaults"

        local function default_config()
            return {
                on_attach = defaults.on_attach,
                on_init = defaults.on_init,
                capabilities = defaults.capabilities,
            }
        end

        local merge = require("helpers").merge

        local servers = {
            "html",
            "cssls",
            "ts_ls",
            "angularls",
            "basedpyright",
            "gdscript",
            "bashls",
            "ruff",
            "lua_ls",
            "qmlls",
            "gopls",
        }

        for _, lsp in ipairs(servers) do
            local ok, server_config = pcall(require, "plugins.lsp.configs." .. lsp)
            if ok then
                local config = merge(default_config(), server_config)
                vim.lsp.config(lsp, config)
                vim.lsp.enable(lsp)
            else
                vim.notify(lsp .. " configuration could not be loaded", vim.log.levels.ERROR)
            end
        end
    end,
}
