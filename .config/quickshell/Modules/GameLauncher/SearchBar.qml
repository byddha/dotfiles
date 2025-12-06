import QtQuick
import QtQuick.Controls
import "../../Config"
import "../../Services"

Rectangle {
    id: root

    // Navigation signals
    signal navigateLeft
    signal navigateRight
    signal activateSelected

    height: 36
    radius: Theme.radiusBase
    color: Theme.colLayer1
    border.width: searchInput.activeFocus ? 2 : 1
    border.color: searchInput.activeFocus ? Theme.primary : Theme.colLayer2

    Behavior on border.color {
        ColorAnimation {
            duration: 150
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: Theme.spacingBase
        spacing: Theme.spacingBase

        // Search icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""  // Search icon from Nerd Font
            font.family: Theme.fontFamilyIcons
            font.pixelSize: 14
            color: Theme.textSecondary
        }

        // Text input
        TextInput {
            id: searchInput
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 30

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textColor
            selectionColor: Theme.primary
            selectedTextColor: Theme.primaryText

            // Placeholder
            Text {
                anchors.fill: parent
                text: "Search games..."
                font: parent.font
                color: Theme.textSecondary
                visible: !parent.text && !parent.activeFocus
            }

            onTextChanged: {
                GameService.searchQuery = text;
            }

            // Keyboard navigation
            Keys.onEscapePressed: {
                if (text) {
                    text = "";
                } else {
                    Settings.gameLauncherVisible = false;
                }
            }

            Keys.onLeftPressed: root.navigateLeft()
            Keys.onRightPressed: root.navigateRight()
            Keys.onReturnPressed: root.activateSelected()
            Keys.onEnterPressed: root.activateSelected()
        }

        // Clear button
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""  // Close icon
            font.family: Theme.fontFamilyIcons
            font.pixelSize: 12
            color: Theme.textSecondary
            visible: searchInput.text.length > 0

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: searchInput.text = ""
            }
        }
    }

    // Auto-focus when component loads (which happens when launcher opens)
    Component.onCompleted: {
        Qt.callLater(() => searchInput.forceActiveFocus());
    }
}
