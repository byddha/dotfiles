local dap = require "dap"
dap.adapters.codelldb = {
    type = "server",
    host = "127.0.0.1",
    port = 13000,
    executable = {
        command = vim.fn.stdpath "data" .. "/mason/packages/codelldb/extension/adapter/codelldb",
        args = { "--port", "13000" },

        -- on windows you may have to uncomment this:
        -- detached = false,
    },
}
