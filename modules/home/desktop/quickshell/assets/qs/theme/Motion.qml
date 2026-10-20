pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Shared motion tongue for the whole shell. Durations in ms.
// Spatial moves geometry; Effects only fades paint.
Singleton {
    id: root

    // Centralized animation toggle based on Hyprland config
    property bool motionEnabled: true

    readonly property int spatial: 220
    readonly property int spatialSlow: 350
    readonly property int effects: 150
    readonly property int snappy: 120
    readonly property int stagger: 70
    readonly property int staggerClose: 50
    readonly property int reveal: 300
    readonly property int settle: 1400
    readonly property int settleQuick: 900

    readonly property var spatialEasing: Easing.OutCubic
    readonly property var effectsEasing: Easing.OutQuad

    readonly property real springStiffness: 8.0
    readonly property real springDamping: 0.5
    readonly property real bloomStiffness: 6.0
    readonly property real bloomDamping: 0.45

    Process {
        id: checkProc
        command: ["hyprctl", "getoption", "animations:enabled"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.startsWith("int:")) {
                    const val = parseInt(line.replace("int:", "").trim(), 10);
                    root.motionEnabled = (val === 1);
                }
            }
        }
    }

    function checkMotion(): void {
        if (!checkProc.running)
            checkProc.running = true;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded") {
                root.checkMotion();
            }
        }
    }

    Component.onCompleted: {
        root.checkMotion();
    }
}
