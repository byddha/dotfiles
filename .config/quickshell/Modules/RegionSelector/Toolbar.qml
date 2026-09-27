import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services/UI"

Rectangle {
    id: root

    required property int action
    required property bool adjusting
    signal dismiss
    signal actionRequested(int newAction)
    signal cropRequested
    signal lensRequested
    signal ocrRequested        // English only
    signal ocrAllRequested     // All languages
    signal translateRequested  // OCR + Kagi Translate

    radius: Theme.radiusBase * 1.5
    color: Theme.alpha(Theme.colLayer1, 0.9)
    border.color: Theme.alpha(Theme.colLayer0Border, 0.5)
    border.width: 1

    implicitWidth: content.width + 12
    implicitHeight: content.height + 12

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 8

        // Segmented mode toggle
        Rectangle {
            id: segmentedControl
            Layout.preferredHeight: 36
            implicitWidth: segmentRow.width + 4
            radius: Theme.radiusBase
            color: Theme.alpha(Theme.colLayer0, 0.6)

            RowLayout {
                id: segmentRow
                anchors.centerIn: parent
                spacing: 2

                SegmentButton {
                    selected: root.action === RegionSelector.SnipAction.Copy
                    icon: Icons.screenshot
                    label: `<u>S</u>creenshot`
                    onClicked: root.actionRequested(RegionSelector.SnipAction.Copy)
                }

                SegmentButton {
                    selected: root.action === RegionSelector.SnipAction.Record
                    icon: Icons.record
                    label: `<u>R</u>ecord`
                    onClicked: root.actionRequested(RegionSelector.SnipAction.Record)
                }
            }
        }

        ActionButton {
            icon: Icons.fullscreen
            label: `<u>F</u>ull`
            labelFont.family: Theme.fontFamily
            onClicked: root.actionRequested(-1)  // -1 signals fullscreen
        }

        // Shrink to content
        ActionButton {
            active: root.adjusting
            icon: Icons.crop
            label: `<u>C</u>rop`
            labelFont.family: Theme.fontFamily
            onClicked: root.cropRequested()
        }

        // Google Lens visual search
        ActionButton {
            active: root.adjusting
            icon: Icons.lens
            label: `<u>L</u>ens`
            labelFont.family: Theme.fontFamily
            onClicked: root.lensRequested()
        }

        ActionButton {
            active: root.adjusting
            icon: Icons.ocr
            label: `<u>O</u>CR copy (En)`
            labelFont.family: Theme.fontFamily
            onClicked: root.ocrRequested()
        }

        // These two labels use the default font, not Theme.fontFamily
        ActionButton {
            active: root.adjusting
            icon: Icons.ocrAll
            label: `<u><font face="${Theme.fontFamilyIcons}">${Icons.keyShift}</font>O</u>CR copy (All)`
            onClicked: root.ocrAllRequested()
        }

        ActionButton {
            active: root.adjusting
            icon: Icons.translate
            label: `<u><font face="${Theme.fontFamilyIcons}">${Icons.keyCtrl}</font>O</u>CR + Translate`
            onClicked: root.translateRequested()
        }

        // Cancel button
        Rectangle {
            Layout.preferredWidth: cancelContent.width + 16
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: cancelMouse.containsMouse ? Theme.alpha(Theme.accentRed, 0.2) : Theme.alpha(Theme.colLayer0, 0.6)

            RowLayout {
                id: cancelContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: cancelMouse.containsMouse ? Theme.accentRed : Theme.textSecondary
                    text: Icons.cancel
                }
                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: cancelMouse.containsMouse ? Theme.accentRed : Theme.textSecondary
                    text: "Esc"
                }
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismiss()
            }
        }
    }

    component SegmentButton: Rectangle {
        id: segment

        required property bool selected
        property string icon
        property string label

        signal clicked

        Layout.preferredWidth: segmentContent.width + 20
        Layout.preferredHeight: 32
        radius: Theme.radiusBase - 2
        color: segment.selected ? Theme.primary : "transparent"

        RowLayout {
            id: segmentContent
            anchors.centerIn: parent
            spacing: 6

            Text {
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 14
                color: segment.selected ? Theme.primaryText : Theme.textSecondary
                text: segment.icon
            }
            Text {
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: segment.selected ? Theme.primaryText : Theme.textSecondary
                textFormat: Text.RichText
                text: segment.label
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: segment.clicked()
        }
    }

    // Inactive buttons stay hoverable and swallow clicks so a press doesn't
    // fall through and start a new selection, hence `active` instead of `enabled`.
    component ActionButton: Rectangle {
        id: button

        property bool active: true
        property string icon
        property string label
        property alias labelFont: labelText.font

        signal clicked

        Layout.preferredWidth: buttonContent.width + 16
        Layout.preferredHeight: 36
        radius: Theme.radiusBase
        color: buttonMouse.containsMouse && button.active ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)
        opacity: button.active ? 1.0 : 0.4

        RowLayout {
            id: buttonContent
            anchors.centerIn: parent
            spacing: 6

            Text {
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 16
                color: button.active ? Theme.textColor : Theme.textSecondary
                text: button.icon
            }
            Text {
                id: labelText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.textSecondary
                textFormat: Text.RichText
                text: button.label
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: button.active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (button.active)
                button.clicked()
        }
    }
}
