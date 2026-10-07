import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
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

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.clock = Qt.formatDateTime(new Date(), "ddd dd MMM HH:mm");
            cpuProc.running = true;
            if (Date.now() % 2000 < 1000) memProc.running = true;
        }
    }

    Process {
        id: cpuProc
        command: [ "sh", "-c", "awk '/^cpu /{u=($2+$4)*100/($2+$4+$5); printf \"%.0f\", u}' /proc/stat" ]
        stdout: StdioCollector { onStreamFinished: () => { root.cpu = this.text; } }
        stderr: StdioCollector {}
    }

    Process {
        id: memProc
        command: [ "sh", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'" ]
        stdout: StdioCollector { onStreamFinished: () => { root.mem = this.text; } }
        stderr: StdioCollector {}
    }

    Rectangle {
        anchors.fill: parent
        color: "#2e3440"
        radius: 8
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
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
            Layout.fillWidth: true
            Layout.maximumWidth: 400
        }

        Item { Layout.fillWidth: true }


        Item { Layout.fillWidth: true }


        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            color: "#d8dee9"
            visible: UPower.displayDevice && UPower.displayDevice.isPresent
            text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage) + "%" : ""
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            color: "#81a1c1"
            text: {
                var sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return "vol ?";
                return sink.audio.muted ? "muted" : Math.round(sink.audio.volume * 100) + "%";
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var sink = Pipewire.defaultAudioSink;
                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
                }
            }
        }

        Text {
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13;
            color: "#bf616a"
            text: {
                var name = "Disconnected";
                for (var i = 0; i < Networking.devices.count; i++) {
                    var d = Networking.devices.get(i);
                    if (d && d.network && d.network.connected) { name = d.network.name; break; }
                }
                return name;
            }
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
}
