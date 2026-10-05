import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../Config"
import "../Services"

// One row of a menu: the bar's power and tray menus, and the power menu of the lock and the greeter
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
    radius: Theme.radiusBase
    clip: true
    opacity: enabled ? 1 : 0.45
    color: area.pressed ? (danger ? Qt.darker(Theme.accentRed, 1.15) : Theme.chipSurfaceNested) : lit ? (danger ? Theme.accentRed : Theme.chipSurface) : "transparent"

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

        Icon {
            visible: row.icon !== ""
            text: row.icon
            color: row.danger ? (row.lit ? Theme.textColor : Theme.accentRed) : Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
        }
        IconImage {
            visible: row.icon === "" && row.iconSource !== ""
            implicitSize: Theme.iconSize
            source: row.iconSource
        }
        StyledText {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
        }
        Keycap {
            visible: row.keys !== ""
            text: row.keys
        }
        Icon {
            visible: row.submenu
            text: Lucide.chevronRight
            color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.activated()
    }
}
