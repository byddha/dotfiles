local dap = require "dap"
local is_windows = require("helpers").is_windows

local debugpy_python = vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/pythonw"

if is_windows() then
    debugpy_python = vim.fn.stdpath "data" .. "\\mason\\packages\\debugpy\\venv\\Scripts\\pythonw"
end

local resolve_python = function()
    local pythonLocation = "/bin/python"
    if is_windows() then
        pythonLocation = "\\Scripts\\python"
    end
    local pythonFolder = nil

    if require("venv-selector").venv() then
        pythonFolder = require("venv-selector").venv()
    elseif os.getenv "VIRTUAL_ENV" then
        pythonFolder = os.getenv "VIRTUAL_ENV"
    end

    if pythonFolder then
        return pythonFolder .. pythonLocation
    end

    return debugpy_python
end

local enrich_config = function(config, on_config)
    if not config.pythonPath and not config.python then
        config.pythonPath = resolve_python()
    end
    on_config(config)
end

dap.adapters.python = function(cb, config)
    if config.request == "attach" then
        ---@diagnostic disable-next-line: undefined-field
        local port = (config.connect or config).port
        ---@diagnostic disable-next-line: undefined-field
        local host = (config.connect or config).host or "127.0.0.1"
        cb {
            type = "server",
            port = assert(port, "`connect.port` is required for a python `attach` configuration"),
            host = host,
            enrich_config = enrich_config,
            options = {
                source_filetype = "python",
            },
        }
    else
        cb {
            type = "executable",
            command = debugpy_python,
            args = { "-m", "debugpy.adapter" },
            enrich_config = enrich_config,
            options = {
                source_filetype = "python",
            },
        }
    end
end
dap.adapters.debugpy = dap.adapters.python

dap.configurations.python = {
    {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        console = "integratedTerminal",
    },
    {
        type = "python",
        request = "launch",
        name = "Launch file with arguments",
        program = "${file}",
        args = function()
            local args_string = vim.fn.input "Arguments: "
            return vim.split(args_string, " +")
        end,
        console = "integratedTerminal",
    },
    {
        type = "python",
        request = "attach",
        name = "Attach to process",
        connect = function()
            local host = vim.fn.input "Host [127.0.0.1]: "
            host = host ~= "" and host or "127.0.0.1"
            local port = tonumber(vim.fn.input "Port: [5678]") or 5678
            return { host = host, port = port }
        end,
    },
}
