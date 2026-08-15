local M = {}

M.bg = { "StatusLineBg1", "StatusLineBg2", "StatusLineBg3" }

M.cap = {
    arrow_left = "",
    arrow_right = "",
    round_left = "",
    round_right = "",
    slope_left = "",
    slope_right = "",
}

M.Align = { provider = "%=" }

-- heirline re-parses whatever a provider returns as a statusline format, so
-- anything taken from a branch name, path or server name needs its `%` escaped.
function M.literal(s)
    return (tostring(s):gsub("%%", "%%%%"))
end

local Sep = { provider = "  " }
local Pad = { provider = " " }
local BASE = #M.bg

local cache = {}

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("HeirlineBar", { clear = true }),
    callback = function()
        cache = {}
    end,
})

-- A cap is the zone's own background drawn as foreground over its neighbour's,
-- so the glyph reads as one zone bleeding into the next.
local function cap_hl(zone, against)
    local key = zone .. against
    if not cache[key] then
        cache[key] = {
            fg = vim.api.nvim_get_hl(0, { name = zone, link = false }).bg,
            bg = vim.api.nvim_get_hl(0, { name = against, link = false }).bg,
        }
    end
    return cache[key]
end

-- Walks outwards until it finds what a cap will actually sit against: the first
-- entry in that direction that renders, or the base background.
local function neighbour(spec, from, step)
    for i = from, step > 0 and #spec or 1, step do
        local entry = spec[i]
        local component = entry[1]
        if not component then
            return M.bg[BASE]
        elseif not component.condition or component.condition() then
            return M.bg[entry.bg or BASE]
        end
    end
    return M.bg[BASE]
end

-- Each entry is `{ Component, bg = n, cap_left = glyph, cap_right = glyph }`,
-- everything but the component optional; anything without a component passes
-- through untouched.
function M.bar(spec)
    local bar = { condition = spec.condition }

    for i, entry in ipairs(spec) do
        local component = entry[1]

        if not component then
            bar[#bar + 1] = entry
        elseif not entry.bg then
            bar[#bar + 1] = { condition = component.condition, Sep, component }
        else
            local zone = { condition = component.condition, hl = M.bg[entry.bg], Pad, component, Pad }

            if entry.cap_left then
                table.insert(zone, 1, {
                    provider = entry.cap_left,
                    hl = function()
                        return cap_hl(M.bg[entry.bg], neighbour(spec, i - 1, -1))
                    end,
                })
            end

            if entry.cap_right then
                zone[#zone + 1] = {
                    provider = entry.cap_right,
                    hl = function()
                        return cap_hl(M.bg[entry.bg], neighbour(spec, i + 1, 1))
                    end,
                }
            end

            bar[#bar + 1] = zone
        end
    end

    return bar
end

return M
