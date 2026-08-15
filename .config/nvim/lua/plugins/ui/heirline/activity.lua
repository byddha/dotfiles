local M = {}

-- a task that begins and ends in an instant would only ever be a flicker, so
-- its last state is held on screen briefly after it reports done
local DECAY = 700
local THROTTLE = 50

local tasks = {}
local seq, queued = 0, false

local group = vim.api.nvim_create_augroup("HeirlineActivity", { clear = true })

local function redraw()
    if queued then
        return
    end
    queued = true
    vim.defer_fn(function()
        queued = false
        vim.cmd "redrawstatus"
    end, THROTTLE)
end

-- JSON nulls arrive as vim.NIL, which is neither nil nor a string
local function str(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    return value
end

-- servers may send anything under this event; roslyn sends notifications with
-- neither `token` nor `value`, which would otherwise be indexed blindly
vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(args)
        local params = args.data and args.data.params
        if type(params) ~= "table" or params.token == nil or type(params.value) ~= "table" then
            return
        end

        local value = params.value
        local key = args.data.client_id .. "/" .. tostring(params.token)
        local task = tasks[key]

        if value.kind == "end" then
            if not task then
                return
            end
            task.done = true
            vim.defer_fn(function()
                if tasks[key] and tasks[key].done then
                    tasks[key] = nil
                    redraw()
                end
            end, DECAY)
        elseif value.kind == "begin" or value.kind == "report" then
            seq = seq + 1
            tasks[key] = {
                client = args.data.client_id,
                seq = seq,
                title = str(value.title) or (task and task.title),
                message = str(value.message),
                percentage = tonumber(value.percentage),
            }
        else
            return
        end

        redraw()
    end,
})

vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "DapProgressUpdate",
    callback = redraw,
})

-- the newest task wins and the rest are only counted, so the zone never grows
-- with the number of servers
function M.lsp()
    local newest, count = nil, 0

    for key, task in pairs(tasks) do
        if not vim.lsp.get_client_by_id(task.client) then
            tasks[key] = nil
        else
            count = count + 1
            if not newest or task.seq > newest.seq then
                newest = task
            end
        end
    end

    if not newest then
        return nil
    end

    local parts = {}
    if newest.title then
        parts[#parts + 1] = newest.title
    end
    if newest.message and newest.message ~= newest.title then
        parts[#parts + 1] = newest.message
    end
    if newest.percentage then
        parts[#parts + 1] = string.format("%d%%", newest.percentage)
    end

    local text = #parts > 0 and table.concat(parts, " ") or "working"
    if count > 1 then
        text = text .. " +" .. (count - 1)
    end
    return text
end

return M
