local M = {}

local modifiers = {
    C = "CONTROL",
    A = "ALT",
    M = "ALT",
    S = "SHIFT",
    D = "SUPER",
}

local function parse_keys(keys)
    local body = keys:match("^<(.+)>$")
    if not body then
        return keys
    end

    local parsed = {}
    local key

    for part in body:gmatch("[^-]+") do
        local modifier = modifiers[part]

        if modifier then
            table.insert(parsed, modifier)
        elseif not key then
            key = part
        else
            error("multiple keys in bind: " .. keys)
        end
    end

    assert(key, "missing key in bind: " .. keys)
    table.insert(parsed, key)

    return table.concat(parsed, " + ")
end

function M.bind(keys, dispatcher, description, flags)
    if type(keys) == "table" then
        return M.bind(keys[1], keys[2], keys[3], keys[4])
    end

    flags = flags or {}
    if description then
        flags.description = description
    end
    hl.bind(parse_keys(keys), dispatcher, flags)
end

function M.reset_submap()
    hl.dispatch(hl.dsp.submap("reset"))
end

function M.dispatch_and_reset(dispatcher)
    return function()
        hl.dispatch(dispatcher)
        M.reset_submap()
    end
end

function M.exec(command)
    return hl.dsp.exec_cmd(command)
end

function M.exec_and_reset(command)
    return M.dispatch_and_reset(M.exec(command))
end

return M
