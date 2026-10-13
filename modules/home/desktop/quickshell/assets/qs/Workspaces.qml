import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root
    spacing: 7

    property var wsList: Hyprland.workspaces.values.slice().sort((a, b) => a.id - b.id)

    Repeater {
        model: root.wsList

        delegate: Rectangle {
            required property var modelData

            // Per-object flags track reliably; the focusedWorkspace
            // singleton goes stale on empty workspaces.
            property bool isActive: modelData.active
            property bool isOccupied: ((modelData.toplevels?.values.length ?? 0) > 0)

            // NOTE: size via Layout props (explicit width overflows
            // siblings) and fill the row height like the AGS capsules.
            Layout.preferredWidth: isActive ? 30 : 10
            Layout.preferredHeight: 24
            radius: 999
            color: isActive ? "#777777" : (isOccupied ? "#BF5D5D5D" : "transparent")
            border.color: isActive ? "transparent" : "#B35D5D5D"
            border.width: isActive ? 0 : 1

            // NOTE: no Behavior on width — animated widths don't
            // relayout RowLayout siblings, overlapping the title.

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
