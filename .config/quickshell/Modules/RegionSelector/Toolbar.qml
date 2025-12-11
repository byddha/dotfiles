import QtQuick
import QtQuick.Layouts
import "../../Config"

Rectangle {
    id: root

    required property int action
    required property bool adjusting
    signal dismiss()
    signal actionRequested(int newAction)
    signal cropRequested()

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

                // Screenshot button
                Rectangle {
                    Layout.preferredWidth: screenshotContent.width + 20
                    Layout.preferredHeight: 32
                    radius: Theme.radiusBase - 2
                    color: root.action === RegionSelector.SnipAction.Copy ? Theme.primary : "transparent"

                    RowLayout {
                        id: screenshotContent
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            font.family: Theme.fontFamilyIcons
                            font.pixelSize: 14
                            color: root.action === RegionSelector.SnipAction.Copy ? Theme.primaryText : Theme.textSecondary
                            text: "󰆏"
                        }
                        Text {
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: root.action === RegionSelector.SnipAction.Copy ? Theme.primaryText : Theme.textSecondary
                            textFormat: Text.RichText
                            text: `<u>S</u>creenshot`
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionRequested(RegionSelector.SnipAction.Copy)
                    }
                }

                // Record button
                Rectangle {
                    Layout.preferredWidth: recordContent.width + 20
                    Layout.preferredHeight: 32
                    radius: Theme.radiusBase - 2
                    color: root.action === RegionSelector.SnipAction.Record ? Theme.primary : "transparent"

                    RowLayout {
                        id: recordContent
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            font.family: Theme.fontFamilyIcons
                            font.pixelSize: 14
                            color: root.action === RegionSelector.SnipAction.Record ? Theme.primaryText : Theme.textSecondary
                            text: "󰻃"
                        }
                        Text {
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: root.action === RegionSelector.SnipAction.Record ? Theme.primaryText : Theme.textSecondary
                            textFormat: Text.RichText
                            text: `<u>R</u>ecord`
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionRequested(RegionSelector.SnipAction.Record)
                    }
                }
            }
        }

        // Fullscreen button
        Rectangle {
            Layout.preferredWidth: fullscreenContent.width + 16
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: fullscreenMouse.containsMouse ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)

            RowLayout {
                id: fullscreenContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: Theme.textColor
                    text: "󰍉"
                }
                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                    textFormat: Text.RichText
                    text: `<u>F</u>ull`
                }
            }

            MouseArea {
                id: fullscreenMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionRequested(-1)  // -1 signals fullscreen
            }
        }

        // Crop button (shrink to content)
        Rectangle {
            Layout.preferredWidth: cropContent.width + 16
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: cropMouse.containsMouse && root.adjusting ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)
            opacity: root.adjusting ? 1.0 : 0.4

            RowLayout {
                id: cropContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: root.adjusting ? Theme.textColor : Theme.textSecondary
                    text: "󰆞"
                }
                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.adjusting ? Theme.textSecondary : Theme.textSecondary
                    textFormat: Text.RichText
                    text: `<u>C</u>rop`
                }
            }

            MouseArea {
                id: cropMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.adjusting ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.adjusting) root.cropRequested()
            }
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
                    text: "󰅖"
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
}
