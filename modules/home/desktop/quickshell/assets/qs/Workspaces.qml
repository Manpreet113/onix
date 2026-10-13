import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root
    spacing: 8

    property var wsList: Hyprland.workspaces.values.slice().sort((a, b) => a.id - b.id)

    Repeater {
        model: root.wsList

        delegate: Rectangle {
            required property var modelData

            // Per-object flags track reliably; the focusedWorkspace
            // singleton goes stale on empty workspaces.
            property bool isActive: modelData.active
            property bool isOccupied: ((modelData.toplevels?.values.length ?? 0) > 0)

            width: isActive ? 32 : 11
            height: 11
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
                onClicked: parent.modelData.activate()
            }
        }
    }
}
