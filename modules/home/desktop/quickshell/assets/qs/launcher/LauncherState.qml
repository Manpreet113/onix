pragma Singleton

import QtQuick
import Quickshell

// Single source of truth for the edge-summoned app fan.
Singleton {
    id: root

    property bool open: false
    property int sel: 0
}
