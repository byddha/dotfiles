local util = require "lspconfig/util"
local mason_root = vim.fn.expand "$MASON"
local angularls_path = mason_root .. "/packages/angular-language-server"
local cmd = {
    "ngserver",
    "--stdio",
    "--tsProbeLocations",
    table.concat({
        angularls_path,
        vim.uv.cwd(),
    }, ","),
    "--ngProbeLocations",
    table.concat({
        angularls_path .. "/node_modules/@angular/language-server",
        vim.uv.cwd(),
    }, ","),
}

return {
    cmd = cmd,
    on_new_config = function(new_config, _)
        new_config.cmd = cmd
    end,
    root_dir = function(fname)
        return util.root_pattern "angular.json"(fname)
    end,
}
