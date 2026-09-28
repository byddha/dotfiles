import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Config"

// Reserves the bar's space along its edge. An empty window of its own, so the bar window can
// ignore exclusive zones and sit exactly at the screen edge (see BarLayout.windowOrigin).
PanelWindow {
    required property ShellScreen modelData

    screen: modelData
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "bidshell:bar-exclusion"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    exclusiveZone: BarLayout.reserved

    anchors {
        top: BarLayout.edge !== "bottom"
        bottom: BarLayout.edge !== "top"
        left: BarLayout.edge !== "right"
        right: BarLayout.edge !== "left"
    }
    implicitWidth: 1
    implicitHeight: 1
}
