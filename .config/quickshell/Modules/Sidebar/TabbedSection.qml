pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"
import "../../Services"
import "VolumeMixer"
import "NotificationHistory"
import "BluetoothTab"
import "NetworkTab"
import "PeripheralsTab"

Card {
    id: root

    property bool shown: false
    property int selectedTab: Settings.sidebarSelectedTab
    onSelectedTabChanged: Settings.sidebarSelectedTab = selectedTab

    readonly property var tabModel: [
        {
            icon: Icons.volumeHigh,
            name: "Volume"
        },
        {
            icon: Icons.bell,
            name: "Notifications"
        },
        {
            icon: Icons.bluetoothOn,
            name: "Bluetooth"
        },
        {
            icon: Icons.wifiOn,
            name: "Network"
        },
        {
            icon: Icons.device,
            name: "Peripherals"
        }
    ]

    padding: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.margins: 8
        Layout.minimumHeight: implicitHeight
        spacing: 4

        Repeater {
            model: root.tabModel

            Rectangle {
                id: tab
                required property var modelData
                required property int index
                readonly property bool active: index === root.selectedTab

                Layout.fillWidth: !active
                Layout.preferredWidth: active ? tabRow.implicitWidth + 24 : 0
                implicitHeight: 36
                radius: Theme.radiusBase
                color: active ? Theme.secondaryContainer : "transparent"

                StateLayer {
                    hovered: tabMouse.containsMouse
                    pressed: tabMouse.pressed
                }

                RowLayout {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingBase

                    Text {
                        text: tab.modelData.icon
                        font.family: Theme.fontFamilyGlyphs
                        font.pixelSize: 20
                        color: tab.active ? Theme.onSecondaryContainer : Theme.textSecondary
                    }

                    StyledText {
                        visible: tab.active
                        text: tab.modelData.name
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.onSecondaryContainer
                    }
                }

                Tooltip {
                    id: tooltip
                    target: tab
                    text: tab.modelData.name
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        if (!tab.active)
                            tooltip.show();
                    }
                    onExited: tooltip.hide()
                    onClicked: {
                        tooltip.hide();
                        root.selectedTab = tab.index;
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.minimumHeight: 1
        implicitHeight: 1
        color: Theme.outlineVariant
    }

    // All tabs stay loaded: switching never rebuilds a tab and keeps its scroll position.
    // StackLayout's own natural height is its tallest tab; the sidebar follows the open one.
    StackLayout {
        id: stack
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: stack.children[stack.currentIndex]?.implicitHeight ?? 0
        currentIndex: root.selectedTab

        VolumeMixerTab {
            shown: root.shown && root.selectedTab === 0
        }
        NotificationHistoryTab {
            shown: root.shown && root.selectedTab === 1
        }
        BluetoothTab {
            shown: root.shown && root.selectedTab === 2
        }
        NetworkTab {
            shown: root.shown && root.selectedTab === 3
        }
        PeripheralsTab {
            shown: root.shown && root.selectedTab === 4
        }
    }
}
