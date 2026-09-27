import QtQuick
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Services"

ListRow {
    id: root

    required property var device

    readonly property int percentage: device?.percentage ?? 0
    readonly property bool charging: device?.charging ?? false
    readonly property bool isLow: !charging && percentage <= 20
    readonly property bool isCritical: !charging && percentage <= 10
    readonly property color levelColor: isCritical ? Theme.accentRed : isLow ? Theme.accentOrange : Theme.primary

    lead: Component {
        Item {
            implicitWidth: 32
            implicitHeight: 32

            Image {
                id: logo
                anchors.fill: parent
                anchors.margins: 2
                source: root.device?.logoPath ?? ""
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: logo.status !== Image.Ready
                text: root.device?.typeIcon ?? Icons.device
                font.family: Theme.fontFamilyGlyphs
                font.pixelSize: 20
                color: Theme.textSecondary
            }
        }
    }
    title: device?.name ?? "Unknown device"
    minHeight: 48
    subtitleIcon: device?.typeIcon ?? ""
    subtitle: {
        switch (device?.connectionType) {
        case "bluetooth":
            return "Bluetooth";
        case "2.4ghz":
            return "2.4 GHz";
        case "wired":
            return "USB";
        default:
            return "";
        }
    }
    trail: Component {
        RowLayout {
            spacing: 6

            Text {
                visible: root.charging
                text: Icons.lightningBolt
                font.family: Theme.fontFamilyGlyphs
                font.pixelSize: 16
                color: Theme.primary
            }

            // Battery shell
            Rectangle {
                implicitWidth: 24
                implicitHeight: 12
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(Theme.outline, 0.35)

                Rectangle {
                    x: 2
                    y: 2
                    width: Math.max(2, (parent.width - 4) * root.percentage / 100)
                    height: parent.height - 4
                    radius: 1
                    color: root.levelColor
                }
            }

            StyledText {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: root.percentage + "%"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.levelColor
            }
        }
    }
}
