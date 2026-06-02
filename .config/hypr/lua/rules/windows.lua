local rules = {
    {
        name           = "suppress-maximize-events",
        match          = { class = ".*" },
        suppress_event = "maximize",
    },
    {
        name = "fix-xwayland-drags",
        match = {
            class      = "^$",
            title      = "^$",
            xwayland   = true,
            float      = true,
            fullscreen = false,
            pin        = false,
        },
        no_focus = true,
    },
    {
        name       = "satty-fullscreen",
        match      = { class = "com.gabm.satty" },
        fullscreen = true,
        no_anim    = true,
    },
    {
        name   = "xdg-desktop-portal-gtk-dialog",
        match  = { class = "^(Xdg-desktop-portal-gtk)$" },
        float  = true,
        center = true,
    },
    {
        name  = "godot-tiled",
        match = { class = "^(Godot)$", initial_class = "^(Godot)$", initial_title = "^(Godot)$" },
        tile  = true,
    },
    {
        name   = "kitty-file-picker-files",
        match  = { class = "^(kitty)$", title = "^(Select Files:)$", initial_title = "^(Select Files:)$" },
        float  = true,
        center = true,
        size   = { 1300, 800 },
    },
    {
        name   = "kitty-file-picker-directory",
        match  = { class = "^(kitty)$", title = "^(Select Directory:)$", initial_title = "^(Select Directory:)$" },
        float  = true,
        center = true,
        size   = { 1300, 800 },
    },
    {
        name   = "kitty-file-picker-save",
        match  = { class = "^(kitty)$", title = "^(Save File:)$", initial_title = "^(Save File:)$" },
        float  = true,
        center = true,
        size   = { 1300, 800 },
    },
    {
        name   = "kitty-yazi-floating",
        match  = { class = "^(kitty)$", title = "^(Yazi)$", initial_title = "^(Yazi)$" },
        float  = true,
        center = true,
        size   = { 1300, 800 },
    },
    {
        name       = "steam-games-cursorlock",
        match      = { class = "(steam_app)(.*)" },
        fullscreen = true,
        tag        = "+cursorlock",
    },
    { match = { class = "^(steam_app).*" },                                     idle_inhibit = "focus" },
    { match = { class = "^(gamescope).*" },                                     idle_inhibit = "focus" },
    { match = { class = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*" }, idle_inhibit = "focus" },
    { match = { title = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*" }, idle_inhibit = "fullscreen" },
    { match = { class = "^(zen|Firefox)$" },                                    idle_inhibit = "fullscreen" },
    { match = { title = ".*(YouTube|Twitch|Netflix).*" },                       idle_inhibit = "focus" },
    { match = { class = "^(mpv|vlc|.+exe)$" },                                  idle_inhibit = "focus" },
    {
        name        = "smart-gaps-one-tiled",
        match       = { float = false, workspace = "w[tv1]" },
        border_size = 0,
    },
    {
        name        = "smart-gaps-one-fullscreen",
        match       = { float = false, workspace = "f[1]" },
        border_size = 0,
    },
    -- {
    --     name            = "zen-scrolling-width",
    --     match           = { initial_class = "^(zen)$" },
    --     scrolling_width = 1,
    -- },
    {
        name      = "special-chatapps",
        match     = {
            class = "^(vesktop|chrome-web\\.whatsapp\\.com__-Default|chrome-teams\\.cloud\\.microsoft__-Default)$",
        },
        workspace = "special:chatapps silent",
    },
    {
        name      = "special-chatapps-chromium-xwayland",
        match     = {
            class         = "^Chromium$",
            initial_title = "^(web\\.whatsapp\\.com_/|teams\\.cloud\\.microsoft_/)$",
        },
        workspace = "special:chatapps silent",
        float     = false
    },
    {
        name      = "special-gaming",
        match     = { class = "^(steam_app).*" },
        workspace = "special:gaming silent",
    },
    {
        name      = "special-gaming-gamescope",
        match     = { class = "^(gamescope).*" },
        workspace = "special:gaming silent",
    },
}

for _, rule in ipairs(rules) do
    hl.window_rule(rule)
end
