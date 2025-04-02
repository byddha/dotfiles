return {
    "seblj/roslyn.nvim",
    -- dir = "D:/Dev/roslyn.nvim",
    ft = "cs",
    opts = {
        config = {
            -- exe = {
            --     "dotnet",
            --     "D:/Dev/roslyn/artifacts/obj/Microsoft.CodeAnalysis.LanguageServer/Debug/net9.0/Microsoft.CodeAnalysis.LanguageServer.dll",
            -- },
            handlers = {
                ["textDocument/hover"] = function(err, result, ctx, config)
                    if result and result.contents and result.contents.value then
                        result.contents.value = result.contents.value:gsub("\\([^%w])", "%1")
                    end
                    vim.lsp.handlers["textDocument/hover"](err, result, ctx, config)
                end,
            },
            on_attach = require("plugins.lsp.configs.defaults").on_attach,
            settings = {
                ["csharp|inlay_hints"] = {
                    csharp_enable_inlay_hints_for_implicit_object_creation = true,
                    csharp_enable_inlay_hints_for_implicit_variable_types = true,
                    csharp_enable_inlay_hints_for_lambda_parameter_types = true,
                    csharp_enable_inlay_hints_for_types = true,
                    dotnet_enable_inlay_hints_for_indexer_parameters = true,
                    dotnet_enable_inlay_hints_for_literal_parameters = true,
                    dotnet_enable_inlay_hints_for_object_creation_parameters = true,
                    dotnet_enable_inlay_hints_for_other_parameters = true,
                    dotnet_enable_inlay_hints_for_parameters = true,
                    dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = false,
                    dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = false,
                    dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = false,
                },
                ["csharp|code_lens"] = { dotnet_enable_references_code_lens = true },
            },
        },
    },
}
