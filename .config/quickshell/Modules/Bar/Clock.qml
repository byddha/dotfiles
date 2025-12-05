import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Utils"
import "Popups"

/**
 * Clock - Clock button with calendar popup (follows Tray pattern)
 *
 * Uses PopupWindow with HyprlandFocusGrab for click-outside-to-close.
 * Signal chain ensures focus grab is activated AFTER popup is shown.
 */
Rectangle {
    id: clock

    required property var barWindow  // Need screen reference from bar

    property var now: new Date()

    width: clockRow.implicitWidth + BarStyle.spacing * 2
    height: BarStyle.buttonSize
    color: BarStyle.buttonBackground
    radius: BarStyle.buttonRadius

    // Update time every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }

    // Track active popup for focus management (same as Tray)
    property var activePopup: null

    // Focus grab - starts INACTIVE (same as Tray pattern)
    HyprlandFocusGrab {
        id: focusGrab
        active: false  // NOT bound to visibility!
        windows: clock.activePopup ? [clock.activePopup] : []
        onCleared: {
            Logger.info("Focus cleared (clicked outside or Escape pressed)")
            if (clock.activePopup) {
                clock.activePopup.hidePanel()
                clock.releaseFocus()
            }
        }
    }

    function setActivePopupAndGrabFocus(popupWindow) {
        clock.activePopup = popupWindow
        focusGrab.active = true
        Logger.info("Focus grabbed for calendar popup")
    }

    function releaseFocus() {
        focusGrab.active = false
        clock.activePopup = null
        popupLoader.active = false
        Settings.calendarPanelVisible = false
        Logger.info("Focus released")
    }

    function showCalendarPopup() {
        popupLoader.active = true  // Create fresh popup instance
    }

    // CalendarPopup Loader - Recreates popup on each open (same as Tray)
    Loader {
        id: popupLoader
        active: false  // NOT bound to Settings!

        sourceComponent: CalendarPopup {
            Component.onCompleted: {
                // Show popup immediately when created
                showPanel(clock)
            }

            onPanelOpened: window => clock.setActivePopupAndGrabFocus(window)
            onPanelClosed: clock.releaseFocus()
        }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: BarStyle.spacing / 2

        Text {
            id: weatherIcon
            visible: WeatherService.weatherReady
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.weatherReady ? WeatherService.weatherSymbolFromCode(WeatherService.data.weather.current.weather_code) : ""
            font.family: Theme.fontFamilyIcons
            font.pixelSize: BarStyle.iconSize
            color: Theme.primary
        }

        Text {
            visible: WeatherService.weatherReady
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(WeatherService.data.weather?.current?.temperature_2m ?? 0) + "° /"
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textSecondaryColor
        }

        Text {
            id: clockText
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.now, "hh:mm:ss")
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.textSize
            font.weight: BarStyle.textWeight
            color: BarStyle.textColor
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (Settings.calendarPanelVisible) {
                // Close
                if (clock.activePopup) {
                    clock.activePopup.hidePanel()
                }
            } else {
                // Open
                Settings.calendarPanelVisible = true
                clock.showCalendarPopup()
            }
            Logger.info("Calendar panel toggled: " + Settings.calendarPanelVisible)
        }
    }

    states: State {
        name: "hovered"
        when: mouseArea.containsMouse
        PropertyChanges {
            target: clock
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
