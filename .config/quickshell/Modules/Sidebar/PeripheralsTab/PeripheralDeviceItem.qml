import QtQuick
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Services"
import "../../../Utils"

Rectangle {
    id: root

    required property var device

    property int percentage: device?.percentage ?? 0
    property bool charging: device?.charging ?? false
    property bool isLow: !charging && percentage <= 20
    property bool isCritical: !charging && percentage <= 10
    property string logoPath: device?.logoPath ?? ""

    implicitHeight: contentColumn.implicitHeight + Theme.spacingBase * 2
    radius: Theme.radiusBase
    color: mouseArea.containsMouse ? Theme.colLayer2 : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingBase
        spacing: Theme.spacingBase

        // Brand logo or padding
        Item {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                source: root.logoPath
                fillMode: Image.PreserveAspectFit
                cache: true
                visible: status === Image.Ready
                smooth: true
            }
        }

        // Two-row content
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: 2

            // Row 1: Product name
            StyledText {
                Layout.fillWidth: true
                text: root.device?.name ?? "Unknown Device"
                font.pixelSize: Theme.fontSizeBase
                color: Theme.textColor
                elide: Text.ElideRight
            }

            // Row 2: type icon + connection type ... charging + battery %
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Device type icon
                Text {
                    text: root.device?.typeIcon ?? ""
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: Theme.fontSizeSmall + 2
                    color: Theme.textSecondary
                }

                // Connection type label
                StyledText {
                    text: {
                        switch (root.device?.connectionType) {
                        case "bluetooth": return "Bluetooth";
                        case "2.4ghz": return "2.4 GHz";
                        case "wired": return "Wired";
                        default: return "";
                        }
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                // Charging icon
                Text {
                    visible: root.charging
                    text: Icons.batteryCharging
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: Theme.fontSizeSmall + 2
                    color: Theme.primary

                    SequentialAnimation on opacity {
                        running: root.charging
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 1000; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                    }
                }

                // Battery percentage
                StyledText {
                    text: root.percentage + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.isCritical ? Theme.accentRed
                         : root.isLow ? Theme.accentOrange
                         : root.charging ? Theme.primary
                         : Theme.textColor
                }
            }

            // Battery progress bar
            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 1.5
                color: Theme.colLayer2

                Rectangle {
                    width: parent.width * (root.percentage / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.isCritical ? Theme.accentRed
                         : root.isLow ? Theme.accentOrange
                         : root.charging ? Theme.primary
                         : Theme.textColor
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
