import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io

RowLayout {
    id: root
    spacing: 7

    property var wsList: Hyprland.workspaces.values.slice().sort((a, b) => a.id - b.id)

    // hyprctl directly: Hyprland.dispatch() speaks lua in this setup.
    Process {
        id: hyprctl
    }

    Repeater {
        model: root.wsList

        delegate: Rectangle {
            required property var modelData

            property bool isActive: Hyprland.focusedWorkspace?.id === modelData.id
            property bool isOccupied: ((modelData.toplevels?.values.length ?? 0) > 0)

            width: isActive ? 30 : 10
            height: 10
            radius: 5
            color: isActive ? "#777777" : (isOccupied ? "#BF5D5D5D" : "transparent")
            border.color: isActive ? "transparent" : "#B35D5D5D"
            border.width: isActive ? 0 : 1

            Behavior on width {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.border.color = "#F2F2F2"
                onExited: parent.border.color = parent.isActive ? "transparent" : "#B35D5D5D"
                onClicked: {
                    hyprctl.command = ["hyprctl", "dispatch", "hl.dsp.focus({workspace = " + parent.modelData.id + "})"];
                    hyprctl.running = true;
                }
            }
        }
    }
}
