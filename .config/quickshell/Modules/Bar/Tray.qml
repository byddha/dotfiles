import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../Utils"
import "../../Config"
import "../../Components"
import "Popups"

/**
 * Tray - System tray with unified background container
 *
 * Displays system tray icons in a single background container matching workspace style.
 */
Item {
    id: root

    required property var barWindow  // Pass the bar's window to get screen

    visible: SystemTray.items.values.length > 0
    implicitWidth: trayBackground.width
    implicitHeight: BarStyle.barHeight

    // Track currently open menu for focus management
    property var activeMenu: null

    // Pending menu configuration (to pass to Loader)
    property var pendingMenuItem: null
    property real pendingMenuX: 0
    property real pendingMenuY: 0

    // Parent-level focus grab handles the single tray menu window (ii pattern)
    HyprlandFocusGrab {
        id: focusGrab
        active: false
        windows: [root.activeMenu]
        onCleared: {
            Logger.info("Focus cleared (clicked outside or Escape pressed)");
            if (root.activeMenu) {
                root.activeMenu.hideMenu();
                root.releaseFocus();
            }
        }
    }

    function setActiveMenuAndGrabFocus(menuWindow) {
        root.activeMenu = menuWindow;
        focusGrab.active = true;
        Logger.info("Focus grabbed for menu");
    }

    function releaseFocus() {
        focusGrab.active = false;
        root.activeMenu = null;
        menuLoader.active = false;  // Destroy menu component
        Logger.info("Focus released");
    }

    function showMenuFor(item, x, y) {
        root.pendingMenuItem = item;
        root.pendingMenuX = x;
        root.pendingMenuY = y;
        menuLoader.active = true;  // Create fresh menu instance
    }

    // TrayMenu Loader - Recreates menu on each open for fresh state
    Loader {
        id: menuLoader
        active: false

        sourceComponent: TrayMenu {
            Component.onCompleted: {
                // Show menu immediately when created
                showAt(root.pendingMenuItem, root.pendingMenuX, root.pendingMenuY);
            }

            onMenuOpened: window => root.setActiveMenuAndGrabFocus(window)
            onMenuClosed: root.releaseFocus()
        }
    }

    // Background for all tray icons (like workspaces)
    Rectangle {
        id: trayBackground
        width: trayRow.width + (BarStyle.spacing * 2)
        height: BarStyle.barHeight
        color: BarStyle.buttonBackground
        radius: BarStyle.buttonRadius

        Behavior on width {
            NumberAnimation {
                duration: Theme.animation.elementMoveFast.duration
                easing.type: Theme.animation.elementMoveFast.type
                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
            }
        }
    }

    Row {
        id: trayRow
        x: BarStyle.spacing
        spacing: 0
        height: BarStyle.barHeight

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem
                width: BarStyle.buttonSize
                height: BarStyle.buttonSize
                visible: modelData

                property var item: modelData

                // Tooltip
                Tooltip {
                    id: trayTooltip
                    target: trayItem
                    text: trayItem.item?.tooltipTitle || trayItem.item?.name || trayItem.item?.id || ""
                }

                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: BarStyle.iconSize
                    height: BarStyle.iconSize
                    smooth: true
                    asynchronous: true
                    backer.fillMode: Image.PreserveAspectFit
                    source: {
                        let icon = trayItem.item?.icon || "";
                        if (!icon)
                            return "";

                        // Handle special ?path= format for custom icon paths
                        if (icon.includes("?path=")) {
                            const chunks = icon.split("?path=");
                            const name = chunks[0];
                            const path = chunks[1];
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return `file://${path}/${fileName}`;
                        }
                        return icon;
                    }
                }

                MouseArea {
                    id: trayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onEntered: {
                        if (Config.options?.bar?.tray?.showTooltips ?? true) {
                            trayTooltip.show();
                        }
                    }

                    onExited: {
                        trayTooltip.hide();
                    }

                    onClicked: mouse => {
                        if (!trayItem.item)
                            return;

                        // Hide tooltip when clicking
                        trayTooltip.hide();

                        if (mouse.button === Qt.LeftButton) {
                            if (!trayItem.item.onlyMenu) {
                                trayItem.item.activate();
                                Logger.info(`Activated: ${trayItem.item.name || trayItem.item.id}`);
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayItem.item.secondaryActivate();
                            Logger.info(`Secondary activated: ${trayItem.item.name || trayItem.item.id}`);
                        } else if (mouse.button === Qt.RightButton) {
                            if (trayItem.item.menu) {
                                // Calculate menu position as offset from tray icon
                                const menuX = (trayItem.width / 2) - 100;  // Approximate menu width
                                const menuY = Theme.barHeight;

                                root.showMenuFor(trayItem, menuX, menuY);
                                Logger.info(`Menu opened: ${trayItem.item.name || trayItem.item.id}`);
                            }
                        }
                    }
                }
            }
        }
    }
}
