import QtQuick
import Quickshell.Services.UPower
import "../../Config"
import "../../Services"

Item {
    id: root

    implicitWidth: peripheralRow.implicitWidth
    height: BarStyle.buttonSize

    Row {
        id: peripheralRow
        spacing: BarStyle.spacing
        height: parent.height

        // UPower peripherals (filtered — excludes replaced devices)
        Repeater {
            model: UPower.devices

            delegate: BatteryPill {
                required property var modelData

                property var _configDevices: Config.options.peripheralBatteries?.devices ?? []
                visible: PeripheralBatteries.isPeripheral(modelData, _configDevices)
                icon: PeripheralBatteries.getDeviceIcon(modelData)
                percentage: Math.round((modelData?.percentage ?? 0) * 100)
                charging: modelData?.state === UPowerDeviceState.Charging
                isLow: !charging && percentage <= PeripheralBatteries.lowThreshold
                isCritical: !charging && percentage <= PeripheralBatteries.criticalThreshold
                pulseWhileCharging: true
                tooltipText: PeripheralBatteries.getDeviceStatusText(modelData)
            }
        }

        // Custom devices from config
        Repeater {
            model: PeripheralBatteries.customDevices

            delegate: BatteryPill {
                required property var modelData

                visible: modelData?.present ?? false
                icon: modelData?.icon ?? ""
                percentage: modelData?.percentage ?? 0
                charging: modelData?.charging ?? false
                isLow: !charging && percentage <= PeripheralBatteries.lowThreshold
                isCritical: !charging && percentage <= PeripheralBatteries.criticalThreshold
                pulseWhileCharging: true
                tooltipText: {
                    const name = modelData?.name ?? "Device";
                    const pct = modelData?.percentage ?? 0;
                    const ch = modelData?.charging ?? false;
                    return `${name}: ${pct}%${ch ? " - Charging" : ""}`;
                }
            }
        }
    }
}
