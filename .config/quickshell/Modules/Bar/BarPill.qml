import QtQuick
import "../../Components"

// Background, hover highlight and pointer handling shared by the simple bar buttons.
// Children are placed freely; each button sizes itself.
Rectangle {
    id: root

    property bool highlightOnHover: true
    property Tooltip tooltip: null
    property alias acceptedButtons: mouseArea.acceptedButtons
    property alias cursorShape: mouseArea.cursorShape
    readonly property alias hovered: mouseArea.containsMouse
    readonly property alias mouseArea: mouseArea

    signal clicked(var mouse)

    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.tooltip?.show()
        onExited: root.tooltip?.hide()
        onClicked: mouse => root.clicked(mouse)
    }

    states: State {
        name: "hovered"
        when: root.hovered && root.highlightOnHover
        PropertyChanges {
            root.color: BarStyle.buttonBackgroundHover
        }
    }

    transitions: Transition {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }
}
