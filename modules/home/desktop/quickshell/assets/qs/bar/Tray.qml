import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components

RowLayout {
    id: root
    spacing: 2

    // SystemTray is a singleton — no instance, use it directly.
    Repeater {
        model: SystemTray.items.values

        delegate: Pill {
            required property var modelData

            IconImage {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        modelData.secondaryActivate();
                    else
                        modelData.activate();
                }
            }
        }
    }
}
