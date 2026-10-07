import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 6
        left: 8
        right: 8
    }
    implicitHeight: 30
    color: "transparent"


    property string cpu: "?"
    property string mem: "?"
    property string clock: ""
    property string volume: "?"
    property string network: "Disconnected"
    property bool muted: false

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.clock = Qt.formatDateTime(new Date(), "ddd dd MMM HH:mm")
            cpuProc.running = true;
            if (Date.now() % 2000 < 1000) memProc.running = true;
        }
    }

    Timer {
        id: slowTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volProc.running = true;
            netProc.running = true;
        }
    }

    Process {
        id: volProc
        command: [ "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@" ]
        stdout: StdioCollector { onStreamFinished: () => {
            var l = this.text.trim();
            var m = l.match(/Volume:\s*([0-9.]+)/);
            root.volume = m ? Math.round(parseFloat(m[1]) * 100) + "%" : l;
            root.muted = l.indexOf("MUTED") >= 0;
        } }
        stderr: StdioCollector {}
    }

    Process {
        id: netProc
        command: [ "sh", "-c", "nmcli -t -f NAME,TYPE con show --active | grep -E 'wireless|ethernet' | head -n1 | cut -d: -f1" ]
        stdout: StdioCollector { onStreamFinished: () => { root.network = this.text.length > 0 ? this.text : "Disconnected"; } }
        stderr: StdioCollector {}
    }

    Process {
        id: cpuProc
        command: [ "sh", "-c", "awk '/^cpu /{u=($2+$4)*100/($2+$4+$5); printf \"%.0f\", u}' /proc/stat" ]
        stdout: StdioCollector { onStreamFinished: () => { root.cpu = this.text } }
        stderr: StdioCollector {}
    }

    Process {
        id: memProc
        command: [ "sh", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'" ]
        stdout: StdioCollector { onStreamFinished: () => { root.mem = this.text } }
        stderr: StdioCollector {}
    }

    Rectangle {
        anchors.fill: parent
        color: "#2e3440"
        radius: 8
    }

    RowLayout {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 20)
        spacing: 12

        Row {
            spacing: 4
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property HyprlandWorkspace modelData
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 6
                    color: modelData.focused ? "#81a1c1" : "#3b4252"
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
                        anchors.centerIn: parent
                        text: modelData.id
                        color: modelData.focused ? "#2e3440" : "#eceff4"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                }
            }
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
            color: "#d8dee9"
            elide: Text.ElideRight
            Layout.maximumWidth: 400
        }

        Item { Layout.fillWidth: true }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            text: root.cpu + "% CPU";
            color: "#a3be8c";
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            text: root.mem + "% MEM";
            color: "#ebcb8b";
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            color: "#d8dee9"
            visible: UPower.displayDevice && UPower.displayDevice.isPresent
            text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage) + "%" : ""
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            color: "#81a1c1"
            text: root.muted ? "muted" : root.volume
            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached([ "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle" ])
            }
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            color: "#bf616a"
            text: root.network
        }

        Row {
            spacing: 6
            Repeater {
                model: SystemTray.items
                delegate: Image {
                    required property var modelData
                    width: 18
                    height: 18
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.activate()
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        z: 2
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
        text: root.clock;
        color: "#eceff4";
    }
}
