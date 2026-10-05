import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Config"

// [icon button] · slider · label. Above 1.0 (to > 1) is the boost zone; stepped sliders show a dot per level.
RowLayout {
    id: root

    property real value: 0.5
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property bool snapMode: false
    property string icon: ""
    property bool showMuteIcon: false
    property bool isMuted: false
    // Replaces the percentage, e.g. "2/3"
    property string labelText: ""
    property bool showLabel: true

    readonly property bool boosted: slider.value > 1.0
    readonly property real boostStart: slider.to > 1 ? 1.0 / slider.to : 1
    readonly property color accent: isMuted ? Theme.alpha(Theme.textSecondary, 0.38) : boosted ? Theme.accentOrange : Theme.primary

    signal moved(real value)
    signal iconClicked
    signal rightClicked

    spacing: 4
    implicitHeight: 36

    onValueChanged: {
        if (Math.abs(slider.value - value) > 0.001)
            slider.value = value;
    }

    IconButton {
        visible: root.icon !== ""
        icon: root.icon
        danger: root.isMuted && root.showMuteIcon
        onClicked: root.iconClicked()
        onRightClicked: root.rightClicked()
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        implicitHeight: 20
        padding: 0
        from: 0
        to: 1
        value: root.value
        snapMode: root.snapMode ? Slider.SnapAlways : Slider.NoSnap

        onMoved: root.moved(value)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: root.rightClicked()
        }

        background: Item {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 6

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Theme.chipSurface
            }

            // Boost zone
            Rectangle {
                visible: slider.to > 1
                x: root.boostStart * parent.width
                width: parent.width - x
                height: parent.height
                radius: 3
                color: Theme.alpha(Theme.accentOrange, 0.22)
            }

            Rectangle {
                width: Math.min(slider.visualPosition, root.boostStart) * parent.width
                height: parent.height
                radius: 3
                color: root.isMuted ? root.accent : Theme.primary

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            Rectangle {
                visible: slider.visualPosition > root.boostStart
                x: root.boostStart * parent.width
                width: (slider.visualPosition - root.boostStart) * parent.width
                height: parent.height
                radius: 3
                color: root.accent
            }

            // 100% tick
            Rectangle {
                visible: slider.to > 1
                x: root.boostStart * parent.width - 1
                y: parent.height / 2 - 6
                width: 2
                height: 12
                radius: 1
                color: Theme.alpha(Theme.outline, 0.35)
            }

            // One dot per level on stepped sliders
            Repeater {
                model: root.snapMode && slider.stepSize > 0 ? Math.round((slider.to - slider.from) / slider.stepSize) + 1 : 0

                Rectangle {
                    required property int index
                    readonly property real fraction: index * slider.stepSize / (slider.to - slider.from)
                    x: fraction * (parent.width - 4)
                    y: parent.height / 2 - 2
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.alpha(Theme.textSecondary, 0.5)
                }
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 16
            implicitHeight: 16
            radius: 8
            color: root.accent
            border.width: 3
            border.color: Theme.cardSurface

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }

    StyledText {
        visible: root.showLabel
        Layout.preferredWidth: 44
        horizontalAlignment: Text.AlignRight
        text: root.isMuted && root.showMuteIcon ? "Muted" : root.labelText !== "" ? root.labelText : Math.round(slider.value * 100) + "%"
        font.pixelSize: Theme.fontSizeTiny
        font.weight: Font.Normal
        color: root.isMuted && root.showMuteIcon ? Theme.accentRed : root.boosted ? Theme.accentOrange : Theme.textSecondary
    }
}
