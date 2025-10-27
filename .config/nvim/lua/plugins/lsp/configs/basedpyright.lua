return {
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
