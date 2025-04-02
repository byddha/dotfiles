local exception_bufnr
local current_session
local current_exception_filters = {}

local function splitCamel(s)
    local function split(char)
        return " " .. char
    end

    return (s:gsub("[A-Z]", split):gsub("^.", string.upper))
end

local function check_session_state()
    local dap = require "dap"
    local session = dap.session()
    if current_session ~= session then
        current_session = session
        return true
    end
    return false
end

local function generate_exception_breakpoints()
    local exc = {}
    if current_session then
        local filters = current_session.capabilities and current_session.capabilities.exceptionBreakpointFilters
        if filters then
            for _, filter in ipairs(filters) do
                local exceptionId = filter.filter
                local name = splitCamel(exceptionId) .. " Exceptions"
                table.insert(exc, { exceptionId = exceptionId, name = name, active = false })
            end
        end
    end
    current_exception_filters = exc
end

local ExceptionControl = {
    buffer = function(self)
        -- test
        while true do
            break
        end
        if not exception_bufnr or not vim.api.nvim_buf_is_valid(exception_bufnr) then
            exception_bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_name(exception_bufnr, "DAP Exception Controls")

            vim.keymap.set("n", "t", function()
                local line = vim.fn.line "."
                if line > 1 then
                    local index = line - 1
                    if current_exception_filters[index] then
                        current_exception_filters[index].active = not current_exception_filters[index].active
                    end
                    local active_filters = {}
                    for _, filter in ipairs(current_exception_filters) do
                        if filter.active then
                            table.insert(active_filters, filter.exceptionId)
                        end
                    end
                    require("dap").set_exception_breakpoints(active_filters)
                    self:render()
                end
            end, { buffer = exception_bufnr, noremap = true, silent = true })
        end
        return exception_bufnr
    end,
    render = function(self)
        local buf = self:buffer()
        if check_session_state() then
            local dap = require "dap"
            dap.set_exception_breakpoints {}
            generate_exception_breakpoints()
        end

        local lines = { "Exception Settings" }
        for _, filter in ipairs(current_exception_filters) do
            local active = filter.active and "X" or " "
            table.insert(lines, string.format("[%s] %s", active, filter.name))
        end

        local success, err = pcall(function()
            vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

            vim.api.nvim_buf_add_highlight(buf, -1, "DapUIExceptionSettingsTitle", 0, 0, -1)
            for i = 1, #current_exception_filters do
                local filter = current_exception_filters[i]
                local highlight_group = filter.active and "DapUIExceptionSettingsBreakpointActive"
                    or "DapUIExceptionSettingsBreakpointInactive"
                vim.api.nvim_buf_add_highlight(buf, -1, highlight_group, i, 0, -1)
            end
        end)

        if not success then
            print("Error rendering exception controls: " .. err)
        end
    end,
    float_defaults = function()
        return { enter = false }
    end,
}

local exception_controls_internal = setmetatable(ExceptionControl, {
    __index = ExceptionControl,
})

local exception_controls_element = {
    render = function()
        exception_controls_internal:render()
    end,
    buffer = function()
        return exception_controls_internal:buffer()
    end,
    float_defaults = function()
        return exception_controls_internal:float_defaults()
    end,
}

return {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    event = "VeryLazy",
    opts = {
        controls = {
            element = "console",
        },
        layouts = {
            {
                elements = {
                    {
                        id = "scopes",
                        size = 0.25,
                    },
                    {
                        id = "breakpoints",
                        size = 0.25,
                    },
                    {
                        id = "stacks",
                        size = 0.25,
                    },
                    {
                        id = "watches",
                        size = 0.13,
                    },
                    {
                        id = "exception_controls",
                        size = 0.12,
                    },
                },
                position = "left",
                size = 40,
            },
            {
                elements = {
                    {
                        id = "console",
                        size = 0.5,
                    },
                    {
                        id = "repl",
                        size = 0.5,
                    },
                },
                position = "bottom",
                size = 15,
            },
        },
    },
    keys = {
        {
            "<leader>du",
            function()
                require("dapui").toggle()
            end,
            desc = "Toggle dapui",
        },
        {
            "<leader>dk",
            function()
                require("dapui").eval(nil)
            end,
            { silent = true, desc = "Hover value" },
        },
    },
    config = function(_, opts)
        require("dapui").register_element("exception_controls", exception_controls_element)
        require("dapui").setup(opts)
        local dapui = require "dapui"
        local dap = require "dap"
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end
    end,
}
