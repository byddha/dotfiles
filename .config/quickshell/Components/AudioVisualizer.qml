import QtQuick
import "../Config"

Item {
    id: root

    property list<real> values: []
    property bool live: true
    readonly property real maxValue: 1000
    readonly property color barColor: Theme.primary
    readonly property int barCount: 8
    readonly property real barSpacing: 3
    readonly property real minBarHeight: 2

    Row {
        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index

                width: (root.width - (root.barCount - 1) * root.barSpacing) / root.barCount
                height: root.live ? Math.max(root.minBarHeight, (root.values[index] ?? 0) / root.maxValue * root.height) : root.minBarHeight
                anchors.bottom: parent.bottom
                radius: 2
                color: root.barColor
                opacity: 0.8

                Behavior on height {
                    NumberAnimation {
                        duration: 50
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
