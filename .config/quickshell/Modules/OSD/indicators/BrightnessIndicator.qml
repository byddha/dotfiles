import QtQuick
import "../../../Services"
import "../../OSD"

/**
 * Brightness indicator for OSD
 * Shows current screen brightness level
 */
OsdValueIndicator {
    id: root

    value: Brightness.brightness
    icon: Icons.brightness
}
