import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.powermenu
import qs.theme

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    // Geometry mirrors the AGS bar exactly: 8px top margin inside the
    // window, 38px content, 46px total reservation.
    exclusiveZone: 46
    margins {
        top: 8
        left: 12
        right: 12
    }
    implicitHeight: 44 + 6 + powerList.implicitHeight + 14
    color: "transparent"
    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: 44

        Region {
            x: powerCard.x
            y: 44
            width: powerCard.width
            height: menuProg * (powerCard.height - 44)
        }
    }
    WlrLayershell.namespace: "onix-bar"
    WlrLayershell.keyboardFocus: PowerState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real menuProg: PowerState.open ? 1 : 0
    readonly property real menuFull: 6 + powerList.implicitHeight + 10

    Behavior on menuProg {
        NumberAnimation {
            duration: Motion.spatial
            easing.type: Motion.spatialEasing
        }
    }

    Connections {
        target: PowerState
        function onOpenChanged() {
            if (PowerState.open)
                powerList.reset();
        }
    }

    Shortcut {
        sequence: "Up"
        enabled: PowerState.open
        onActivated: {
            powerList.sel = (powerList.sel + powerList.count - 1) % powerList.count;
            powerList.armed = "";
        }
    }
    Shortcut {
        sequence: "Down"
        enabled: PowerState.open
        onActivated: {
            powerList.sel = (powerList.sel + 1) % powerList.count;
            powerList.armed = "";
        }
    }
    Shortcut {
        sequence: "Return"
        enabled: PowerState.open
        onActivated: powerList.trigger(powerList.sel)
    }
    Shortcut {
        sequence: "Enter"
        enabled: PowerState.open
        onActivated: powerList.trigger(powerList.sel)
    }
    Shortcut {
        sequence: "Escape"
        enabled: PowerState.open
        onActivated: {
            if (powerList.armed !== "")
                powerList.armed = "";
            else
                PowerState.open = false;
        }
    }

    RowLayout {
        id: barRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44
        spacing: 0

        Item {
            Layout.preferredWidth: parent.width * 0.32
            Layout.fillHeight: true

            Island {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                padH: 15
                Workspaces {}
                WindowTitle {}
            }
        }

        Item {
            Layout.preferredWidth: parent.width * 0.36
            Layout.fillHeight: true
            Island {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                gap: 8
                padV: 5
                padH: 15
                Clock {}
            }
        }

        Item {
            Layout.preferredWidth: parent.width * 0.32
            Layout.fillHeight: true
        }
    }

    Rectangle {
        id: powerCard
        anchors.top: parent.top
        anchors.right: parent.right
        width: menuRow.implicitWidth + 16
        height: 44 + menuFull * menuProg
        color: "#D6060606"
        border.color: "#2B2B2B"
        border.width: 1
        radius: 22

        RowLayout {
            id: menuRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 3
            height: 38

            Cluster {}
        }

        PowerList {
            id: powerList
            anchors.top: menuRow.bottom
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            visible: menuProg > 0
            opacity: menuProg
        }
    }
}
