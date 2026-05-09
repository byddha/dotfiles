local M = {}

function M.read_line(path, empty_message)
    local file = assert(io.open(path, "r"), "failed to open " .. path)
    local line = file:read("*l")
    file:close()

    return assert(line and line ~= "" and line, empty_message or path .. " was empty")
end

return M
