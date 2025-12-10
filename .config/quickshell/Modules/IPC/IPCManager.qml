import QtQuick
import Quickshell.Io
import "../../Config"
import "../../Services"
import "../../Services/Hyprland"
import "../../Utils"

Item {
    id: root

    IpcHandler {
        target: "theme"

        function setTheme(themeName: string): string {
            Logger.info("IPC: theme.setTheme called with:", themeName);
            Config.options.general.base16Theme = themeName;
            Config.saveConfig();
            return `Theme switched to: ${themeName}`;
        }

        function getTheme(): string {
            const theme = Config.options.general.base16Theme;
            Logger.info("IPC: theme.getTheme →", theme);
            return theme;
        }

        function listThemes(): string {
            Logger.info("IPC: theme.listThemes called");
            ThemeService.listThemes(function (themes) {
                Logger.info("Available themes:", themes.join(", "));
            });
            return "Listing themes...";
        }
    }

    IpcHandler {
        target: "sidebar"

        function toggle(): string {
            Settings.sidebarVisible = !Settings.sidebarVisible;
            Logger.info("IPC: sidebar.toggle →", Settings.sidebarVisible ? "shown" : "hidden");
            return `Sidebar ${Settings.sidebarVisible ? "shown" : "hidden"}`;
        }

        function show(): string {
            Logger.info("IPC: sidebar.show");
            Settings.sidebarVisible = true;
            return "Sidebar shown";
        }

        function hide(): string {
            Logger.info("IPC: sidebar.hide");
            Settings.sidebarVisible = false;
            return "Sidebar hidden";
        }

        function status(): string {
            Logger.debug("IPC: sidebar.status →", Settings.sidebarVisible ? "visible" : "hidden");
            return `Sidebar is ${Settings.sidebarVisible ? "visible" : "hidden"}`;
        }
    }

    IpcHandler {
        target: "games"

        function toggle(): string {
            Settings.gameLauncherVisible = !Settings.gameLauncherVisible;
            Logger.info("IPC: games.toggle →", Settings.gameLauncherVisible ? "shown" : "hidden");
            return `Game Launcher ${Settings.gameLauncherVisible ? "shown" : "hidden"}`;
        }

        function show(): string {
            Logger.info("IPC: games.show");
            Settings.gameLauncherVisible = true;
            return "Game Launcher shown";
        }

        function hide(): string {
            Logger.info("IPC: games.hide");
            Settings.gameLauncherVisible = false;
            return "Game Launcher hidden";
        }

        function refresh(): string {
            Logger.info("IPC: games.refresh");
            GameService.refresh();
            return "Refreshing game library...";
        }
    }

    IpcHandler {
        target: "hyprwhichkey"

        function toggle(): string {
            HyprWhichKeyService.toggleManual();
            Logger.info("IPC: hyprwhichkey.toggle →", HyprWhichKeyService.visible ? "shown" : "hidden");
            return `HyprWhichKey ${HyprWhichKeyService.visible ? "shown" : "hidden"}`;
        }
    }

    IpcHandler {
        target: "screenshot"

        function region(): string {
            Settings.regionSelectorVisible = true;
            Logger.info("IPC: screenshot.region");
            return "Opening region selector";
        }

        function toggle(): string {
            Settings.regionSelectorVisible = !Settings.regionSelectorVisible;
            Logger.info("IPC: screenshot.toggle →", Settings.regionSelectorVisible ? "shown" : "hidden");
            return `Region selector ${Settings.regionSelectorVisible ? "shown" : "hidden"}`;
        }

        function hide(): string {
            Settings.regionSelectorVisible = false;
            Logger.info("IPC: screenshot.hide");
            return "Region selector hidden";
        }
    }
}
