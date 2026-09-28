pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../Config"

/**
 * Tray - Status notifier items. Left click activates (or opens the menu when the item only has
 * a menu), middle click is the item's secondary action, right click opens its menu.
 */
Grid {
    id: root

    property TrayMenu menu: TrayMenu {}

    columns: BarLayout.vertical ? 1 : Math.max(1, children.length)
    spacing: 2

    Repeater {
        model: SystemTray.items

        BarItem {
            id: trayButton

            required property SystemTrayItem modelData

            iconOnly: true
            highlighted: root.menu.visible && root.menu.menu === modelData.menu
            tooltipTitle: highlighted ? "" : modelData.tooltipTitle || modelData.title || modelData.id

            onClicked: mouse => {
                const item = modelData;
                if (mouse.button === Qt.MiddleButton)
                    item.secondaryActivate();
                else if (mouse.button === Qt.RightButton || item.onlyMenu)
                    openMenu();
                else
                    item.activate();
            }

            function openMenu() {
                if (!modelData.hasMenu)
                    return;
                if (highlighted)
                    root.menu.hidePanel();
                else
                    root.menu.openMenu(modelData.menu, trayButton);
            }

            IconImage {
                implicitSize: 16
                source: {
                    const icon = trayButton.modelData.icon;
                    // Some apps send "name?path=/dir" for an icon outside the theme
                    if (icon.includes("?path=")) {
                        const [name, dir] = icon.split("?path=");
                        return `file://${dir}/${name.substring(name.lastIndexOf("/") + 1)}`;
                    }
                    return icon;
                }
            }
        }
    }
}
