pragma Singleton

import QtQuick
import Quickshell

// Shared motion tongue for the whole shell. Durations in ms.
// Spatial moves geometry; Effects only fades paint. Nothing anywhere
// else may carry its own magic numbers once migrated.
Singleton {
    id: root

    readonly property int spatial: 220
    readonly property int spatialSlow: 350
    readonly property int effects: 150
    readonly property int stagger: 70

    readonly property var spatialEasing: Easing.OutCubic
    readonly property var effectsEasing: Easing.OutQuad
}
