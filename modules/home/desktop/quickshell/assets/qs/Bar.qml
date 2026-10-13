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
    // Geometry mirrors the AGS bar exactly: 8px top margin inside the
    // window, 38px content, 46px total reservation.
    exclusiveZone: 46
    margins {
        top: 8
        left: 12
        right: 12
    }
    implicitHeight: 38
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
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                gap: 6
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
                padH: 10
                Clock {}
            }
        }

        Item {
            Layout.preferredWidth: parent.width * 0.32
            Layout.fillHeight: true

            Island {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                gap: 4
                Cluster {}
            }
        }
    }
}
