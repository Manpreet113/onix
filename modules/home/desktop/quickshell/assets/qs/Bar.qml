import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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
    margins {
        top: 8
        left: 12
        right: 12
    }
    implicitHeight: 46
    color: "transparent"
    WlrLayershell.namespace: "onix-bar"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.preferredWidth: parent.width * 0.32
            Layout.fillHeight: true

            Island {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Workspaces {}
                WindowTitle {}
            }
        }

        Item {
            Layout.preferredWidth: parent.width * 0.36
            Layout.fillHeight: true

            Island {
                anchors.centerIn: parent
                Clock {}
            }
        }

        Item {
            Layout.preferredWidth: parent.width * 0.32
            Layout.fillHeight: true

            Island {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Cluster {}
            }
        }
    }
}
