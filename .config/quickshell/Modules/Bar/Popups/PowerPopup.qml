pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../Config"
import "../../../Utils"
import "../../../Components"
import "../../../Services"

PanelWindow {
    id: powerPopup

    property var anchorItem: null
    property var targetScreen: null
    property real popupX: 0
    property real popupY: 0

    signal panelOpened(window: var)
    signal panelClosed

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

    WlrLayershell.namespace: "bidshell:power-popup"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? (Compositor.useHyprlandFocusGrab ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    onVisibleChanged: {
        if (!visible) {
            panelClosed();
        } else {
            Qt.callLater(updatePosition);
        }
    }

    function updatePosition() {
        if (!anchorItem || !targetScreen)
            return;
        const pos = anchorItem.mapToGlobal(0, 0);
        const screenX = targetScreen.x || 0;
        const screenY = targetScreen.y || 0;
        const w = panelBg.implicitWidth;
        const h = panelBg.implicitHeight;
        popupX = Math.max(8, Math.min((targetScreen.width || width) - w - 8, pos.x - screenX + (anchorItem.width / 2) - (w / 2)));
        popupY = Math.max(8, Math.min((targetScreen.height || height) - h - 8, pos.y - screenY + anchorItem.height + 4));
    }

    function showPanel(item) {
        if (!item) {
            Logger.warn("anchorItem is undefined, won't show panel.");
            return;
        }
        anchorItem = item;
        targetScreen = item.QsWindow?.window?.screen ?? null;
        visible = true;
        panelOpened(powerPopup);
        Qt.callLater(updatePosition);
        Logger.info("Panel opened");
    }

    function hidePanel() {
        visible = false;
        Logger.info("Panel hidden");
    }

    MouseArea {
        anchors.fill: parent
        enabled: powerPopup.visible
        onClicked: powerPopup.hidePanel()
    }

    Item {
        focus: powerPopup.visible
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                powerPopup.hidePanel();
                event.accepted = true;
            }
        }
    }

    Item {
        x: powerPopup.popupX
        y: powerPopup.popupY
        width: panelBg.implicitWidth
        height: panelBg.implicitHeight

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
            id: panelBg
            width: buttonsRow.implicitWidth + Theme.spacingBase * 2
            height: buttonsRow.implicitHeight + Theme.spacingBase * 2
            implicitWidth: width
            implicitHeight: height
            color: Theme.colLayer0
            radius: Theme.radiusBase
            border.color: Theme.colLayer0Border
            border.width: 1

            Row {
                id: buttonsRow
                anchors.centerIn: parent
                spacing: Theme.spacingBase

                PowerActionButton {
                    icon: Icons.shutdown
                    onClicked: {
                        const threshold = Config.options.peripheralBatteries?.shutdownReminderThreshold ?? 40;
                        const lowDevices = PeripheralBatteries.getLowBatteryDevices(threshold);
                        if (lowDevices.length === 0) {
                            PowerActions.poweroff();
                        } else {
                            Settings.shutdownReminderVisible = true;
                        }
                        powerPopup.hidePanel();
                    }
                }
                PowerActionButton {
                    icon: Icons.reboot
                    onClicked: {
                        PowerActions.reboot();
                        powerPopup.hidePanel();
                    }
                }
                PowerActionButton {
                    icon: Icons.logout
                    onClicked: {
                        PowerActions.logout();
                        powerPopup.hidePanel();
                    }
                }
                PowerActionButton {
                    icon: Icons.suspend
                    onClicked: {
                        PowerActions.suspend();
                        powerPopup.hidePanel();
                    }
                }
            }
        }
    }
}
