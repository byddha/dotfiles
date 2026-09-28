import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"

Item {
    id: root

    required property real value  // 0.0 to 1.0
    required property string icon

    readonly property real barWidth: 24
    readonly property real barHeight: 180
    readonly property real padding: Theme.spacingBase

    implicitWidth: mainColumn.implicitWidth + Theme.elevationMargin * 2
    implicitHeight: mainColumn.implicitHeight + Theme.elevationMargin * 2

    ColumnLayout {
        id: mainColumn
        anchors.centerIn: parent
        spacing: 0

        Rectangle {
            id: topSection
            color: Theme.alpha(Theme.hostSurface, 0.95)
            border.width: 1
            border.color: Theme.chipSurface

            topLeftRadius: Theme.radiusBase
            topRightRadius: Theme.radiusBase

            Layout.preferredWidth: root.barWidth + root.padding * 2
            Layout.preferredHeight: numberText.implicitHeight + root.padding + root.barHeight + root.padding

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.padding
                spacing: root.padding

                StyledText {
                    id: numberText
                    text: Math.round(root.value * 100)
                    font.pixelSize: Theme.fontSizeLarge
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                Rectangle {
                    id: barTrack
                    Layout.preferredWidth: 12
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.chipSurface
                    radius: 6

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

        Rectangle {
            id: iconSection
            color: Theme.primary

            bottomLeftRadius: Theme.radiusBase
            bottomRightRadius: Theme.radiusBase

            Layout.preferredWidth: root.barWidth + root.padding * 2
            Layout.preferredHeight: root.barWidth + root.padding * 2

            Icon {
                anchors.centerIn: parent
                text: root.icon
                size: Theme.iconSizeLarge
                color: Theme.hostSurface
            }
        }
    }
}
