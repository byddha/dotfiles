pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    
    property QtObject options: QtObject {
        property QtObject overview: QtObject {
            property int rows: 5
            property int columns: 2
            property real scale: 0.08
            property bool enable: true

            // Map workspace IDs to monitor IDs
            property var workspaceToMonitor: ({
                1: 0, 2: 0, 3: 0, 4: 0, 5: 0,    // Workspaces 1-5 on monitor 0
                6: 1, 7: 1, 8: 1                  // Workspaces 6-8 on monitor 1
            })

            // Force 180° rotation for monitors in overview (monitor ID -> bool)
            // true = flip monitor preview upside down
            property var forceRotateMonitors: ({
                1: true    // Flip monitor 1 (second monitor) 180°
            })
        }
    }
}
