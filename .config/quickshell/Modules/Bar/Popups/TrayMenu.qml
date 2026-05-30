pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../../../Config"
import "../../../Utils"
import "../../../Components"
import "../../../Services"
import ".."

PanelWindow {
    id: trayMenu

    property var menu: null
    property var anchorItem: null
    property var targetScreen: null
    property real anchorX: 0
    property real anchorY: 0
    property real popupX: 0
    property real popupY: 0

    // Signals for parent focus management (ii pattern)
    signal menuOpened(window: var)
    signal menuClosed

    screen: targetScreen
    implicitWidth: 0
    implicitHeight: 0
    visible: false
    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.namespace: "bidshell:tray-menu"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? (Compositor.useHyprlandFocusGrab ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    // Emit menuClosed only when menu actually closes
    onVisibleChanged: {
        if (!visible) {
            menuClosed();
        } else {
            Qt.callLater(updatePosition);
        }
    }

    // Keyboard focus for Escape key handling
    Item {
        id: keyHandler
        focus: trayMenu.visible
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                trayMenu.hideMenu();
                event.accepted = true;
            }
        }
    }

    function updatePosition() {
        if (!anchorItem || !targetScreen)
            return;
        const pos = anchorItem.mapToGlobal(0, 0);
        const screenX = targetScreen.x || 0;
        const screenY = targetScreen.y || 0;
        const w = menuBg.implicitWidth;
        const h = menuBg.implicitHeight;
        popupX = Math.max(8, Math.min((targetScreen.width || width) - w - 8, pos.x - screenX + anchorX));
        popupY = Math.max(8, Math.min((targetScreen.height || height) - h - 8, pos.y - screenY + anchorY));
    }

    function showAt(item, x, y, panelScreen) {
        if (!item) {
            Logger.warn("anchorItem is undefined, won't show menu.");
            return;
        }
        menu = item.item.menu;
        anchorItem = item;
        targetScreen = panelScreen ?? item.QsWindow?.window?.screen ?? null;
        anchorX = x;
        anchorY = y;
        visible = true;
        menuOpened(trayMenu);  // Emit signal with window instance
        Qt.callLater(updatePosition);
        Logger.info(`Menu opened at anchor offset ${x}, ${y}`);
    }

    function hideMenu() {
        visible = false;
        // Pop all submenu views back to root
        while (stackView.depth > 1) {
            stackView.pop();
        }
        Logger.info("Menu hidden");
    }

    MouseArea {
        anchors.fill: parent
        enabled: trayMenu.visible
        onClicked: trayMenu.hideMenu()
    }

    // Background with shadow
    Item {
        x: trayMenu.popupX
        y: trayMenu.popupY
        width: menuBg.implicitWidth
        height: menuBg.implicitHeight

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => {
                mouse.accepted = true;
            }
            onClicked: mouse => {
                mouse.accepted = true;
            }
        }

        Rectangle {
            id: menuBg
            width: stackView.implicitWidth + Theme.spacingBase * 2
            height: stackView.implicitHeight + Theme.spacingBase * 2
            implicitWidth: width
            implicitHeight: height
            color: Theme.surface
            border.color: Theme.colLayer0Border
            border.width: 1
            radius: Theme.radiusBase

            onImplicitWidthChanged: Qt.callLater(trayMenu.updatePosition)
            onImplicitHeightChanged: Qt.callLater(trayMenu.updatePosition)

            StackView {
                id: stackView
                anchors.fill: parent
                anchors.margins: Theme.spacingBase

                // No animations for instant transitions
                pushEnter: Transition {}
                pushExit: Transition {}
                popEnter: Transition {}
                popExit: Transition {}

                implicitWidth: currentItem ? currentItem.implicitWidth : 200
                implicitHeight: currentItem ? currentItem.implicitHeight : 40

                initialItem: MenuLevel {
                    menuHandle: trayMenu.menu
                }
            }
        }
    }

    // MenuLevel component - reusable for root and submenus
    component MenuLevel: Item {
        id: menuLevel
        required property var menuHandle
        property bool isSubMenu: false

        implicitWidth: 200
        implicitHeight: menuLevel.isSubMenu ? (backButton.height + listView.contentHeight + 2) : listView.contentHeight

        QsMenuOpener {
            id: opener
            menu: menuLevel.menuHandle
        }

        Column {
            anchors.fill: parent
            spacing: 2

            // Back button for submenus
            Rectangle {
                id: backButton
                width: parent.width
                height: menuLevel.isSubMenu ? Math.max(32, backText.height + Theme.spacingBase) : 0
                visible: menuLevel.isSubMenu
                color: backMouseArea.containsMouse ? Theme.colLayer2 : "transparent"
                radius: Theme.radiusBase

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingBase
                    anchors.rightMargin: Theme.spacingBase
                    spacing: Theme.spacingBase / 2

                    Text {
                        text: "‹"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBase
                        font.weight: Font.Bold
                        color: Theme.textColor
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: backText
                        Layout.fillWidth: true
                        color: Theme.textColor
                        text: "Back"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: backMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        stackView.pop();
                        Logger.info("Navigated back from submenu");
                    }
                }
            }

            ListView {
                id: listView
                width: parent.width
                height: contentHeight
                spacing: 2
                interactive: false
                clip: true

                model: ScriptModel {
                    values: opener.children ? [...opener.children.values] : []
                }

                delegate: Rectangle {
                    id: entry
                    required property var modelData

                    width: listView.width
                    height: (modelData?.isSeparator) ? 8 : Math.max(32, entryText.height + Theme.spacingBase)
                    color: "transparent"

                    // Separator
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - Theme.spacingBase * 2
                        height: 1
                        color: Theme.colLayer0Border
                        visible: modelData?.isSeparator ?? false
                    }

                    // Menu item
                    Rectangle {
                        id: entryBg
                        anchors.fill: parent
                        color: mouseArea.containsMouse ? Theme.colLayer2 : "transparent"
                        radius: Theme.radiusBase
                        visible: !(modelData?.isSeparator ?? false)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingBase
                            anchors.rightMargin: Theme.spacingBase
                            spacing: Theme.spacingBase / 2

                            // Checkbox/Radio indicator
                            Item {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                visible: modelData?.buttonType !== undefined && modelData.buttonType !== 0 // QsMenuButtonType.None = 0

                                // CheckBox - Rectangle
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    radius: 2
                                    visible: modelData?.buttonType === 1 // QsMenuButtonType.CheckBox

                                    // Checked state: filled rectangle
                                    color: (modelData?.checkState === 2 || modelData?.checkState === 1) ? Theme.primary : "transparent"
                                    border.color: Theme.colLayer0Border
                                    border.width: 1

                                    // Partially checked: show with lower opacity
                                    opacity: modelData?.checkState === 1 ? 0.5 : 1.0
                                }

                                // RadioButton - Text circles
                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData?.buttonType === 2 // QsMenuButtonType.RadioButton
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeBase
                                    color: Theme.textColor
                                    text: modelData?.checkState === 2 ? "●" : "○"
                                }
                            }

                            Text {
                                id: entryText
                                Layout.fillWidth: true
                                color: (modelData?.enabled ?? true) ? Theme.textColor : Theme.textSecondary
                                text: modelData?.text ?? ""
                                font.family: BarStyle.textFont
                                font.pixelSize: BarStyle.textSize
                                font.weight: BarStyle.textWeight
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            IconImage {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                source: modelData?.icon ?? ""
                                visible: (modelData?.icon ?? "") !== ""
                                backer.fillMode: Image.PreserveAspectFit
                            }

                            // Submenu indicator
                            Text {
                                text: "›"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBase
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                visible: modelData?.hasChildren ?? false
                                color: (modelData?.enabled ?? true) ? Theme.textColor : Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: (modelData?.enabled ?? true) && !(modelData?.isSeparator ?? false)

                            onClicked: {
                                if (modelData && !modelData.isSeparator) {
                                    if (modelData.hasChildren) {
                                        // Push submenu onto stack
                                        stackView.push(menuLevelComponent, {
                                            menuHandle: modelData,
                                            isSubMenu: true
                                        });
                                        Logger.info("Opened submenu");
                                    } else {
                                        // Execute action and close menu
                                        modelData.triggered();
                                        trayMenu.hideMenu();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Component for creating submenu levels
    Component {
        id: menuLevelComponent
        MenuLevel {}
    }
}
