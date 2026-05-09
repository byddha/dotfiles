local settings = require("lua.core.settings")

local fallback = {
    active_border   = "rgba(7fbbb3bb)",
    inactive_border = "rgba(859289aa)",
    shadow          = "rgba(272e33ee)",
}

local ok, theme = pcall(dofile, settings.home .. "/.cache/theme/hypr-colors.lua")
if ok and type(theme) == "table" then
    return theme
end

return fallback
