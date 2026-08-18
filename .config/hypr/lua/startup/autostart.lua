local settings = require("lua.core.settings")
local launch = settings.programs.launch

-- Chromium probes org.freedesktop.Notifications once, early in startup, and never
-- retries; if it wins the race against quickshell it renders every notification in
-- its own in-window popup for the rest of the session.
local function after_notification_daemon(command)
    return "gdbus wait --session --timeout 60 org.freedesktop.Notifications; " .. command
end

local commands = {
    "hypridle",
    "systemctl --user start hyprpolkitagent",
    "qs -d",
    "wl-paste --watch cliphist store",
    "hyprpm reload -n",
    "elephant",
    "walker --gapplication-service",
    "waydroid session start",
    "kbuildsycoca6",
    "bash -c 'for i in $(seq 1 20); do bloqlight set 255,255,255 && break; sleep 0.5; done'",
    launch .. ' -ic "vesktop" dev.vencord.Vesktop',
    after_notification_daemon("gio launch ~/.local/share/applications/webapp-whatsapp.desktop"),
    after_notification_daemon("gio launch ~/.local/share/applications/webapp-teams.desktop"),
}

hl.on("hyprland.start", function()
    for _, command in ipairs(commands) do
        hl.exec_cmd(command)
    end
end)
