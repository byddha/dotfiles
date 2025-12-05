import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"

/**
 * Reusable OSD indicator component - Vertical Bar Layout
 *
 * Layout (top to bottom):
 * ┌─────────┐
 * │   75    │  ← Percentage number
 * ├─────────┤
 * │ ▓▓▓▓▓▓▓ │  ← Vertical bar (fills bottom-to-top)
 * │ ░░░░░░░ │
 * └─────────┘
 * ┌─────────┐
 * │   🔊    │  ← Icon (inverted colors)
 * └─────────┘
 */
Item {
    id: root

    // Required properties
    required property real value  // 0.0 to 1.0
    required property string icon  // Icon character

    // Sizing
    property real barWidth: 24
    property real barHeight: 180
    property real padding: Theme.spacingBase

    implicitWidth: mainColumn.implicitWidth + Theme.elevationMargin * 2
    implicitHeight: mainColumn.implicitHeight + Theme.elevationMargin * 2

    ColumnLayout {
        id: mainColumn
        anchors.centerIn: parent
        spacing: 0

        // Top section: Number + Vertical Bar (shared background)
        Rectangle {
            id: topSection
            color: Theme.alpha(Theme.colLayer0, 0.95)
            border.width: 1
            border.color: Theme.colLayer2

            // Only round top corners
            topLeftRadius: Theme.radiusBase
            topRightRadius: Theme.radiusBase
            bottomLeftRadius: 0
            bottomRightRadius: 0

            Layout.preferredWidth: root.barWidth + root.padding * 2
            Layout.preferredHeight: numberText.implicitHeight + root.padding + root.barHeight + root.padding

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.padding
                spacing: root.padding

                // Percentage number
                Text {
                    id: numberText
                    text: Math.round(root.value * 100)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBase + 2
                    font.weight: Font.Medium
                    color: Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                // Vertical progress bar
                Rectangle {
                    id: barTrack
                    Layout.preferredWidth: 12
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.colLayer2
                    radius: 6

                    // Fill (anchored to bottom, height based on value)
                    Rectangle {
                        id: barFill
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.height * root.value
                        color: Theme.primary
                        radius: parent.radius

                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.animation.elementMoveFast.duration
                                easing.type: Theme.animation.elementMoveFast.type
                                easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                            }
                        }
                    }
                }
            }
        }

        // Bottom section: Icon (primary color background)
        Rectangle {
            id: iconSection
            color: Theme.primary

            // Only round bottom corners
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Theme.radiusBase
            bottomRightRadius: Theme.radiusBase

            Layout.preferredWidth: root.barWidth + root.padding * 2
            Layout.preferredHeight: root.barWidth + root.padding * 2

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.fontFamilyIcons
                font.pixelSize: root.barWidth
                color: Theme.colLayer0
            }
        }
    }
}
