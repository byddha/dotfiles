import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services/UI"

Rectangle {
    id: root

    required property int action
    required property bool adjusting
    signal dismiss()
    signal actionRequested(int newAction)
    signal cropRequested()
    signal lensRequested()
    signal ocrRequested()        // English only
    signal ocrAllRequested()     // All languages
    signal translateRequested()  // OCR + Kagi Translate

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
                            text: Icons.screenshot
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
                            text: Icons.record
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
                    text: Icons.fullscreen
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
                    text: Icons.crop
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

        // Lens button (Google Lens visual search)
        Rectangle {
            Layout.preferredWidth: lensContent.width + 16
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: lensMouse.containsMouse && root.adjusting ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)
            opacity: root.adjusting ? 1.0 : 0.4

            RowLayout {
                id: lensContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: root.adjusting ? Theme.textColor : Theme.textSecondary
                    text: Icons.lens
                }
                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.adjusting ? Theme.textSecondary : Theme.textSecondary
                    textFormat: Text.RichText
                    text: `<u>L</u>ens`
                }
            }

            MouseArea {
                id: lensMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.adjusting ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.adjusting) root.lensRequested()
            }
        }

        // Text button (OCR English)
        Rectangle {
            Layout.preferredWidth: textContent.width + 16
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: textMouse.containsMouse && root.adjusting ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)
            opacity: root.adjusting ? 1.0 : 0.4

            RowLayout {
                id: textContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: root.adjusting ? Theme.textColor : Theme.textSecondary
                    text: Icons.ocr
                }
                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.adjusting ? Theme.textSecondary : Theme.textSecondary
                    textFormat: Text.RichText
                    text: `<u>T</u>ext`
                }
            }

            MouseArea {
                id: textMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.adjusting ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.adjusting) root.ocrRequested()
            }
        }

        // Text+ button (OCR All Languages)
        Rectangle {
            Layout.preferredWidth: textPlusContent.width + 16
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: textPlusMouse.containsMouse && root.adjusting ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)
            opacity: root.adjusting ? 1.0 : 0.4

            RowLayout {
                id: textPlusContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: root.adjusting ? Theme.textColor : Theme.textSecondary
                    text: Icons.ocrAll
                }
                Text {
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.adjusting ? Theme.textSecondary : Theme.textSecondary
                    textFormat: Text.RichText
                    text: `<u><font face="${Theme.fontFamilyIcons}">${Icons.keyShift}</font>T</u>ext all langs`
                }
            }

            MouseArea {
                id: textPlusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.adjusting ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.adjusting) root.ocrAllRequested()
            }
        }

        // Translate button (OCR + Kagi Translate)
        Rectangle {
            Layout.preferredWidth: translateContent.width + 16
            Layout.preferredHeight: 36
            radius: Theme.radiusBase
            color: translateMouse.containsMouse && root.adjusting ? Theme.alpha(Theme.colLayer2, 0.8) : Theme.alpha(Theme.colLayer0, 0.6)
            opacity: root.adjusting ? 1.0 : 0.4

            RowLayout {
                id: translateContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 16
                    color: root.adjusting ? Theme.textColor : Theme.textSecondary
                    text: Icons.translate
                }
                Text {
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: root.adjusting ? Theme.textSecondary : Theme.textSecondary
                    textFormat: Text.RichText
                    text: `<u><font face="${Theme.fontFamilyIcons}">${Icons.keyCtrl}</font>T</u>ranslate`
                }
            }

            MouseArea {
                id: translateMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.adjusting ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.adjusting) root.translateRequested()
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
}
