import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// System panel for the Overlay host: cpu / mem / disk / load / uptime
// plus a top-process list. Refreshes on show and every 3s while open
// (the Loader destroys this with the view, so no background cost).
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property string cpu: "?"
    property string mem: "?"
    property string disk: "?"
    property string load: ""
    property string uptime: ""
    property var tops: []

    function refresh(): void {
        cpuProc.running = true;
        memProc.running = true;
        diskProc.running = true;
        miscProc.running = true;
        topProc.running = true;
    }

    function onShown(): void {
        root.refresh();
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu /{u=($2+$4)*100/($2+$4+$5); printf \"%.0f\", u}' /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.cpu = this.text;
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mem = this.text;
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df / | awk 'NR==2 {print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.disk = this.text.trim().replace("%", "");
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: miscProc
        command: ["sh", "-c", "awk '{s=$1; h=int(s/3600); m=int(s%3600/60); printf \"up %dh %dm|\", h, m}' /proc/uptime; cut -d' ' -f1-3 /proc/loadavg"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|");
                root.uptime = parts.length > 0 ? parts[0] : "";
                root.load = parts.length > 1 ? parts[1].trim() : "";
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: topProc
        command: ["sh", "-c", "ps -eo pcpu,pmem,comm --sort=-pcpu | head -8 | tail -7"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = [];
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].trim().split(/\s+/);
                    if (f.length >= 3)
                        out.push({ cpu: f[0], mem: f[1], cmd: f.slice(2).join(" ") });
                }
                root.tops = out;
            }
        }
        stderr: StdioCollector {}
    }

    component Meter: Column {
        id: meter
        property string label: ""
        property string value: "?"
        property color meterColor: Theme.primary
        width: parent.width
        spacing: 4

        RowLayout {
            width: parent.width
            Text {
                text: meter.label
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
                font.bold: true
                Layout.fillWidth: true
            }
            Text {
                text: meter.value + "%"
                color: meter.meterColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
                font.bold: true
            }
        }
        Rectangle {
            width: parent.width
            height: 8
            radius: 4
            color: Theme.surface
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, parseFloat(meter.value) / 100 || 0))
                height: parent.height
                radius: 4
                color: meter.meterColor
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.fadeMed
                    }
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Text {
            text: "System"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            font.bold: true
        }

        Text {
            width: parent.width
            text: (root.uptime !== "" ? root.uptime + " · " : "") + (root.load !== "" ? "load " + root.load : "")
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }

        Meter {
            label: "cpu"
            value: root.cpu
            meterColor: Theme.success
        }
        Meter {
            label: "memory"
            value: root.mem
            meterColor: Theme.warning
        }
        Meter {
            label: "disk /"
            value: root.disk
            meterColor: Theme.accent
        }

        Text {
            text: "top processes"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        Repeater {
            model: root.tops
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                implicitHeight: 28
                color: Theme.surface
                radius: Theme.radiusSmall

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: modelData.cmd
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMed
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "mem " + modelData.mem + "%"
                        color: Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: modelData.cpu + "%"
                        color: Theme.success
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        Layout.minimumWidth: 52
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        Item {
            width: 1
            height: 1
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "refreshes every 3s while open · esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
