local dap = require "dap"

local mason_registry = require "mason-registry"
local vscode_js_debug = mason_registry.get_package "js-debug-adapter"
local js_dap_executable = vscode_js_debug:get_install_path() .. "/js-debug/src/dapDebugServer.js"
for _, adapter in ipairs { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" } do
    dap.adapters[adapter] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
            command = "node",
            args = { js_dap_executable, "${port}" },
        },
    }
end

dap.configurations.typescript = {
    {
        type = "pwa-chrome",
        request = "launch",
        name = "Launch & Debug Chrome",
        url = function()
            local co = coroutine.running()
            return coroutine.create(function()
                vim.ui.input({
                    prompt = "Enter URL: ",
                    default = "http://localhost:44309",
                }, function(url)
                    if url == nil or url == "" then
                        return
                    else
                        coroutine.resume(co, url)
                    end
                end)
            end)
        end,
        webRoot = vim.fn.getcwd(),
        protocol = "inspector",
        sourceMaps = true,
        userDataDir = false,
    },
}
