pragma Singleton

import QtQuick
import Quickshell
import "../../Config"

QtObject {
    id: root

    // Nerd Font unicode icon mappings

    // https://github.com/Jas-SinghFSU/HyprPanel/blob/f9a04192e8fb90a48e1756989f582dc0baec2351/src/components/bar/modules/window_title/helpers/appIcons.ts#L64
    readonly property var iconMap: ({
            // Misc
            "qbittorrent": ["", "qBittorrent"],
            "rofi": ["", "Rofi"],

            // Browsers
            "brave-browser": ["󰖟", "Brave"],
            "chromium": ["", "Chromium"],
            "firefox": ["󰈹", "Firefox"],
            "floorp": ["󰈹", "Floorp"],
            "google-chrome": ["", "Chrome"],
            "microsoft-edge": ["󰇩", "Edge"],
            "opera": ["", "Opera"],
            "thorium": ["󰖟", "Thorium"],
            "tor-browser": ["", "Tor Browser"],
            "vivaldi": ["󰖟", "Vivaldi"],
            "waterfox": ["󰖟", "Waterfox"],
            "zen": ["", "Zen Browser"],

            // Terminals
            "^st$": ["", "st"],
            "alacritty": ["", "Alacritty"],
            "com.mitchellh.ghostty": ["󰊠", "Ghostty"],
            "foot": ["󰽒", "Foot"],
            "gnome-terminal": ["", "Terminal"],
            "kitty": ["", "Kitty"],
            "konsole": ["", "Konsole"],
            "tilix": ["", "Tilix"],
            "urxvt": ["", "URxvt"],
            "wezterm": ["", "WezTerm"],
            "xterm": ["", "XTerm"],

            // Development Tools
            "dbeaver": ["", "DBeaver"],
            "android-studio": ["󰀴", "Android Studio"],
            "atom": ["", "Atom"],
            "code": ["󰨞", "VS Code"],
            "docker": ["", "Docker"],
            "eclipse": ["", "Eclipse"],
            "emacs": ["", "Emacs"],
            "godot": ["", "Godot"],
            "jetbrains-idea": ["", "IntelliJ IDEA"],
            "jetbrains-phpstorm": ["", "PhpStorm"],
            "jetbrains-pycharm": ["", "PyCharm"],
            "jetbrains-webstorm": ["", "WebStorm"],
            "neovide": ["", "Neovide"],
            "neovim": ["", "Neovim"],
            "netbeans": ["", "NetBeans"],
            "sublime-text": ["", "Sublime Text"],
            "vim": ["", "Vim"],
            "vscode": ["󰨞", "VS Code"],

            // Communication Tools
            "discord": ["", "Discord"],
            "legcord": ["", "Legcord"],
            "webcord": ["", "WebCord"],
            "org.telegram.desktop": ["", "Telegram"],
            "skype": ["󰒯", "Skype"],
            "slack": ["󰒱", "Slack"],
            "teams": ["󰊻", "Teams"],
            "teamspeak": ["", "TeamSpeak"],
            "telegram-desktop": ["", "Telegram"],
            "thunderbird": ["", "Thunderbird"],
            "vesktop": ["", "Vesktop"],
            "whatsapp": ["󰖣", "WhatsApp"],
            "outlook": ["󰴢", "Outlook"],

            // File Managers
            "doublecmd": ["󰝰", "Double Commander"],
            "krusader": ["󰝰", "Krusader"],
            "nautilus": ["󰝰", "Files"],
            "nemo": ["󰝰", "Nemo"],
            "org.kde.dolphin": ["", "Dolphin"],
            "pcmanfm": ["󰝰", "PCManFM"],
            "ranger": ["󰝰", "Ranger"],
            "thunar": ["󰝰", "Thunar"],
            "org.kde.ark": ["󰀼", "Ark"],

            // Media Players
            "mpv": ["󰿎", "mpv"],
            "plex": ["󰚺", "Plex"],
            "rhythmbox": ["󰓃", "Rhythmbox"],
            "ristretto": ["󰋩", "Ristretto"],
            "spotify": ["󰓇", "Spotify"],
            "com.mastermindzh.tidal-hifi": ["", "Tidal"],
            "tidal-hifi": ["", "Tidal"],
            "vlc": ["󰕼", "VLC"],
            "qimgv": ["", "qimgv"],
            "waydroid.app.komikku": ["", "Komikku"],

            // Graphics Tools
            "blender": ["󰂫", "Blender"],
            "gimp": ["", "GIMP"],
            "inkscape": ["", "Inkscape"],
            "krita": ["", "Krita"],

            // Video Editing
            "kdenlive": ["", "Kdenlive"],

            // Games and Gaming Platforms
            "csgo": ["󰺵", "CS:GO"],
            "dota2": ["󰺵", "Dota 2"],
            "heroic": ["󰺵", "Heroic"],
            "lutris": ["󰺵", "Lutris"],
            "minecraft": ["󰍳", "Minecraft"],
            "steam": ["", "Steam"],
            "com.github.mtkennerly.ludusavi": ["󰆔", "Ludasavi"],

            // Office and Productivity
            "evernote": ["", "Evernote"],
            "libreoffice-base": ["", "LibreOffice Base"],
            "libreoffice-calc": ["", "LibreOffice Calc"],
            "libreoffice-draw": ["", "LibreOffice Draw"],
            "libreoffice-impress": ["", "LibreOffice Impress"],
            "libreoffice-math": ["", "LibreOffice Math"],
            "libreoffice-writer": ["", "LibreOffice Writer"],
            "obsidian": ["󱓧", "Obsidian"],
            "sioyek": ["", "Sioyek"],
            // putting these at the bottom, as they are defaults
            "libreoffice": ["", "LibreOffice"],
            "title:LibreOffice": ["", "LibreOffice"],
            "soffice": ["", "LibreOffice"],

            // Utilities
            "balenaetcher": ["󱊞", "balenaEtcher"],
            "blueman-manager": ["", "Blueman"],
            "org.corectrl.corectrl": ["󰍛", "CoreCtrl"],
            "nwg-displays": ["󰍺", "nwg-displays"],
            "mullvad vpn": ["󰖂", "Mullvad VPN"],
            "org.remmina.remmina": ["󰢹", "Remmina"],
            "virt-manager": ["󰢔", "Virt Manager"],
            "io.missioncenter.missioncenter": ["", "Mission Center"],
            "swappy": ["", "Swappy"],
            "kvantummanager": ["󰔎", "Kvantum"],
            "nwg-look": ["", "GTK Theme"],

            // Cloud Services and Sync
            "dropbox": ["󰇣", "Dropbox"],

            // Fallback
            "unknown": ["", "Unknown"]
        })

    // Keys are tried as exact class, then as substrings of the class, then of the title, in declaration order.
    // "^name$" keys are exact-only, for names too short to use as substrings.
    function findEntry(className, title) {
        if (className && className.length > 0) {
            const lowerClass = className.toLowerCase();
            const exact = iconMap[lowerClass] || iconMap["^" + lowerClass + "$"];
            if (exact)
                return exact;
            for (const key in iconMap) {
                if (lowerClass.includes(key))
                    return iconMap[key];
            }
        }
        if (title && title.length > 0) {
            const lowerTitle = title.toLowerCase();
            for (const key in iconMap) {
                if (lowerTitle.includes(key))
                    return iconMap[key];
            }
        }
        return iconMap["unknown"];
    }

    function lookup(className, title, xdgTag) {
        const entry = xdgTag === "proton-game" ? ["󰊗", "Game"] : findEntry(className, title);
        return {
            icon: entry[0],
            name: entry[1]
        };
    }

    // The app's icon file from its .desktop entry, "" when it has none. Proton games use the icon Steam installs.
    function iconSourceFor(className) {
        const steamApp = /^steam_app_(\d+)$/.exec(className ?? "");
        if (steamApp)
            return Quickshell.iconPath(`steam_icon_${steamApp[1]}`, true);
        // Entries load after startup: reading the list makes a binding that calls this update then
        if (!className || DesktopEntries.applications.values.length === 0)
            return "";
        return iconForEntry(DesktopEntries.byId(className) || DesktopEntries.heuristicLookup(className));
    }

    // The icon to show for an app's desktop entry: the config's override, else the entry's themed icon
    function iconForEntry(entry) {
        if (!entry)
            return "";
        return overrideFor(entry.id) || (entry.icon ? Quickshell.iconPath(entry.icon, true) : "");
    }

    // The config's iconOverrides icon for a desktop entry id, "" when it has none
    function overrideFor(entryId) {
        const override = Config.options.iconOverrides[entryId];
        if (!override)
            return "";
        return override.startsWith("/") ? `file://${override}` : Quickshell.iconPath(override, true);
    }

    function getIcon(className, title, xdgTag) {
        return lookup(className, title, xdgTag).icon;
    }

    function getDisplayName(className, title, xdgTag) {
        return lookup(className, title, xdgTag).name;
    }
}
