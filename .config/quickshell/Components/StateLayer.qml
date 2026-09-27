import QtQuick
import "../Config"

// Hover / pressed overlay, dropped into every button, tile and row (Material state layer)
Rectangle {
    id: root

    property bool hovered: false
    property bool pressed: false
    property bool onPrimary: false
    property real hoverOpacity: Theme.stateHover

    anchors.fill: parent
    radius: parent.radius ?? 0
    color: onPrimary ? Theme.primaryText : Theme.textColor
    opacity: pressed ? Theme.statePressed : hovered ? hoverOpacity : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }
}
