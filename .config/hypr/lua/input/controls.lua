local settings = require("lua.core.settings")

local input = {
    kb_layout    = "us",
    kb_variant   = "",
    kb_model     = "",
    kb_options   = "",
    kb_rules     = "",
    follow_mouse = 1,
    sensitivity  = 0,
    touchpad     = {
        natural_scroll = false,
    },
}

if settings.touch_output then
    input.touchdevice = {
        output = settings.touch_output,
        transform = 2,
    }
end

hl.config({
    input = input,
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.gesture({ fingers = 3, direction = "swipe", action = "scroll_move" })
hl.gesture({ fingers = 3, direction = "swipe", mods = "ALT", action = "move" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
