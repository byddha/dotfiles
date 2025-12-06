import QtQuick
import "../../Config"
import "../../Services"
import "../../Utils"

Item {
    id: root

    required property var game

    property bool isSelected: false

    // Card container
    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.margins: Theme.spacingSmall
        radius: Theme.radiusBase
        color: "transparent"

        border.width: isSelected ? 3 : 0
        border.color: Theme.primary

        // Inner content (clipped)
        Rectangle {
            id: cardContent
            anchors.fill: parent
            anchors.margins: isSelected ? 3 : 0
            radius: Theme.radiusBase - 2
            color: Theme.colLayer1
            clip: true
        }

        // Cover art
        Image {
            id: coverImage
            anchors.fill: cardContent
            source: root.game?.coverArt ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: status === Image.Ready
        }

        // Fallback placeholder
        Rectangle {
            anchors.fill: cardContent
            color: Theme.colLayer2
            visible: coverImage.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text: root.game?.name?.charAt(0)?.toUpperCase() ?? "?"
                font.family: Theme.fontFamily
                font.pixelSize: 48
                font.weight: Font.Bold
                color: Theme.textSecondary
            }
        }

        // Bottom gradient overlay for title
        Rectangle {
            anchors.left: cardContent.left
            anchors.right: cardContent.right
            anchors.bottom: cardContent.bottom
            height: 80

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.colLayer0, 0.9) }
            }
        }

        // Game title
        Text {
            anchors.left: cardContent.left
            anchors.right: cardContent.right
            anchors.bottom: cardContent.bottom
            anchors.margins: 10

            text: root.game?.name ?? "Unknown"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.textColor
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
        }

        // Platform badge
        Rectangle {
            anchors.top: cardContent.top
            anchors.right: cardContent.right
            anchors.margins: 8
            width: platformIcon.width + 12
            height: platformIcon.height + 8
            radius: Theme.radiusSmall
            color: Theme.alpha(Theme.colLayer0, 0.8)

            Text {
                id: platformIcon
                anchors.centerIn: parent
                text: ""  // Steam icon from Nerd Font
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 14
                color: Theme.textColor
            }
        }

        // Selection scale effect - instant shrink, animated grow
        scale: isSelected ? 1.2 : 0.85

        Behavior on scale {
            enabled: !isSelected  // Only animate when becoming selected (checked before change)
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
    }
}
