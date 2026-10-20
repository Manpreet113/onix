pragma Singleton

import QtQuick
import Quickshell

// Central state for the expanding Right Control Center / Power menu
Singleton {
    id: root

    property bool open: false
    property string activeTab: "controls" // "controls" | "power"
}
