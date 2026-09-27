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
            name: "Volume",
            label: "Volume"
        },
        {
            icon: Icons.bell,
            name: "Notifications",
            label: "Notifs"
        },
        {
            icon: Icons.bluetoothOn,
            name: "Bluetooth",
            label: "Bluetooth"
        },
        {
            icon: Icons.wifiOn,
            name: "Network",
            label: "Network"
        },
        {
            icon: Icons.device,
            name: "Peripherals",
            label: "Devices"
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

            // Equal widths and an always-visible label: switching tabs never moves the other tabs
            Rectangle {
                id: tab
                required property var modelData
                required property int index
                readonly property bool active: index === root.selectedTab
                readonly property color foreground: active ? Theme.secondaryContainerText : Theme.textSecondary

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 48
                radius: Theme.radiusBase
                color: active ? Theme.secondaryContainer : "transparent"

                StateLayer {
                    hovered: tabMouse.containsMouse
                    pressed: tabMouse.pressed
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: tab.modelData.icon
                        font.family: Theme.fontFamilyGlyphs
                        font.pixelSize: 20
                        color: tab.foreground
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: tab.modelData.label
                        font.pixelSize: 11
                        font.weight: tab.active ? Font.Medium : Font.Normal
                        color: tab.foreground
                    }
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
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
