local settings = require("lua.core.settings")
local helpers = require("lua.binds.helpers")
local programs = settings.programs

hl.config({
    binds = {
        hide_special_on_workspace_change = true,
        scroll_event_delay = 50,
    },
})

local bind      = helpers.bind
local exec      = helpers.exec

local app_binds = {
    { "<D-F8>",     exec("hyprctl dispatch cursorlock:toggle") },
    { "<D-x>",      hl.dsp.window.close(),                             "Kill active window" },
    { "<D-S-f>",    hl.dsp.window.fullscreen({ mode = "maximized" }),  "Maximize" },
    { "<D-C-f>",    hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Fullscreen" },
    { "<D-f>",      exec("nc -U /run/user/1000/walker/walker.sock"),   "Launcher" },
    { "<D-g>",      exec("qs ipc call games toggle"),                  "Games" },
    { "<D-1>",      hl.dsp.workspace.toggle_special("chatapps") },
    { "<D-2>",      hl.dsp.workspace.toggle_special("gaming") },
    { "<D-z>",      exec("qs ipc call screenshot region"),             "Screenshot" },
    { "<D-Return>", exec(programs.terminal),                           "Launch terminal" },
}


local focus_binds     = {
    -- { "<D-h>",           hl.dsp.layout("focus l"),            "Move focus left" },
    -- { "<D-l>",           hl.dsp.layout("focus r"),            "Move focus right" },
    { "<D-h>",           hl.dsp.focus({ direction = "l" }),  "Move focus up" },
    { "<D-l>",           hl.dsp.focus({ direction = "r" }),  "Move focus down" },
    { "<D-k>",           hl.dsp.focus({ direction = "u" }),  "Move focus up" },
    { "<D-j>",           hl.dsp.focus({ direction = "d" }),  "Move focus down" },
    { "<D-mouse_up>",    hl.dsp.layout("focus l") },
    { "<D-mouse_down>",  hl.dsp.layout("focus r") },
    { "<D-mouse_left>",  hl.dsp.focus({ workspace = "e-1" }) },
    { "<D-mouse_right>", hl.dsp.focus({ workspace = "e+1" }) },
}

local resize          = hl.dsp.window.resize
local resize_binds    = {
    { "<D-C-h>", resize({ x = -20, y = 0, relative = true }), "Decrease window width",  { repeating = true }, },
    { "<D-C-l>", resize({ x = 20, y = 0, relative = true }),  "Increase window width",  { repeating = true }, },
    { "<D-C-k>", resize({ x = 0, y = -20, relative = true }), "Decrease window height", { repeating = true }, },
    { "<D-C-j>", resize({ x = 0, y = 20, relative = true }),  "Increase window height", { repeating = true }, },
}

local move            = hl.dsp.window.move
local move_binds      = {
    { "<D-S-h>", move({ direction = "l" }), "Move window left" },
    { "<D-S-l>", move({ direction = "r" }), "Move window right" },
    { "<D-S-k>", move({ direction = "u" }), "Move window up" },
    { "<D-S-j>", move({ direction = "d" }), "Move window down" },
}

local swap            = hl.dsp.window.swap
local swap_binds      = {
    { "<D-A-h>",           swap({ direction = "l" }), "Swap window left" },
    { "<D-A-mouse_left>",  swap({ direction = "l" }) },
    { "<D-A-l>",           swap({ direction = "r" }), "Swap window right" },
    { "<D-A-mouse_right>", swap({ direction = "r" }) },
    { "<D-A-k>",           swap({ direction = "u" }), "Swap window up" },
    { "<D-A-mouse_down>",  swap({ direction = "u" }) },
    { "<D-A-j>",           swap({ direction = "d" }), "Swap window down" },
    { "<D-A-mouse_up>",    swap({ direction = "d" }) },
}

local workspace_keys  = {
    q = 1,
    w = 2,
    e = 3,
    r = 4,
    t = 5,
    a = 6,
    s = 7,
    d = 8,
}

local workspace_binds = {}

for key, workspace in pairs(workspace_keys) do
    table.insert(workspace_binds, { "<D-" .. key .. ">", hl.dsp.focus({ workspace = workspace }) })
    table.insert(workspace_binds, { "<D-S-" .. key .. ">", hl.dsp.window.move({ workspace = workspace }) })
end

local layout_binds = {
    { "<D-bracketleft>",  hl.dsp.layout("consume_or_expel prev"), "Consume or expel prev" },
    { "<D-bracketright>", hl.dsp.layout("consume_or_expel next"), "Consume or expel next" },
    { "<D-comma>",        hl.dsp.layout("consume"),               "Consume" },
    { "<D-period>",       hl.dsp.layout("expel"),                 "Expel" },
    { "<D-S-g>",          hl.dsp.layout("colresize +conf"),       "Cycle column width" },
}

local workspace_navigation_binds = {
    { "<D-semicolon>", hl.dsp.focus({ workspace = "previous" }), "Back" },
}

local mouse_binds = {
    { "<D-mouse:274>", hl.dsp.window.drag(),   nil, { mouse = true } },
    { "<D-mouse:273>", hl.dsp.window.resize(), nil, { mouse = true } },
}

local utility_binds = {
    { "<D-A-SPACE>", exec(settings.script("whisperT.sh")), "Transcribe speech" },
    { "<D-SPACE>",   exec("qs ipc call sidebar toggle"),   "Open sidebar" },
}

local locked_repeating = { locked = true, repeating = true }

local hardware_binds = {
    { "XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), nil, locked_repeating },
    { "XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      nil, locked_repeating },
    { "XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     nil, locked_repeating },
    { "XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   nil, locked_repeating },
    { "XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+"),                  nil, locked_repeating },
    { "XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-"),                  nil, locked_repeating },
    { "Print",                 hl.dsp.submap("screenshot") },
}

local submap_binds = {
    { "<D-TAB>", hl.dsp.submap("apps"),        "+apps" },
    { "<D-m>",   hl.dsp.submap("window-mode"), "+window-mode" },
    { "<D-u>",   hl.dsp.submap("toggles"),     "+toggles" },
}

local bind_groups = {
    app_binds,
    focus_binds,
    resize_binds,
    move_binds,
    swap_binds,
    layout_binds,
    workspace_binds,
    workspace_navigation_binds,
    mouse_binds,
    utility_binds,
    hardware_binds,
    submap_binds,
}

for _, group in ipairs(bind_groups) do
    for _, spec in ipairs(group) do
        bind(spec)
    end
end
