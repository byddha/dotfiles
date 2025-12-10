import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../Config"
import "../../Services"
import "../../Utils"

Scope {
    id: root

    enum SnipAction { Copy, Record }

    property int action: RegionSelector.SnipAction.Copy

    function dismiss() {
        Settings.regionSelectorVisible = false;
    }

    function screenshot() {
        root.action = RegionSelector.SnipAction.Copy;
        Settings.regionSelectorVisible = true;
    }

    function record() {
        root.action = RegionSelector.SnipAction.Record;
        Settings.regionSelectorVisible = true;
    }

    function setAction(newAction) {
        root.action = newAction;
    }

    // Reset to screenshot mode whenever overlay opens
    Connections {
        target: Settings
        function onRegionSelectorVisibleChanged() {
            if (Settings.regionSelectorVisible) {
                root.action = RegionSelector.SnipAction.Copy;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: windowLoader
            required property ShellScreen modelData
            active: Settings.regionSelectorVisible

            sourceComponent: SelectionWindow {
                screen: windowLoader.modelData
                action: root.action
                onDismiss: root.dismiss()
                onActionChangeRequested: (newAction) => root.setAction(newAction)
            }
        }
    }
}
