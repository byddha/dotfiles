local M = {}

local handlers = {}

_G.cmd = _G.cmd or {}

local function split(line)
    local parts = {}

    for part in line:gmatch("%S+") do
        table.insert(parts, part)
    end

    return parts
end

local function copy(tbl)
    local result = {}

    for key, value in pairs(tbl) do
        result[key] = value
    end

    return result
end

local function register(name, handler)
    handlers[name] = handler
end

function cmd.run(line)
    local parts = split(line)
    local namespace = table.remove(parts, 1)
    local command = table.remove(parts, 1)

    if not namespace or not command then
        error("usage: <namespace> <command> ...")
    end

    local name = namespace .. "." .. command
    local handler = handlers[name]

    if not handler then
        error("unknown command: " .. tostring(name))
    end

    return handler(parts)
end

function M.monitor(profile)
    local function find(output)
        for _, monitor in ipairs(profile.monitors) do
            if monitor.output == output then
                return monitor
            end
        end

        local matched

        for _, monitor in ipairs(profile.monitors) do
            if monitor.supports_hdr ~= -1 and monitor.bitdepth == 10 then
                if matched then
                    error("ambiguous monitor profile for runtime output: " .. tostring(output))
                end

                matched = monitor
            end
        end

        if matched then
            return matched
        end

        error("unknown monitor: " .. tostring(output))
    end

    local function supports_cm(monitor, cm)
        if cm ~= "hdr" then
            return true
        end

        return monitor.supports_hdr ~= -1 and monitor.bitdepth == 10
    end

    register("monitor.cm", function(args)
        local output = args[1]
        local cm = args[2]

        if not output or not cm then
            error("usage: monitor cm <output> <cm>")
        end

        local base = find(output)

        if not supports_cm(base, cm) then
            error("monitor does not support cm=" .. cm .. ": " .. tostring(base.output))
        end

        local monitor = copy(base)
        monitor.output = output
        monitor.cm = cm

        hl.monitor(monitor)
    end)
end

return M
