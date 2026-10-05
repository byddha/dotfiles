pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".."

// power-profiles-daemon through Quickshell's PowerProfiles; external changes (Fn+Q, powerprofilesctl) arrive as profileChanged
Singleton {
    id: root

    readonly property int profile: PowerProfiles.profile
    // Enum values, which are also the slider positions: PowerSaver 0, Balanced 1, Performance 2
    readonly property list<int> profiles: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]
    readonly property int degradationReason: PowerProfiles.degradationReason
    readonly property var holds: PowerProfiles.holds

    function set(profile) {
        PowerProfiles.profile = profile;
    }

    function name(profile) {
        return ["Power Saver", "Balanced", "Performance"][profile];
    }

    function icon(profile) {
        return [Lucide.leaf, Lucide.scale, Lucide.rocket][profile];
    }

    function description(profile) {
        return ["Reduced performance and power usage", "Standard performance and power usage", "High performance and power usage"][profile];
    }

    function degradationText(reason) {
        return reason === PerformanceDegradationReason.LapDetected ? "Performance limited: the laptop is on a lap" : "Performance limited: the laptop is too hot";
    }
}
