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
    readonly property list<var> outputAppNodes: appNodes(true)
    readonly property list<var> inputAppNodes: appNodes(false)
    readonly property list<var> outputDevices: devices(true)
    readonly property list<var> inputDevices: devices(false)

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
        Logger.info(`Default sink set to: ${friendlyDeviceName(node)}`);
    }

    // Set default input device
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
        Logger.info(`Default source set to: ${friendlyDeviceName(node)}`);
    }

    Component.onCompleted: {
        Logger.info("PipeWire service initialized");
        Logger.info(`Sink: ${sink?.description ?? "none"}`);
        Logger.info(`Source: ${source?.description ?? "none"}`);
    }

    // Set volume (0.0 to 1.0)
    function setVolume(value) {
        if (!sink) {
            Logger.error("No audio sink available");
            return;
        }

        const clampedValue = Math.max(0, Math.min(1, value));
        sink.audio.volume = clampedValue;
        Logger.info(`Volume set to ${(clampedValue * 100).toFixed(0)}%`);
    }

    // Set microphone volume (0.0 to 1.0)
    function setMicVolume(value) {
        if (!source) {
            Logger.error("No audio source available");
            return;
        }

        const clampedValue = Math.max(0, Math.min(1, value));
        source.audio.volume = clampedValue;
        Logger.info(`Mic volume set to ${(clampedValue * 100).toFixed(0)}%`);
    }

    // Toggle mute
    function toggleMute() {
        if (!sink) {
            Logger.error("No audio sink available");
            return;
        }

        sink.audio.muted = !sink.audio.muted;
        Logger.info(`Audio ${sink.audio.muted ? 'muted' : 'unmuted'}`);
    }

    // Toggle microphone mute
    function toggleMicMute() {
        if (!source) {
            Logger.error("No audio source available");
            return;
        }

        source.audio.muted = !source.audio.muted;
        Logger.info(`Microphone ${source.audio.muted ? 'muted' : 'unmuted'}`);
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

    // Monitor for changes (for logging/debugging)
    onVolumeChanged: {
        Logger.info(`Volume changed to ${(volume * 100).toFixed(0)}%`);
    }

    onMicVolumeChanged: {
        Logger.info(`Mic volume changed to ${(micVolume * 100).toFixed(0)}%`);
    }

    onIsMutedChanged: {
        Logger.info(`Mute state changed to ${isMuted}`);
    }

    onIsMicMutedChanged: {
        Logger.info(`Mic mute state changed to ${isMicMuted}`);
    }
}
