import QtQuick
import "../Config"
import "../Services"

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    // A live capture uses the error fill so it does not look like a normal toggle
    property bool danger: false
    // Tiles that open something carry a chevron; it points up while the thing is open
    property bool hasMenu: false
    property bool menuOpen: false

    readonly property color fill: !active ? Theme.colLayer2 : danger ? Theme.accentRed : Theme.primary
    readonly property color glyph: !active ? Theme.textSecondary : danger ? Theme.accentRedText : Theme.primaryText

    signal clicked

    implicitWidth: 64
    implicitHeight: 64
    radius: Theme.radiusWindow
    color: fill

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    StateLayer {
        onPrimary: root.active
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.fontFamilyGlyphs
        font.pixelSize: 20
        color: root.glyph
    }

    Text {
        visible: root.hasMenu
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 6
        anchors.bottomMargin: 6
        text: root.menuOpen ? Icons.chevronUp : Icons.chevronDown
        font.family: Theme.fontFamilyGlyphs
        font.pixelSize: 12
        color: root.glyph
    }

    Tooltip {
        id: tooltip
        target: root
        text: root.label
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tooltip.show()
        onExited: tooltip.hide()
        onClicked: {
            tooltip.hide();
            root.clicked();
        }
    }
}
