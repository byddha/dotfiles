local ok, mason_registry = pcall(require, "mason-registry")
if not ok then
    vim.notify("Could not load mason registry for angularls", vim.log.levels.ERROR)
    return nil
end

local util = require "lspconfig/util"
local angularls_path = mason_registry.get_package("angular-language-server"):get_install_path()
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
