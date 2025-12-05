import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Config"
import "../../Components"
import "../../Utils"
import "../../Services"
import "VolumeMixer"
import "NotificationHistory"
import "BluetoothTab"
import "NetworkTab"

Card {
    id: root

    property int selectedTab: Settings.sidebarSelectedTab
    onSelectedTabChanged: Settings.sidebarSelectedTab = selectedTab
    collapsible: true
    collapsed: false

    // Tab data model with icon and name
    property var tabModel: [
        { icon: Icons.volumeHigh, name: "Volume" },
        { icon: Icons.bell, name: "Notifications" },
        { icon: Icons.bluetoothOn, name: "Bluetooth" },
        { icon: Icons.wifiOn, name: "Network" }
    ]

    ColumnLayout {
        width: parent.width
        spacing: Theme.spacingBase

        // Tab bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.tabModel

                Rectangle {
                    id: tabButton
                    property bool isActive: index === root.selectedTab
                    property bool isHovered: tabMouseArea.containsMouse

                    Layout.fillWidth: true
                    Layout.preferredWidth: isActive ? 3 : 1  // Active tab gets 3x weight
                    height: 32
                    radius: Theme.radiusBase
                    color: isActive ? Theme.primary : (isHovered ? Theme.colLayer2 : "transparent")

                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    // Content row
                    Row {
                        id: expandedContent
                        anchors.centerIn: parent
                        spacing: 6

                        // Icon
                        Text {
                            text: modelData.icon
                            font.family: Theme.fontFamilyIcons
                            font.pixelSize: Theme.fontSizeBase + 2
                            color: tabButton.isActive ? Theme.primaryText : Theme.textColor
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        // Name (only visible when active)
                        Text {
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBase
                            color: Theme.primaryText
                            visible: tabButton.isActive
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: tabMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.selectedTab = index
                    }
                }
            }
        }

        // Tab content
        StackLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 450

            currentIndex: root.selectedTab

            // Volume Mixer tab
            Loader {
                active: root.selectedTab === 0
                sourceComponent: VolumeMixerTab {}
            }

            // Notifications tab
            Loader {
                active: root.selectedTab === 1
                sourceComponent: NotificationHistoryTab {}
            }

            // Bluetooth tab
            Loader {
                active: root.selectedTab === 2
                sourceComponent: BluetoothTab {}
            }

            // Network tab
            Loader {
                active: root.selectedTab === 3
                sourceComponent: NetworkTab {}
            }
        }
    }

    Component.onCompleted: {
        Logger.info("Tabbed section loaded")
    }
}
