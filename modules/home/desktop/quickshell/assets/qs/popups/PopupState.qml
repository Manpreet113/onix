pragma Singleton

import QtQuick
import Quickshell

// Central Coordinator for Individual Popups (Ambxst / Caelestia Architecture)
Singleton {
    id: root

    // Active popup name: "" | "audio" | "network" | "battery" | "calendar" | "media" | "power"
    property string activePopup: ""

    readonly property bool isOpen: activePopup !== ""

    function toggle(name: string): void {
        if (activePopup === name) {
            close();
        } else {
            activePopup = name;
        }
    }

    function open(name: string): void {
        activePopup = name;
    }

    function close(): void {
        activePopup = "";
    }
}
