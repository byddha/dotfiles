import QtQuick
import Quickshell
import "../../Config"
import "../../Services"

BarItem {
    id: root

    property CalendarPopout calendar: CalendarPopout {}

    readonly property var current: WeatherService.data.weather?.current ?? null
    readonly property string weatherGlyph: current ? WeatherService.glyphFromCode(current.weather_code, current.is_day !== 0) : ""
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

    // Horizontal: weather, then the time
    Row {
        visible: !root.vertical
        spacing: 10

        Row {
            visible: root.current !== null
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            BarIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.weatherGlyph
                color: Theme.alpha(Theme.textSecondary, 0.66)
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                role: "secondary"
                text: root.temperature
            }
        }

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 14
            font.weight: Font.DemiBold
            textFormat: Text.StyledText
            text: `${Qt.formatTime(clock.date, "hh:mm")}<font color="${Theme.alpha(Theme.textSecondary, 0.55)}">:${Qt.formatTime(clock.date, "ss")}</font>`
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
                color: Theme.alpha(Theme.textSecondary, 0.66)
            }
            BarText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "secondary"
                font.pixelSize: 11
                text: root.temperature
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: ["hh", "mm", "ss"]

                BarText {
                    required property string modelData
                    required property int index

                    anchors.horizontalCenter: parent.horizontalCenter
                    font.weight: Font.DemiBold
                    lineHeight: 1.2
                    color: index === 2 ? Theme.alpha(Theme.textSecondary, 0.55) : Theme.textColor
                    text: Qt.formatTime(clock.date, modelData)
                }
            }
        }
    }
}
