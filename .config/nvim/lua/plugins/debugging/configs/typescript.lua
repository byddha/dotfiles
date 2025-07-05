local dap = require "dap"

local mason_root = vim.fn.expand "$MASON"
local js_dbg_pkg = mason_root .. "/packages/js-debug-adapter"
local js_dap_executable = js_dbg_pkg .. "/js-debug/src/dapDebugServer.js"

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
