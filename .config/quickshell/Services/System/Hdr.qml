pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../Config"
import "../../Utils"

Singleton {
    id: root

    property bool enabled: false
    property var hdrMonitors: []
    property int pendingToggles: 0
    property bool pendingToggle: false

    function refresh() {
        queryMonitors.running = true;
    }

    function toggle() {
        if (hdrMonitors.length === 0) return;
        pendingToggle = true;
        queryMonitors.running = true;
    }

    function doToggle() {
        const newState = enabled ? "srgb" : "hdr";
        pendingToggles = hdrMonitors.length;
        for (const mon of hdrMonitors) {
            const proc = toggleComponent.createObject(root, {
                command: ["hyprctl", "keyword", `monitorv2[${mon}]:cm`, newState]
            });
            proc.running = true;
        }
    }

    Process {
        id: queryMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const monitors = JSON.parse(text);
                    const configMonitors = Config.options?.monitors || {};

                    root.hdrMonitors = [];
                    for (const monName in configMonitors) {
                        if (configMonitors[monName].hdrCapable) {
                            root.hdrMonitors.push(monName);
                        }
                    }

                    for (const mon of monitors) {
                        if (root.hdrMonitors.includes(mon.name)) {
                            if (mon.colorManagementPreset === "hdr") {
                                root.enabled = true;
                                Logger.info("HDR state: enabled");
                                if (root.pendingToggle) {
                                    root.pendingToggle = false;
                                    root.doToggle();
                                }
                                return;
                            }
                        }
                    }
                    root.enabled = false;
                    Logger.info("HDR state: disabled");

                    if (root.pendingToggle) {
                        root.pendingToggle = false;
                        root.doToggle();
                    }
                } catch (e) {
                    Logger.error("Failed to parse monitors:", e);
                }
            }
        }
    }

    Component {
        id: toggleComponent
        Process {
            onExited: (code) => {
                root.pendingToggles--;
                if (root.pendingToggles === 0 && code === 0) {
                    root.enabled = !root.enabled;
                    Logger.info(`HDR ${root.enabled ? "enabled" : "disabled"}`);
                }
                destroy();
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "monitoraddedv2" || event.name === "monitorremoved" || event.name === "configreloaded") {
                queryMonitors.running = true;
            }
        }
    }

    Component.onCompleted: queryMonitors.running = true
}
