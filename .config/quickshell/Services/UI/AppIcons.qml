pragma Singleton

import QtQuick
import "../../Utils/"

QtObject {
    id: root

    // Nerd Font unicode icon mappings

    // https://github.com/Jas-SinghFSU/HyprPanel/blob/f9a04192e8fb90a48e1756989f582dc0baec2351/src/components/bar/modules/window_title/helpers/appIcons.ts#L64
    readonly property var iconMap: ({
            // Misc
            "qbittorrent": {
                icon: "",
                name: "qBittorrent"
            },
            "rofi": {
                icon: "",
                name: "Rofi"
            },

            // Browsers
            "brave-browser": {
                icon: "󰖟",
                name: "Brave"
            },
            "chromium": {
                icon: "",
                name: "Chromium"
            },
            "firefox": {
                icon: "󰈹",
                name: "Firefox"
            },
            "floorp": {
                icon: "󰈹",
                name: "Floorp"
            },
            "google-chrome": {
                icon: "",
                name: "Chrome"
            },
            "microsoft-edge": {
                icon: "󰇩",
                name: "Edge"
            },
            "opera": {
                icon: "",
                name: "Opera"
            },
            "thorium": {
                icon: "󰖟",
                name: "Thorium"
            },
            "tor-browser": {
                icon: "",
                name: "Tor Browser"
            },
            "vivaldi": {
                icon: "󰖟",
                name: "Vivaldi"
            },
            "waterfox": {
                icon: "󰖟",
                name: "Waterfox"
            },
            "zen": {
                icon: "",
                name: "Zen Browser"
            },

            // Terminals
            "^st$": {
                icon: "",
                name: "st"
            },
            "alacritty": {
                icon: "",
                name: "Alacritty"
            },
            "com.mitchellh.ghostty": {
                icon: "󰊠",
                name: "Ghostty"
            },
            "foot": {
                icon: "󰽒",
                name: "Foot"
            },
            "gnome-terminal": {
                icon: "",
                name: "Terminal"
            },
            "kitty": {
                icon: "",
                name: "Kitty"
            },
            "konsole": {
                icon: "",
                name: "Konsole"
            },
            "tilix": {
                icon: "",
                name: "Tilix"
            },
            "urxvt": {
                icon: "",
                name: "URxvt"
            },
            "wezterm": {
                icon: "",
                name: "WezTerm"
            },
            "xterm": {
                icon: "",
                name: "XTerm"
            },

            // Development Tools
            "dbeaver": {
                icon: "",
                name: "DBeaver"
            },
            "android-studio": {
                icon: "󰀴",
                name: "Android Studio"
            },
            "atom": {
                icon: "",
                name: "Atom"
            },
            "code": {
                icon: "󰨞",
                name: "VS Code"
            },
            "docker": {
                icon: "",
                name: "Docker"
            },
            "eclipse": {
                icon: "",
                name: "Eclipse"
            },
            "emacs": {
                icon: "",
                name: "Emacs"
            },
            "godot": {
                icon: "",
                name: "Godot"
            },
            "jetbrains-idea": {
                icon: "",
                name: "IntelliJ IDEA"
            },
            "jetbrains-phpstorm": {
                icon: "",
                name: "PhpStorm"
            },
            "jetbrains-pycharm": {
                icon: "",
                name: "PyCharm"
            },
            "jetbrains-webstorm": {
                icon: "",
                name: "WebStorm"
            },
            "neovide": {
                icon: "",
                name: "Neovide"
            },
            "neovim": {
                icon: "",
                name: "Neovim"
            },
            "netbeans": {
                icon: "",
                name: "NetBeans"
            },
            "sublime-text": {
                icon: "",
                name: "Sublime Text"
            },
            "vim": {
                icon: "",
                name: "Vim"
            },
            "vscode": {
                icon: "󰨞",
                name: "VS Code"
            },

            // Communication Tools
            "discord": {
                icon: "",
                name: "Discord"
            },
            "legcord": {
                icon: "",
                name: "Legcord"
            },
            "webcord": {
                icon: "",
                name: "WebCord"
            },
            "org.telegram.desktop": {
                icon: "",
                name: "Telegram"
            },
            "skype": {
                icon: "󰒯",
                name: "Skype"
            },
            "slack": {
                icon: "󰒱",
                name: "Slack"
            },
            "teams": {
                icon: "󰊻",
                name: "Teams"
            },
            "teamspeak": {
                icon: "",
                name: "TeamSpeak"
            },
            "telegram-desktop": {
                icon: "",
                name: "Telegram"
            },
            "thunderbird": {
                icon: "",
                name: "Thunderbird"
            },
            "vesktop": {
                icon: "",
                name: "Vesktop"
            },
            "whatsapp": {
                icon: "󰖣",
                name: "WhatsApp"
            },
            "outlook": {
                icon: "󰴢",
                name: "Outlook"
            },

            // File Managers
            "doublecmd": {
                icon: "󰝰",
                name: "Double Commander"
            },
            "krusader": {
                icon: "󰝰",
                name: "Krusader"
            },
            "nautilus": {
                icon: "󰝰",
                name: "Files"
            },
            "nemo": {
                icon: "󰝰",
                name: "Nemo"
            },
            "org.kde.dolphin": {
                icon: "",
                name: "Dolphin"
            },
            "pcmanfm": {
                icon: "󰝰",
                name: "PCManFM"
            },
            "ranger": {
                icon: "󰝰",
                name: "Ranger"
            },
            "thunar": {
                icon: "󰝰",
                name: "Thunar"
            },
            "org.kde.ark": {
                icon: "󰀼",
                name: "Ark"
            },

            // Media Players
            "mpv": {
                icon: "",
                name: "mpv"
            },
            "plex": {
                icon: "󰚺",
                name: "Plex"
            },
            "rhythmbox": {
                icon: "󰓃",
                name: "Rhythmbox"
            },
            "ristretto": {
                icon: "󰋩",
                name: "Ristretto"
            },
            "spotify": {
                icon: "󰓇",
                name: "Spotify"
            },
            "com.mastermindzh.tidal-hifi": {
                icon: "",
                name: "Tidal"
            },
            "tidal-hifi": {
                icon: "",
                name: "Tidal"
            },
            "vlc": {
                icon: "󰕼",
                name: "VLC"
            },

            // Graphics Tools
            "blender": {
                icon: "󰂫",
                name: "Blender"
            },
            "gimp": {
                icon: "",
                name: "GIMP"
            },
            "inkscape": {
                icon: "",
                name: "Inkscape"
            },
            "krita": {
                icon: "",
                name: "Krita"
            },

            // Video Editing
            "kdenlive": {
                icon: "",
                name: "Kdenlive"
            },

            // Games and Gaming Platforms
            "csgo": {
                icon: "󰺵",
                name: "CS:GO"
            },
            "dota2": {
                icon: "󰺵",
                name: "Dota 2"
            },
            "heroic": {
                icon: "󰺵",
                name: "Heroic"
            },
            "lutris": {
                icon: "󰺵",
                name: "Lutris"
            },
            "minecraft": {
                icon: "󰍳",
                name: "Minecraft"
            },
            "steam": {
                icon: "",
                name: "Steam"
            },

            // Office and Productivity
            "evernote": {
                icon: "",
                name: "Evernote"
            },
            "libreoffice-base": {
                icon: "",
                name: "LibreOffice Base"
            },
            "libreoffice-calc": {
                icon: "",
                name: "LibreOffice Calc"
            },
            "libreoffice-draw": {
                icon: "",
                name: "LibreOffice Draw"
            },
            "libreoffice-impress": {
                icon: "",
                name: "LibreOffice Impress"
            },
            "libreoffice-math": {
                icon: "",
                name: "LibreOffice Math"
            },
            "libreoffice-writer": {
                icon: "",
                name: "LibreOffice Writer"
            },
            "obsidian": {
                icon: "󱓧",
                name: "Obsidian"
            },
            "sioyek": {
                icon: "",
                name: "Sioyek"
            },
            // putting these at the bottom, as they are defaults
            "libreoffice": {
                icon: "",
                name: "LibreOffice"
            },
            "title:LibreOffice": {
                icon: "",
                name: "LibreOffice"
            },
            "soffice": {
                icon: "",
                name: "LibreOffice"
            },

            // Utilities
            "balenaetcher": {
                icon: "󱊞",
                name: "balenaEtcher"
            },
            "blueman-manager": {
                icon: "",
                name: "Blueman"
            },
            "org.corectrl.corectrl": {
                icon: "󰍛",
                name: "CoreCtrl"
            },
            "nwg-displays": {
                icon: "󰍺",
                name: "nwg-displays"
            },
            "mullvad vpn": {
                icon: "󰖂",
                name: "Mullvad VPN"
            },
            "org.remmina.remmina": {
                icon: "󰢹",
                name: "Remmina"
            },
            "virt-manager": {
                icon: "󰢔",
                name: "Virt Manager"
            },
            "io.missioncenter.missioncenter": {
                icon: "",
                name: "Mission Center"
            },

            // Cloud Services and Sync
            "dropbox": {
                icon: "󰇣",
                name: "Dropbox"
            },

            // Fallback
            "unknown": {
                icon: "",
                name: "Desktop"
            }
        })

    /**
     * Look up app data by class name
     * @param className - Window class name
     * @returns App data object with icon and name
     */
    function lookup(className, title, xdgTag) {
        // Check xdgTag first for special cases like Proton games
        if (xdgTag === "proton-game") {
            return {
                icon: "󰊗",
                name: "Game"
            };
        }

        // Try className first
        if (className && className.length > 0) {
            const lowerClass = className.toLowerCase();

            // Try exact match
            if (iconMap[lowerClass]) {
                return iconMap[lowerClass];
            }

            // Try partial match (class contains key)
            for (const key in iconMap) {
                if (lowerClass.includes(key)) {
                    return iconMap[key];
                }
            }
        }

        // Fallback: try title if provided
        if (title && title.length > 0) {
            const lowerTitle = title.toLowerCase();

            // Try partial match (title contains key)
            for (const key in iconMap) {
                if (lowerTitle.includes(key)) {
                    return iconMap[key];
                }
            }
        }

        Logger.debug("No icon mapping found for class '" + className + "' and title '" + title + "'; using default.");
        return iconMap["unknown"];
    }

    /**
     * Get Nerd Font icon for window class
     * @param className - Window class name
     * @returns Nerd Font unicode character
     */
    function getIcon(className, title, xdgTag) {
        return lookup(className, title, xdgTag).icon;
    }

    /**
     * Get display name for window class
     * @param className - Window class name
     * @returns Friendly display name
     */
    function getDisplayName(className, title, xdgTag) {
        return lookup(className, title, xdgTag).name;
    }

    /**
     * Get icon file path for an app
     * Tries to resolve actual icon files from XDG icon themes
     * @param appName - Application name (for fallback lookup)
     * @param appIcon - Icon name/path from notification
     * @returns File path (with file:// prefix) or empty string
     */
    function getIconPath(appName, appIcon) {
        if (!appIcon || appIcon.length === 0) {
            return "";
        }

        // If already a file path, return it
        if (appIcon.startsWith("/")) {
            return "file://" + appIcon;
        }
        if (appIcon.startsWith("file://")) {
            return appIcon;
        }

        // Normalize icon name (remove extension if present)
        let iconName = appIcon;
        if (iconName.endsWith(".png") || iconName.endsWith(".svg")) {
            iconName = iconName.substring(0, iconName.lastIndexOf("."));
        }

        // Determine icon category based on name patterns
        let category = "apps";
        if (iconName.match(/^(video|audio|image|text|application|font|x-office|package)-/)) {
            category = "mimetypes";
        } else if (iconName.match(/^(edit|document|list|view|go|media|window|system|help|insert)-/)) {
            category = "actions";
        } else if (iconName.match(/^(dialog|emblem)-/)) {
            category = "emblems";
        } else if (iconName.match(/^(user|folder|network|drive|computer|phone)-/)) {
            category = "places";
        } else if (iconName.match(/^(battery|network|audio|display|input|printer|weather)-/)) {
            category = "status";
        }

        // Try breeze theme first (common on KDE/Arch), uses category/size/ structure
        return "file:///usr/share/icons/breeze/" + category + "/64/" + iconName + ".svg";
    }
}
