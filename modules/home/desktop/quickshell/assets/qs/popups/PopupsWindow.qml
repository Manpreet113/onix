import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.theme

// Master Overlay Window Hosting All Dedicated Pop-ups (Ambxst / Caelestia Architecture)
PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "onix-popups"
    WlrLayershell.keyboardFocus: PopupState.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: PopupState.isOpen

    // Click outside backdrop to dismiss
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: PopupState.close()
    }

    // Global Dismiss Shortcuts
    Shortcut {
        sequence: "Escape"
        enabled: PopupState.isOpen
        onActivated: PopupState.close()
    }

    // Hotkeys when Power menu is active
    Shortcut {
        sequence: "l"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["hyprlock"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "u"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["systemctl", "suspend"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "e"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["hyprctl", "dispatch", "exit"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "r"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["systemctl", "reboot"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "s"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["systemctl", "poweroff"]); PopupState.close(); }
    }

    // 1. Right-Anchored Popups Container (Audio, Network, Battery, Power)
    Item {
        id: rightContainer
        anchors.top: parent.top
        anchors.topMargin: 54
        anchors.right: parent.right
        anchors.rightMargin: 16
        width: 350
        height: {
            if (audioPop.visible) return audioPop.height;
            if (netPop.visible) return netPop.height;
            if (battPop.visible) return battPop.height;
            if (powerPop.visible) return powerPop.height;
            return 300;
        }

        visible: PopupState.activePopup === "audio" ||
                 PopupState.activePopup === "network" ||
                 PopupState.activePopup === "battery" ||
                 PopupState.activePopup === "power"

        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.95
        transform: Translate {
            y: rightContainer.visible ? 0 : -8
            Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        Behavior on scale {
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
            }
        }

        AudioPopup {
            id: audioPop
            anchors.top: parent.top
            anchors.right: parent.right
            visible: PopupState.activePopup === "audio"
        }

        NetworkPopup {
            id: netPop
            anchors.top: parent.top
            anchors.right: parent.right
            visible: PopupState.activePopup === "network"
        }

        BatteryPopup {
            id: battPop
            anchors.top: parent.top
            anchors.right: parent.right
            visible: PopupState.activePopup === "battery"
        }

        PowerPopup {
            id: powerPop
            anchors.top: parent.top
            anchors.right: parent.right
            visible: PopupState.activePopup === "power"
            onActionExecuted: PopupState.close()
        }
    }

    // 2. Center-Anchored Popups Container (Calendar, Media)
    Item {
        id: centerContainer
        anchors.top: parent.top
        anchors.topMargin: 54
        anchors.horizontalCenter: parent.horizontalCenter
        width: 350
        height: {
            if (calPop.visible) return calPop.height;
            if (medPop.visible) return medPop.height;
            return 300;
        }

        visible: PopupState.activePopup === "calendar" ||
                 PopupState.activePopup === "media"

        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.95
        transform: Translate {
            y: centerContainer.visible ? 0 : -8
            Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        Behavior on scale {
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
            }
        }

        CalendarPopup {
            id: calPop
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            visible: PopupState.activePopup === "calendar"
        }

        MediaPopup {
            id: medPop
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            visible: PopupState.activePopup === "media"
        }
    }
}
