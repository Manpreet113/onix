import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components

RowLayout {
    id: root
    spacing: 4

    Repeater {
        model: SystemTray.items.values

        delegate: GlassChip {
            required property var modelData
            squircleRadius: 8
            implicitWidth: 28
            implicitHeight: 28

            onClicked: modelData.activate()
            onRightClicked: modelData.secondaryActivate()

            IconImage {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignCenter
                source: modelData.icon
            }
        }
    }
}
