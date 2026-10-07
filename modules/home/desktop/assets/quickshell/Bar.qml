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
    property string netType: ""
    property bool muted: false

    component Pill: Rectangle {
        id: pill
        signal pressed
        property alias iconText: pillIcon.text
        property alias iconColor: pillIcon.color
        property alias valueText: pillValue.text
        property alias valueColor: pillValue.color

        implicitHeight: 22
        implicitWidth: pillRow.implicitWidth + 16
        radius: 6
        color: "#3b4252"

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                id: pillIcon
                anchors.verticalCenter: parent.verticalCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }
            Text {
                id: pillValue
                anchors.verticalCenter: parent.verticalCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: pill.pressed()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.clock = Qt.formatDateTime(new Date(), "ddd dd MMM HH:mm");
            cpuProc.running = true;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memProc.running = true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }

    Process {
        id: volProc
        running: true
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
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
        running: true
        command: ["sh", "-c", "n=$(nmcli -t -f TYPE,NAME con show --active | grep wireless | head -n1); if [ -z \"$n\" ]; then n=$(nmcli -t -f TYPE,NAME con show --active | grep ethernet | head -n1); fi; printf '%s' \"$n\""]
        stdout: SplitParser { onRead: data => {
            var parts = data.trim().split(":");
            if (parts.length >= 2 && parts.slice(1).join(":").length > 0) {
                root.netType = parts[0];
                root.network = parts.slice(1).join(":");
            } else {
                root.netType = "";
                root.network = "Disconnected";
            }
        } }
        stderr: StdioCollector {}
    }

    property int lastVolPoll: 0

    // wpctl events -> instant volume refresh (throttled)
    Process {
        id: volMon
        running: true
        command: ["pw-mon"]
        stdout: SplitParser { onRead: data => {
            var now = Date.now();
            if (now - root.lastVolPoll > 400) {
                root.lastVolPoll = now;
                volProc.running = true;
            }
        } }
        stderr: StdioCollector {}
    }

    // NetworkManager events -> instant network refresh
    Process {
        id: netMon
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: data => { netProc.running = true; } }
        stderr: StdioCollector {}
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu /{u=($2+$4)*100/($2+$4+$5); printf \"%.0f\", u}' /proc/stat"]
        stdout: StdioCollector { onStreamFinished: () => { root.cpu = this.text; } }
        stderr: StdioCollector {}
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'"]
        stdout: StdioCollector { onStreamFinished: () => { root.mem = this.text; } }
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
        spacing: 8

        Row {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property HyprlandWorkspace modelData
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 6
                    color: modelData.focused ? "#81a1c1" : "#3b4252"
                    Text {
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
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
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
            color: "#d8dee9"
            elide: Text.ElideRight
            Layout.maximumWidth: 400
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Pill {
            iconText: "󰍛"
            iconColor: "#a3be8c"
            valueText: root.cpu + "%"
            valueColor: "#a3be8c"
            Layout.alignment: Qt.AlignVCenter
        }

        Pill {
            iconText: "󰳲"
            iconColor: "#ebcb8b"
            valueText: root.mem + "%"
            valueColor: "#ebcb8b"
            Layout.alignment: Qt.AlignVCenter
        }

        Pill {
            visible: UPower.displayDevice && UPower.displayDevice.isPresent
            iconText: {
                if (!UPower.displayDevice) return "󰁹";
                if (!UPower.onBattery) return "󰂄";
                var p = UPower.displayDevice.percentage;
                if (p >= 90) return "󰁹";
                if (p >= 80) return "󰂂";
                if (p >= 70) return "󰂁";
                if (p >= 60) return "󰂀";
                if (p >= 50) return "󰁿";
                if (p >= 40) return "󰁾";
                if (p >= 30) return "󰁽";
                if (p >= 20) return "󰁼";
                if (p >= 10) return "󰁻";
                return "󰁺";
            }
            iconColor: (UPower.displayDevice && UPower.displayDevice.percentage <= 15 && UPower.onBattery) ? "#bf616a" : "#d8dee9"
            valueText: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage) + "%" : ""
            valueColor: "#d8dee9"
            Layout.alignment: Qt.AlignVCenter
        }

        Pill {
            iconText: root.muted ? "" : "󰕾"
            iconColor: "#81a1c1"
            valueText: root.muted ? "muted" : root.volume
            valueColor: "#81a1c1"
            Layout.alignment: Qt.AlignVCenter
            onPressed: {
                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                volProc.running = true;
            }
        }

        Pill {
            iconText: root.netType.indexOf("wireless") >= 0 ? "󰖩" : (root.netType.length > 0 ? "󰈀" : "󰖪")
            iconColor: "#bf616a"
            valueText: root.network
            valueColor: "#bf616a"
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            implicitHeight: 22
            implicitWidth: trayRow.implicitWidth + 16
            radius: 6
            color: SystemTray.items.count > 0 ? "#3b4252" : "#2e3440"
            border.color: SystemTray.items.count > 0 ? "#3b4252" : "#4c566a"
            border.width: SystemTray.items.count > 0 ? 0 : 1
            opacity: SystemTray.items.count > 0 ? 1.0 : 0.6
            Layout.alignment: Qt.AlignVCenter

            Row {
                id: trayRow
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: SystemTray.items
                    delegate: Image {
                        required property var modelData
                        width: 16
                        height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: modelData.activate()
                        }
                    }
                }
                Text {
                    visible: SystemTray.items.count === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⋯"
                    color: "#4c566a"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        z: 2
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        text: root.clock
        color: "#eceff4"
    }
}
