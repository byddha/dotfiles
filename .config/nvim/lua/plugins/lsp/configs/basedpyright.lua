local util = require "lspconfig/util"
return {
    root_dir = function(fname)
        return util.root_pattern("pyproject.toml", "pyrightconfig.json", ".git")(fname) or vim.fn.getcwd()
    end,
    on_attach = function(client, _)
        client.server_capabilities.codeActionProvider = false
    end,
    settings = {
        basedpyright = {
            analysis = {
                diagnosticSeverityOverrides = {
                    reportAny = false,
                },
            },
        },
    },
}
