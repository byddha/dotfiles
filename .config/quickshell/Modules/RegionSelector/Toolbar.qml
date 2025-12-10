import QtQuick
import QtQuick.Layouts
import "../../Config"

Rectangle {
    id: root

    required property int action
    signal dismiss()
    signal actionRequested(int newAction)

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
                            text: "Screenshot"
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
                            text: "Record"
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
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: fullscreenMouse.containsMouse ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 18
                color: Theme.textColor
                text: "󰍉"
            }

            MouseArea {
                id: fullscreenMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionRequested(-1)  // -1 signals fullscreen
            }
        }

        // Cancel button
        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: cancelMouse.containsMouse ? Theme.alpha(Theme.accentRed, 0.2) : Theme.alpha(Theme.colLayer0, 0.6)

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 18
                color: cancelMouse.containsMouse ? Theme.accentRed : Theme.textSecondary
                text: "󰅖"
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
