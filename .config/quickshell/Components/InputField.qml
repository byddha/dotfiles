import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Config"

Rectangle {
    id: root

    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias echoMode: field.echoMode
    property string icon: ""
    property bool error: false
    // Inside an expanded row the row already has the surface_container_high fill
    property bool inRow: false
    // When false, Esc also reaches the popout and closes it
    property bool consumeEscape: false

    signal accepted
    signal escapePressed

    function focusInput() {
        field.forceActiveFocus();
    }

    implicitHeight: 36
    Layout.minimumHeight: implicitHeight
    radius: Theme.radiusBase
    color: inRow ? Theme.hostSurface : Theme.chipSurface
    border.width: 1
    border.color: error ? Theme.accentRed : field.activeFocus ? Theme.primary : "transparent"

    Behavior on border.color {
        ColorAnimation {
            duration: 150
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: Theme.spacingBase

        Icon {
            visible: root.icon !== ""
            text: root.icon
            size: Theme.iconSizeSmall
            color: Theme.textSecondary
        }

        TextField {
            id: field
            Layout.fillWidth: true
            Layout.fillHeight: true
            leftPadding: 0
            rightPadding: 0
            verticalAlignment: TextInput.AlignVCenter
            font.family: Theme.fontUi
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textColor
            placeholderTextColor: Theme.alpha(Theme.textSecondary, 0.6)
            selectByMouse: true
            background: null

            onAccepted: root.accepted()
            Keys.onEscapePressed: event => {
                root.escapePressed();
                event.accepted = root.consumeEscape;
            }
        }
    }
}
