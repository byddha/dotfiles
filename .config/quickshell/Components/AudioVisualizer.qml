import QtQuick
import "../Config"

Item {
    id: root

    property list<real> values: []
    property bool live: true
    property real maxValue: 1000
    property color barColor: Theme.primary
    property int barCount: 8
    property real barSpacing: 3
    property real minBarHeight: 2

    Row {
        id: barsRow
        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar
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
