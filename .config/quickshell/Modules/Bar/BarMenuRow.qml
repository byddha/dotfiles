import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../Config"
import "../../Services"

// One row of a menu that opens from the bar (power, tray)
Rectangle {
    id: row

    // A Lucide glyph, or an image for app-provided icons
    property string icon: ""
    property string iconSource: ""
    property string label
    property string keys: ""
    property bool danger: false
    property bool submenu: false
    // Shown as hovered, e.g. the armed Shut down
    property bool filled: false
    readonly property bool lit: area.containsMouse || filled

    signal activated

    Layout.fillWidth: true
    implicitWidth: content.implicitWidth + 20
    implicitHeight: 34
    radius: BarLayout.itemRadius
    clip: true
    opacity: enabled ? 1 : 0.45
    color: area.pressed ? (danger ? Qt.darker(Theme.accentRed, 1.15) : Theme.colLayer3) : lit ? (danger ? Theme.accentRed : Theme.colLayer2) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        BarIcon {
            visible: row.icon !== ""
            text: row.icon
            color: row.danger ? (row.lit ? Theme.textColor : Theme.accentRed) : Theme.alpha(Theme.textSecondary, BarLayout.secondaryOpacity)
        }
        IconImage {
            visible: row.icon === "" && row.iconSource !== ""
            implicitSize: BarLayout.iconSize
            source: row.iconSource
        }
        BarText {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
        }
        BarKeycap {
            visible: row.keys !== ""
            text: row.keys
        }
        BarIcon {
            visible: row.submenu
            text: Lucide.chevronRight
            color: Theme.alpha(Theme.textSecondary, BarLayout.secondaryOpacity)
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.activated()
    }
}
