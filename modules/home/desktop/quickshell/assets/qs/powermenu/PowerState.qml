pragma Singleton

import QtQuick
import Quickshell

// Single source of truth for the power pill dropdown.
Singleton {
    id: root

    property bool open: false
}
