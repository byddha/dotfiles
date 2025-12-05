import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Config"

RowLayout {
    id: root

    property real value: 0.5
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property bool snapMode: false  // Enable snapping to stepSize
    property string icon: ""
    property int iconSize: Theme.iconSize
    property bool showMuteIcon: false
    property bool isMuted: false

    signal moved(real value)
    signal iconClicked
    signal rightClicked

    spacing: Theme.spacingBase

    onValueChanged: {
        if (Math.abs(slider.value - value) > 0.001) {
            slider.value = value;
        }
    }

    // Icon
    Text {
        id: iconText
        text: root.icon
        font.family: Theme.fontFamilyIcons
        font.pixelSize: root.iconSize
        color: root.isMuted ? Theme.textSecondary : Theme.textColor
        visible: root.icon !== ""

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: Theme.iconSize
        Layout.preferredHeight: Theme.iconSize

        MouseArea {
            anchors.fill: parent
            enabled: root.showMuteIcon
            cursorShape: root.showMuteIcon ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.iconClicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    // Slider with hover percentage
    Item {
        Layout.fillWidth: true
        implicitHeight: slider.implicitHeight

        Slider {
            id: slider
            anchors.fill: parent

            from: 0
            to: 1
            snapMode: root.snapMode ? Slider.SnapAlways : Slider.NoSnap

            onMoved: {
                root.moved(value);
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: root.rightClicked()
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: slider.availableWidth
                height: implicitHeight
                radius: 2
                color: Theme.colLayer2

                // Normal range (0-100%)
                Rectangle {
                    width: Math.min(slider.visualPosition, (1.0 / slider.to)) * parent.width
                    height: parent.height
                    color: root.isMuted ? Theme.textSecondary : Theme.primary
                    radius: 2

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animation.elementMoveFast.duration
                            easing.type: Theme.animation.elementMoveFast.type
                            easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                // Boosted range (above 100%)
                Rectangle {
                    x: (1.0 / slider.to) * parent.width
                    width: Math.max(0, (slider.visualPosition - (1.0 / slider.to))) * parent.width
                    height: parent.height
                    color: root.isMuted ? Theme.textSecondary : Theme.accentOrange
                    radius: 2
                    visible: slider.value > 1.0

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animation.elementMoveFast.duration
                            easing.type: Theme.animation.elementMoveFast.type
                            easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: slider.pressed ? Theme.primary : Theme.colLayer1
                border.color: root.isMuted ? Theme.textSecondary : Theme.primary
                border.width: 2

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                // Elevation when pressed
                layer.enabled: slider.pressed
                layer.effect: Item {
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        color: Theme.primary
                        opacity: 0.2
                    }
                }
            }
        }
    }

    // Value label
    Text {
        id: valueLabel
        text: Math.round(slider.value * 100) + "%"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.textSecondary

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 35
    }
}
