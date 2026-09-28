import QtQuick
import Quickshell
import "../../Config"

Scope {
    id: root

    enum SnipAction {
        Copy,
        Record
    }

    property int action: RegionSelector.SnipAction.Copy
    // Sound for Record mode; off every time the selector opens so nothing records sound by accident
    property bool recordAudio: false
    property bool recordMic: false

    function dismiss() {
        Settings.regionSelectorVisible = false;
    }

    // Reset to screenshot mode whenever overlay opens
    Connections {
        target: Settings
        function onRegionSelectorVisibleChanged() {
            if (Settings.regionSelectorVisible) {
                root.action = RegionSelector.SnipAction.Copy;
                root.recordAudio = false;
                root.recordMic = false;
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
                recordAudio: root.recordAudio
                recordMic: root.recordMic
                onDismiss: root.dismiss()
                onActionChangeRequested: newAction => root.action = newAction
                onAudioToggleRequested: root.recordAudio = !root.recordAudio
                onMicToggleRequested: root.recordMic = !root.recordMic
            }
        }
    }
}
