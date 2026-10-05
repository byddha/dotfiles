pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

BarPopout {
    id: root

    WlrLayershell.namespace: "bidshell:battery-popup"
    padding: Theme.spacingBase

    Card {
        implicitWidth: 340
        padding: Theme.spacingLarge
        spacing: Theme.spacingBase

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingBase

            Icon {
                text: Battery.charging ? Lucide.batteryCharging : Battery.isCritical ? Lucide.batteryWarning : Battery.percentage >= 80 ? Lucide.batteryFull : Battery.percentage >= 40 ? Lucide.batteryMedium : Lucide.batteryLow
                size: Theme.iconSizeLarge
                color: Battery.charging ? Theme.accentGreen : Battery.isCritical ? Theme.accentRed : Battery.isLow ? Theme.accentOrange : Theme.textColor
            }
            StyledText {
                text: `${Battery.percentage}%`
                font.pixelSize: Theme.fontSizeTitle
                font.weight: Font.DemiBold
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                role: "secondary"
                text: Battery.charging ? "Charging" : Battery.full ? "Fully charged" : Battery.discharging ? "On battery" : "Plugged in"
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            role: "tertiary"
            font.pixelSize: Theme.fontSizeSmall
            text: {
                const parts = [];
                if (Battery.charging && Battery.timeToFull > 0)
                    parts.push(`${Battery.formatTime(Battery.timeToFull)} until full`);
                else if (Battery.discharging && Battery.timeToEmpty > 0)
                    parts.push(`${Battery.formatTime(Battery.timeToEmpty)} remaining`);
                if (Battery.powerRate > 0)
                    parts.push(`${Battery.powerRate.toFixed(1)} W`);
                return parts.join(" · ");
            }
        }

        SectionHeader {
            Layout.topMargin: Theme.spacingBase
            Layout.leftMargin: -8
            Layout.rightMargin: -8
            text: "Power profile"
        }

        Slider {
            Layout.fillWidth: true
            implicitHeight: 24
            from: 0
            to: PowerMode.profiles.length - 1
            stepSize: 1
            snapMode: true
            showLabel: false
            value: PowerMode.profile
            onMoved: newValue => PowerMode.set(Math.round(newValue))
        }

        // Under the slider's dots: the first at the start, the last at the end
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: PowerMode.profiles

                Item {
                    id: option

                    required property int modelData
                    required property int index
                    readonly property bool current: modelData === PowerMode.profile

                    Layout.fillWidth: true
                    implicitHeight: label.implicitHeight

                    Row {
                        id: label

                        anchors.left: option.index === 0 ? parent.left : undefined
                        anchors.right: option.index === PowerMode.profiles.length - 1 ? parent.right : undefined
                        anchors.horizontalCenter: option.index > 0 && option.index < PowerMode.profiles.length - 1 ? parent.horizontalCenter : undefined
                        spacing: Theme.spacingSmall

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: PowerMode.icon(option.modelData)
                            size: Theme.iconSizeSmall
                            color: option.current ? Theme.primary : Theme.textSecondary
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: PowerMode.name(option.modelData)
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: option.current ? Font.DemiBold : Font.Normal
                            color: option.current ? Theme.primary : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        anchors.fill: label
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PowerMode.set(option.modelData)
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            role: "tertiary"
            font.pixelSize: Theme.fontSizeSmall
            text: PowerMode.description(PowerMode.profile)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingSmall
            visible: PowerMode.degradationReason !== PerformanceDegradationReason.None
            spacing: Theme.spacingBase

            Icon {
                text: Lucide.thermometer
                size: Theme.iconSizeSmall
                color: Theme.accentOrange
            }
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.accentOrange
                text: PowerMode.degradationText(PowerMode.degradationReason)
            }
        }

        Repeater {
            model: PowerMode.holds

            RowLayout {
                id: hold

                required property var modelData

                Layout.fillWidth: true
                spacing: Theme.spacingBase

                Icon {
                    text: Lucide.info
                    size: Theme.iconSizeSmall
                    color: Theme.textSecondary
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    role: "secondary"
                    font.pixelSize: Theme.fontSizeSmall
                    text: `${hold.modelData.applicationId} holds ${PowerMode.name(hold.modelData.profile)}` + (hold.modelData.reason ? `: ${hold.modelData.reason}` : "")
                }
            }
        }
    }
}
