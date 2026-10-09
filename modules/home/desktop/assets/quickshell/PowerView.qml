import QtQuick
import QtQuick.Layouts
import Quickshell

// Power menu content for the Overlay host. Actions run immediately;
// number keys 1-4 work when this view is shown (host shortcuts).
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property var actions: [
        { label: "Lock", key: "1", cmd: ["quickshell", "--config", "shell", "ipc", "call", "lock", "lock"] },
        { label: "Suspend", key: "2", cmd: ["systemctl", "suspend"] },
        { label: "Reboot", key: "3", cmd: ["systemctl", "reboot"] },
        { label: "Shutdown", key: "4", cmd: ["systemctl", "poweroff"] }
    ]

    function runIndex(i: int): void {
        if (i >= 0 && i < actions.length)
            run(actions[i].cmd);
    }

    function run(cmd: var): void {
        requestClose();
        Quickshell.execDetached(cmd);
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Power"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            font.bold: true
        }

        GridLayout {
            width: parent.width
            height: parent.height - 60
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: btnMouse.containsMouse ? Theme.blue : Theme.surface
                    radius: Theme.radiusMed
                    border.color: Theme.border
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.fadeFast
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: btnMouse.containsMouse ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "press " + modelData.key
                            color: btnMouse.containsMouse ? Theme.bg : Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.run(modelData.cmd)
                    }
                }
            }
        }
    }
}
