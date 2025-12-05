pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import "../../Config"
import "../../Utils"

/**
 * HDR - HDR toggle service
 *
 * Manages HDR state by modifying ~/.config/hypr/monitors.conf
 * Swaps between "cm, srgb" and "cm, hdr" for HDR-capable monitors
 */
Singleton {
    id: root

    property bool enabled: false
    readonly property string monitorsConfigPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/hypr/monitors.conf"

    function toggle() {
        enabled = !enabled;
        updateConfig();
    }

    function updateConfig() {
        monitorsFileView.reload();
    }

    FileView {
        id: monitorsFileView
        path: root.monitorsConfigPath

        onLoaded: {
            let content = monitorsFileView.text();
            const monitors = Config.options?.monitors || {};
            let modified = false;

            for (const monitorId in monitors) {
                if (monitors[monitorId].hdrCapable) {
                    // Create regex to match this monitor's line
                    const monitorRegex = new RegExp(`(monitor\\s*=\\s*${monitorId}.*,\\s*cm,\\s*)(srgb|hdr)`, 'g');

                    if (root.enabled) {
                        // Replace srgb with hdr
                        const newContent = content.replace(monitorRegex, '$1hdr');
                        if (newContent !== content) {
                            content = newContent;
                            modified = true;
                        }
                    } else {
                        // Replace hdr with srgb
                        const newContent = content.replace(monitorRegex, '$1srgb');
                        if (newContent !== content) {
                            content = newContent;
                            modified = true;
                        }
                    }
                }
            }

            if (modified) {
                monitorsFileView.setText(content);
                Logger.info(`HDR ${root.enabled ? "enabled" : "disabled"} - monitors.conf updated`);
            }
        }

        onLoadFailed: error => {
            Logger.error(`Failed to load monitors.conf: ${error}`);
        }
    }

    // Check initial state on startup
    Component.onCompleted: {
        checkInitialState.reload();
    }

    FileView {
        id: checkInitialState
        path: root.monitorsConfigPath

        onLoaded: {
            const content = checkInitialState.text();
            const monitors = Config.options?.monitors || {};

            // Check if any HDR-capable monitor has "cm, hdr"
            for (const monitorId in monitors) {
                if (monitors[monitorId].hdrCapable) {
                    const hdrRegex = new RegExp(`monitor\\s*=\\s*${monitorId}.*,\\s*cm,\\s*hdr`);
                    if (hdrRegex.test(content)) {
                        root.enabled = true;
                        Logger.info("HDR state loaded: enabled");
                        return;
                    }
                }
            }
            root.enabled = false;
            Logger.info("HDR state loaded: disabled");
        }
    }
}
