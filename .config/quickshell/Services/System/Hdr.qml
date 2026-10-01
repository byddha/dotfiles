pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../../Config"

Singleton {
    id: root

    property bool enabled: false
    property var hdrMonitors: []

    function refresh() {
        checkState();
    }

    function toggle() {
        if (hdrMonitors.length === 0)
            return;
        checkState();
        doToggle();
    }

    function checkState() {
        const monitors = Quickshell.screens.map(screen => Compositor.monitorFor(screen)).filter(mon => mon);
        const configMonitors = Config.options?.monitors || {};
        const capable = Compositor.hasHdrControl ? monitors.filter(mon => configMonitors[mon.key]?.hdrCapable) : [];
        root.hdrMonitors = capable.map(mon => mon.name);
        root.enabled = capable.some(mon => mon.hdr);
    }

    function doToggle() {
        for (const mon of hdrMonitors)
            Compositor.setHdr(mon, !enabled);
    }

    Connections {
        target: Compositor
        function onMonitorDataUpdated() {
            checkState();
        }
    }

    Component.onCompleted: checkState()
}
