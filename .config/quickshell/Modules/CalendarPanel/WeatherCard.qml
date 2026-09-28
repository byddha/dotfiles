pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services"
import "../../Components"

// Now, the next 8 hours and the next 5 days. While the first data loads the card keeps its size,
// so the popout does not jump when it arrives.
Card {
    id: root

    readonly property bool ready: WeatherService.weatherReady
    readonly property var weather: WeatherService.data.weather
    readonly property var current: weather?.current ?? null
    // The hourly slot of the current hour
    readonly property int hourIndex: {
        const times = weather?.hourly?.time ?? [];
        const now = new Date();
        return Math.max(0, times.findIndex(t => {
            const date = new Date(t);
            return date.getDate() === now.getDate() && date.getHours() >= now.getHours();
        }));
    }
    readonly property var hours: {
        const hourly = weather?.hourly;
        if (!hourly)
            return [];
        return hourly.time.slice(hourIndex, hourIndex + 9).map((time, i) => ({
                    "label": i === 0 ? "Now" : Qt.formatTime(new Date(time), "HH"),
                    "temperature": hourly.temperature_2m[hourIndex + i]
                }));
    }
    readonly property var days: {
        const daily = weather?.daily;
        if (!daily)
            return [];
        return daily.time.slice(0, 5).map((time, i) => ({
                    "label": i === 0 ? "Today" : Qt.formatDate(new Date(time.replace(/-/g, "/")), "ddd"),
                    "code": daily.weather_code[i],
                    "min": Math.round(daily.temperature_2m_min[i]),
                    "max": Math.round(daily.temperature_2m_max[i])
                }));
    }
    // The range bars share the scale of the whole 5 days
    readonly property int weekMin: Math.min(...days.map(day => day.min))
    readonly property int weekMax: Math.max(...days.map(day => day.max))

    padding: Theme.spacingLarge

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: body.implicitHeight

        ColumnLayout {
            id: body

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
            opacity: root.ready ? 1 : 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Icon {
                    size: Theme.iconSizeSmall
                    text: Lucide.mapPin
                    color: Theme.alpha(Theme.textSecondary, Theme.tertiaryOpacity)
                }
                StyledText {
                    Layout.fillWidth: true
                    role: "tertiary"
                    text: WeatherService.location
                    font.pixelSize: Theme.fontSizeTiny
                }
                StyledText {
                    role: "tertiary"
                    text: `Open-Meteo · ${Qt.formatTime(new Date(WeatherService.data.weatherLastFetch * 1000), "HH:mm")}`
                    font.pixelSize: Theme.fontSizeTiny
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingBase
                spacing: Theme.spacingLarge

                StyledText {
                    text: `${Math.round(root.current?.temperature_2m ?? 0)}°`
                    font.pixelSize: Theme.fontSizeDisplay
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: Theme.spacingBase

                        Icon {
                            size: Theme.iconSizeLarge
                            text: root.current ? WeatherService.glyphFromCode(root.current.weather_code, root.current.is_day === 1) : ""
                            color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
                        }
                        StyledText {
                            text: root.current ? WeatherService.weatherDescriptionFromCode(root.current.weather_code) : ""
                        }
                    }
                    StyledText {
                        role: "secondary"
                        text: `Feels like ${Math.round(root.current?.apparent_temperature ?? 0)}°`
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            Row {
                Layout.topMargin: Theme.spacingBase
                spacing: Theme.spacingBase

                Chip {
                    icon: Lucide.droplets
                    text: `${root.current?.relative_humidity_2m ?? 0}%`
                }
                Chip {
                    icon: Lucide.wind
                    text: `${Math.round(root.current?.wind_speed_10m ?? 0)} km/h`
                }
                Chip {
                    icon: Lucide.umbrella
                    text: `${root.weather?.hourly?.precipitation_probability?.[root.hourIndex] ?? 0}% rain`
                }
            }

            HourlyGraph {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingLarge
                hours: root.hours
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingBase
                Layout.bottomMargin: Theme.spacingSmall
                implicitHeight: 1
                color: Theme.outlineVariant
            }

            Repeater {
                model: root.days

                RowLayout {
                    id: day

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    spacing: 10

                    StyledText {
                        Layout.preferredWidth: 44
                        role: "secondary"
                        text: day.modelData.label
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }
                    Icon {
                        text: WeatherService.glyphFromCode(day.modelData.code, true)
                        color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
                    }
                    StyledText {
                        Layout.preferredWidth: 26
                        horizontalAlignment: Text.AlignRight
                        role: "tertiary"
                        text: `${day.modelData.min}°`
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Theme.colLayer3

                        Rectangle {
                            readonly property real span: Math.max(1, root.weekMax - root.weekMin)

                            x: parent.width * (day.modelData.min - root.weekMin) / span
                            width: Math.max(height, parent.width * (day.modelData.max - day.modelData.min) / span)
                            height: parent.height
                            radius: 2
                            color: day.index === 0 ? Theme.primary : Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
                        }
                    }
                    StyledText {
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                        text: `${day.modelData.max}°`
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }

        Row {
            anchors.centerIn: parent
            visible: !root.ready
            spacing: Theme.spacingBase

            Spinner {
                color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
            }
            StyledText {
                role: "secondary"
                text: "Loading weather…"
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    component Chip: Rectangle {
        id: chip

        property string icon
        property string text

        implicitWidth: chipContent.implicitWidth + 16
        implicitHeight: 28
        radius: Theme.radiusBase
        color: Theme.colLayer2

        Row {
            id: chipContent

            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                size: Theme.iconSizeSmall
                text: chip.icon
                color: Theme.alpha(Theme.textSecondary, Theme.tertiaryOpacity)
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                font.pixelSize: Theme.fontSizeTiny
            }
        }
    }
}
