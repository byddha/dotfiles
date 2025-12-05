pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Cache of resolved icon paths: iconName -> filePath
    property var iconCache: ({})

    // Pending lookups: iconName -> true
    property var pendingLookups: ({})

    // Signal emitted when an icon is resolved
    signal iconResolved(string iconName, string path)

    /**
     * Get icon path for an icon name
     * Returns cached path immediately, or empty string while lookup is pending
     * @param iconName - Icon name to resolve
     * @returns File path or empty string
     */
    function getIconPath(iconName) {
        if (!iconName || iconName.length === 0) {
            return "";
        }

        // If already a file path, return it directly
        if (iconName.startsWith("/")) {
            return "file://" + iconName;
        }
        if (iconName.startsWith("file://")) {
            return iconName;
        }

        // Check cache
        if (iconName in iconCache) {
            return iconCache[iconName];
        }

        // Start lookup if not already pending
        if (!(iconName in pendingLookups)) {
            pendingLookups[iconName] = true;
            lookupIcon(iconName);
        }

        return "";
    }

    function lookupIcon(iconName) {
        let proc = procComponent.createObject(root, {
            iconName: iconName
        });
        proc.running = true;
    }

    Component {
        id: procComponent

        Process {
            id: proc
            property string iconName
            property string result: ""

            command: ["python3", Qt.resolvedUrl("../../scripts/resolve_icon.py").toString().replace("file://", ""), iconName]

            stdout: SplitParser {
                onRead: data => {
                    proc.result = data.trim();
                }
            }

            onExited: (exitCode, exitStatus) => {
                let path = proc.result;
                if (path && path.length > 0 && !path.startsWith("file://")) {
                    path = "file://" + path;
                }

                // Cache the result (even if empty)
                root.iconCache[iconName] = path;
                delete root.pendingLookups[iconName];

                // Emit signal
                root.iconResolved(iconName, path);

                // Clean up
                proc.destroy();
            }
        }
    }
}
