import QtQuick
import Quickshell.Io
import "../../Config"
import "../../Services"
import "../../Utils"

Item {
    id: root

    IpcHandler {
        target: "theme"

        function setTheme(themeName: string): string {
            Logger.info("IPC: theme.setTheme called with:", themeName)
            Config.options.general.base16Theme = themeName;
            Config.saveConfig();
            return `Theme switched to: ${themeName}`;
        }

        function getTheme(): string {
            const theme = Config.options.general.base16Theme;
            Logger.info("IPC: theme.getTheme →", theme)
            return theme;
        }

        function listThemes(): string {
            Logger.info("IPC: theme.listThemes called")
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
            Logger.info("IPC: sidebar.toggle →", Settings.sidebarVisible ? "shown" : "hidden")
            return `Sidebar ${Settings.sidebarVisible ? "shown" : "hidden"}`;
        }

        function show(): string {
            Logger.info("IPC: sidebar.show")
            Settings.sidebarVisible = true;
            return "Sidebar shown";
        }

        function hide(): string {
            Logger.info("IPC: sidebar.hide")
            Settings.sidebarVisible = false;
            return "Sidebar hidden";
        }

        function status(): string {
            Logger.debug("IPC: sidebar.status →", Settings.sidebarVisible ? "visible" : "hidden")
            return `Sidebar is ${Settings.sidebarVisible ? "visible" : "hidden"}`;
        }
    }
}
