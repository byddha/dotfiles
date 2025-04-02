local M = {}

function M.merge(a, b)
    if type(a) == "table" and type(b) == "table" then
        for k, v in pairs(b) do
            if type(v) == "table" and type(a[k] or false) == "table" then
                M.merge(a[k], v)
            else
                a[k] = v
            end
        end
    end
    return a
end

function M.is_windows()
    return vim.fn.has "win32" == 1
end

---@param fn fun()
function M.on_very_lazy(fn)
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
            fn()
        end,
    })
end

---@param name string
function M.opts(name)
    local plugin = M.get_plugin(name)
    if not plugin then
        return {}
    end
    local Plugin = require "lazy.core.plugin"
    return Plugin.values(plugin, "opts", false)
end

---@param name string
function M.get_plugin(name)
    return require("lazy.core.config").spec.plugins[name]
end

return M
