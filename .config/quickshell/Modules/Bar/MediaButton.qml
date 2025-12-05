import QtQuick
import Quickshell.Services.Mpris
import "../../Config"
import "../../Services"
import "../../Components"
import "../../Utils"
import "Popups"

Rectangle {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool playerAvailable: MprisController.stableHasPlayer
    readonly property int textWidth: 120

    // Sticky hover to prevent flicker during track changes
    property bool isHovered: false
    property bool inTrackTransition: false

    Timer {
        id: hoverDebounceTimer
        interval: 500
        onTriggered: root.isHovered = mouseArea.containsMouse
    }

    Timer {
        id: trackTransitionTimer
        interval: 300
        onTriggered: root.inTrackTransition = false
    }

    // Detect track changes to enable debounce only during transitions
    Connections {
        target: MprisController
        function onStableTrackTitleChanged() {
            root.inTrackTransition = true;
            trackTransitionTimer.restart();
        }
    }

    width: playerAvailable ? contentRow.implicitWidth + BarStyle.spacing * 2 : 0
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius
    clip: true
    visible: playerAvailable

    Behavior on width {
        NumberAnimation {
            duration: 50
            easing.type: Easing.OutQuad
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: contentRow
        anchors.left: parent.left
        anchors.leftMargin: BarStyle.spacing
        anchors.verticalCenter: parent.verticalCenter
        spacing: BarStyle.spacing / 2
        height: parent.height

        // Music icon
        Text {
            id: musicIcon
            text: Icons.music
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.iconSize
            color: Theme.primary
            height: parent.height
            verticalAlignment: Text.AlignVCenter
        }

        // Scrolling text container
        Rectangle {
            id: textContainer
            width: root.textWidth
            height: parent.height
            color: "transparent"
            clip: true
            visible: root.playerAvailable

            property string displayText: {
                const title = MprisController.stableTrackTitle;
                const artist = MprisController.stableTrackArtist;
                if (!title)
                    return "";
                return artist.length > 0 ? title + " - " + artist : title;
            }

            Text {
                id: mediaText
                property bool needsScrolling: implicitWidth > textContainer.width
                property real scrollOffset: 0

                anchors.verticalCenter: parent.verticalCenter
                text: textContainer.displayText
                font.family: BarStyle.textFont
                font.pixelSize: BarStyle.textSize
                font.weight: BarStyle.textWeight
                color: BarStyle.textColor
                wrapMode: Text.NoWrap
                x: needsScrolling ? -scrollOffset : 0

                onTextChanged: {
                    scrollOffset = 0;
                    scrollAnimation.restart();
                }

                SequentialAnimation {
                    id: scrollAnimation
                    running: mediaText.needsScrolling && textContainer.visible
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: 2000
                    }

                    NumberAnimation {
                        target: mediaText
                        property: "scrollOffset"
                        from: 0
                        to: mediaText.implicitWidth - textContainer.width + 5
                        duration: Math.max(1000, (mediaText.implicitWidth - textContainer.width + 5) * 60)
                        easing.type: Easing.Linear
                    }

                    PauseAnimation {
                        duration: 2000
                    }

                    NumberAnimation {
                        target: mediaText
                        property: "scrollOffset"
                        to: 0
                        duration: Math.max(1000, (mediaText.implicitWidth - textContainer.width + 5) * 60)
                        easing.type: Easing.Linear
                    }
                }
            }
        }

        // Seekbar
        Seekbar {
            id: seekbar
            width: 80
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            activePlayer: root.activePlayer
            visible: root.playerAvailable && MprisController.stableTrackLength > 0
        }

        // Previous button
        Rectangle {
            width: root.isHovered ? 20 : 0
            height: 20
            radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: prevArea.containsMouse ? BarStyle.buttonBackgroundHover : "transparent"
            visible: root.playerAvailable
            opacity: MprisController.stableCanGoPrevious ? 1 : 0.3
            clip: true

            Text {
                anchors.centerIn: parent
                text: Icons.skipPrevious
                font.family: BarStyle.iconFont
                font.pixelSize: 14
                color: BarStyle.iconColor
            }

            MouseArea {
                id: prevArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.playerAvailable && MprisController.stableCanGoPrevious && root.isHovered
                onClicked: {
                    if (activePlayer)
                        activePlayer.previous();
                }
            }
        }

        // Play/Pause button
        Rectangle {
            width: root.isHovered ? 24 : 0
            height: 24
            radius: 12
            anchors.verticalCenter: parent.verticalCenter
            color: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? Theme.primary : BarStyle.buttonBackgroundHover
            visible: root.playerAvailable
            opacity: activePlayer ? 1 : 0.3
            clip: true

            Text {
                anchors.centerIn: parent
                text: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? Icons.pause : Icons.play
                font.family: BarStyle.iconFont
                font.pixelSize: 14
                color: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? Theme.colLayer0 : Theme.primary
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.playerAvailable && root.isHovered
                onClicked: {
                    if (activePlayer)
                        activePlayer.togglePlaying();
                }
            }
        }

        // Next button
        Rectangle {
            width: root.isHovered ? 20 : 0
            height: 20
            radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: nextArea.containsMouse ? BarStyle.buttonBackgroundHover : "transparent"
            visible: root.playerAvailable
            opacity: MprisController.stableCanGoNext ? 1 : 0.3
            clip: true

            Text {
                anchors.centerIn: parent
                text: Icons.skipNext
                font.family: BarStyle.iconFont
                font.pixelSize: 14
                color: BarStyle.iconColor
            }

            MouseArea {
                id: nextArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.playerAvailable && MprisController.stableCanGoNext && root.isHovered
                onClicked: {
                    if (activePlayer)
                        activePlayer.next();
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true

        onContainsMouseChanged: {
            if (containsMouse) {
                hoverDebounceTimer.stop();
                root.isHovered = true;
            } else {
                // Only debounce during track transitions, otherwise exit immediately
                if (root.inTrackTransition) {
                    hoverDebounceTimer.restart();
                } else {
                    root.isHovered = false;
                }
            }
        }

        onWheel: wheel => {
            wheel.accepted = true;

            // Scroll to switch between players
            if (wheel.angleDelta.y > 0) {
                MprisController.previousPlayer();
            } else {
                MprisController.nextPlayer();
            }
        }
    }

    // Hover popup
    Loader {
        id: popupLoader
        active: root.isHovered && playerAvailable
        sourceComponent: MediaPopup {
            activePlayer: root.activePlayer
            anchorItem: root
        }
    }

    states: State {
        name: "hovered"
        when: root.isHovered
        PropertyChanges {
            target: root
            color: BarStyle.buttonBackgroundHover
        }
    }

    transitions: Transition {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }
}
