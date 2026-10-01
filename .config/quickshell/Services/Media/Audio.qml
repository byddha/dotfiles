pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../Utils"

Singleton {
    id: root

    // PipeWire nodes
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource

    // Properties bound to PipeWire (auto-update on external changes)
    property real volume: sink?.audio.volume ?? 0.5
    property real micVolume: source?.audio.volume ?? 0.5
    property bool isMuted: sink?.audio.muted ?? false
    property bool isMicMuted: source?.audio.muted ?? false

    // Keep PipeWire connections alive
    PwObjectTracker {
        objects: [sink, source]
    }

    // Helper function: Check if node matches type (sink/source)
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio;
    }

    // Get all app audio streams (per-app audio)
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return correctType(node, isSink) && node.isStream;
        });
    }

    // Get all audio devices (physical/virtual outputs/inputs)
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return correctType(node, isSink) && !node.isStream;
        });
    }

    // Lists of nodes (auto-updating) - using list<var> because list<PwNode> breaks ScriptModel
    readonly property list<var> outputDevices: devices(true)
    readonly property list<var> inputDevices: devices(false)

    // Grouped app nodes by application binary/name
    readonly property list<var> groupedOutputAppNodes: {
        const nodes = appNodes(true);
        const groups = {};
        const order = [];

        for (const node of nodes) {
            const key = node.properties["application.process.binary"] || node.properties["application.name"]?.toLowerCase() || "unknown";

            if (!groups[key]) {
                groups[key] = {
                    appKey: key,
                    appName: appNodeDisplayName(node),
                    nodes: []
                };
                order.push(key);
            }
            groups[key].nodes.push(node);
        }

        return order.map(key => groups[key]);
    }

    // Format app name for display
    function appNodeDisplayName(node) {
        if (!node)
            return "Unknown";
        return (node.properties["application.name"] || node.description || node.name || "Unknown");
    }

    // Format device name for display
    function friendlyDeviceName(node) {
        if (!node)
            return "Unknown Device";
        return node.description || node.name || "Unknown Device";
    }

    // Set default output device
    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    // Set default input device
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Set volume (0.0 to 1.0)
    // limit > 1 allows boost (sidebar sliders go to 150%)
    function setVolume(value, limit = 1) {
        if (!sink) {
            Logger.error("No audio sink available");
            return;
        }

        const clampedValue = Math.max(0, Math.min(limit, value));
        sink.audio.volume = clampedValue;
    }

    // Set microphone volume (0.0 to 1.0)
    function setMicVolume(value, limit = 1) {
        if (!source) {
            Logger.error("No audio source available");
            return;
        }

        const clampedValue = Math.max(0, Math.min(limit, value));
        source.audio.volume = clampedValue;
    }

    // Toggle mute
    function toggleMute() {
        if (!sink) {
            Logger.error("No audio sink available");
            return;
        }

        sink.audio.muted = !sink.audio.muted;
    }

    // Toggle microphone mute
    function toggleMicMute() {
        if (!source) {
            Logger.error("No audio source available");
            return;
        }

        source.audio.muted = !source.audio.muted;
    }

    // Increase volume by 5%
    function increaseVolume() {
        setVolume(volume + 0.05);
    }

    // Decrease volume by 5%
    function decreaseVolume() {
        setVolume(volume - 0.05);
    }

    // Increase mic volume by 5%
    function increaseMicVolume() {
        setMicVolume(micVolume + 0.05);
    }

    // Decrease mic volume by 5%
    function decreaseMicVolume() {
        setMicVolume(micVolume - 0.05);
    }
}
