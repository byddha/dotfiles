import QtQuick
import Quickshell
import "../../Config"
import "../../Services"

BarItem {
    id: root

    property CalendarPopout calendar: CalendarPopout {}

    readonly property var current: WeatherService.data.weather?.current ?? null
    readonly property string weatherGlyph: current ? WeatherService.glyphFromCode(current.weather_code, current.is_day === 1) : ""
    readonly property string temperature: current ? `${Math.round(current.temperature_2m)}°` : ""

    highlighted: calendar.visible
    tooltipTitle: calendar.visible ? "" : Qt.formatDate(clock.date, "dddd d MMMM")
    tooltipDetail: {
        const lines = [];
        if (current)
            lines.push(`${WeatherService.weatherDescriptionFromCode(current.weather_code)} · ${temperature} · feels like ${Math.round(current.apparent_temperature)}°`);
        lines.push("Click for calendar");
        return lines.join("\n");
    }

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        if (calendar.visible)
            calendar.hidePanel();
        else
            calendar.openFrom(root);
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    function lengthAt(level) {
        if (vertical)
            return padded((current ? BarLayout.iconSize + (level < 3 ? 2 + verticalTemperature.implicitHeight : 0) + 4 : 0) + verticalTime.implicitHeight);
        return padded((current ? BarLayout.iconSize + (level < 3 ? BarLayout.itemGap + temperatureText.implicitWidth : 0) + BarLayout.itemGap + 3 : 0) + time.implicitWidth);
    }

    // Horizontal: weather, then the time
    Row {
        visible: !root.vertical
        spacing: BarLayout.itemGap + 3

        Row {
            visible: root.current !== null
            anchors.verticalCenter: parent.verticalCenter
            spacing: BarLayout.itemGap

            BarIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.weatherGlyph
                color: Theme.alpha(Theme.textSecondary, BarLayout.weatherOpacity)
            }
            BarText {
                id: temperatureText

                visible: root.level < 3
                anchors.verticalCenter: parent.verticalCenter
                font.weight: Font.Medium
                color: Theme.alpha(Theme.textSecondary, BarLayout.weatherOpacity)
                text: root.temperature
            }
        }

        // The seconds are lighter, in weight and in color
        Row {
            id: time

            anchors.verticalCenter: parent.verticalCenter

            BarText {
                font.pixelSize: BarLayout.clockSize
                font.weight: Font.DemiBold
                text: Qt.formatTime(clock.date, "hh:mm")
            }
            BarText {
                font.pixelSize: BarLayout.clockSize
                font.weight: Font.Medium
                color: Theme.alpha(Theme.textSecondary, BarLayout.secondsOpacity)
                text: `:${Qt.formatTime(clock.date, "ss")}`
            }
        }
    }

    // Vertical: weather, then hours, minutes and seconds stacked
    Column {
        visible: root.vertical
        spacing: 4

        Column {
            visible: root.current !== null
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            BarIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.weatherGlyph
                color: Theme.alpha(Theme.textSecondary, BarLayout.weatherOpacity)
            }
            BarText {
                id: verticalTemperature

                visible: root.level < 3
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: BarLayout.captionSize
                font.weight: Font.DemiBold
                color: Theme.alpha(Theme.textSecondary, BarLayout.weatherOpacity)
                text: root.temperature
            }
        }

        Column {
            id: verticalTime

            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: ["hh", "mm", "ss"]

                BarText {
                    required property string modelData
                    required property int index

                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: BarLayout.clockSize
                    font.weight: index === 2 ? Font.Medium : Font.DemiBold
                    lineHeight: 1.2
                    color: index === 2 ? Theme.alpha(Theme.textSecondary, BarLayout.secondsOpacity) : Theme.textColor
                    text: Qt.formatTime(clock.date, modelData)
                }
            }
        }
    }
}
