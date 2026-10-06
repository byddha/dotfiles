-- Read only when Hyprland starts: changes here need a logout.
-- Everything not allowed below asks (screencopy, cursorpos, input-capture and plugin default to ask).
hl.config({ ecosystem = { enforce_permissions = true } })

-- A lock screen that crashes leaves the session locked, with nothing to type into: a new lock may
-- take over (quickshell/scripts/lock starts it again) instead of a dead screen until a TTY login
hl.config({ misc = { allow_session_lock_restore = true } })

local allow = {
    -- Screen share (Discord, Zen, OBS) goes through the portal
    { "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy" },
    -- Region selector and the workspace map previews
    { "/usr/bin/quickshell", "screencopy" },
    { "/usr/bin/quickshell", "cursorpos" },
    -- Reads a single pixel colour, cannot leak the screen
    { "/usr/bin/hyprpicker", "screencopy" },

    -- Keyboards by device name, wired and wireless (names seen on 2026-10-04)
    { ".*[Ff]low2@[Ll]ofree.*", "keyboard" },
    { ".*[Bb]asilisk[- ][Mm]obile.*", "keyboard" },
    -- Audio-Technica AT2040USB microphone: its mute and volume buttons are a keyboard
    { ".*[Aa][Tt]2040[Uu][Ss][Bb].*", "keyboard" },
    { "[Pp]ower[- ][Bb]utton.*", "keyboard" },
    { "[Vv]ideo[- ][Bb]us", "keyboard" },
    -- vicinae Tab binds and whisper paste type through wtype (whisper stays cross-compositor)
    { "hl-virtual-keyboard-wtype", "keyboard" },
}

for _, rule in ipairs(allow) do
    hl.permission({ binary = rule[1], type = rule[2], mode = "allow" })
end

-- Keyboards default to allow; this must stay the last keyboard rule. ydotoold asks on purpose,
-- so it only types after a yes for that run.
hl.permission({ binary = ".*", type = "keyboard", mode = "ask" })
