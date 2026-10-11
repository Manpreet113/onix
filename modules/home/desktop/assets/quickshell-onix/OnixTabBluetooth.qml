// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixTabBluetooth: adapter + device manager (ports upstream BluetoothTab,
// bluetoothctl edition). Row click connects/disconnects; scan runs a 15s
// discovery like upstream.
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: root
    spacing: 8
    width: 800

    property bool absent: false
    property bool powered: false
    property var devices: []
    property bool scanning: false

    function refresh(): void {
        showProc.running = true;
        devProc.running = true;
    }

    function setPower(on): void {
        Quickshell.execDetached(["bluetoothctl", "power", on ? "on" : "off"]);
        refreshTimer.restart();
    }

    function toggleDevice(mac, connected): void {
        Quickshell.execDetached(["bluetoothctl", connected ? "disconnect" : "connect", mac]);
        refreshTimer.restart();
    }

    function startScan(): void {
        root.scanning = true;
        scanProc.running = true;
    }

    function devIcon(icon): string {
        var map = {
            "audio-headset": "headphones",
            "audio-card": "speaker",
            "input-keyboard": "keyboard",
            "input-mouse": "mouse",
            "phone": "phone_android",
            "camera": "photo_camera",
            "computer": "computer"
        };
        return map[icon] || "bluetooth_connected";
    }

    Process {
        id: showProc
        command: ["sh", "-c", "bluetoothctl show 2>&1 | grep -m1 -E 'Powered|No default controller' || echo missing"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var t = this.text.trim();
                if (t.indexOf("No default controller") >= 0 || t === "missing" || t === "") {
                    root.absent = true;
                    return;
                }
                root.absent = false;
                root.powered = t.indexOf("yes") >= 0;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.absent = true
        }
    }

    Process {
        id: devProc
        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null; echo ---; bluetoothctl devices Connected 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var parts = this.text.split("---");
                var con = {};
                if (parts.length > 1) {
                    var cl = parts[1].trim().split("\n");
                    for (var j = 0; j < cl.length; j++) {
                        var cm = cl[j].match(/^Device\s+([0-9A-F:]+)/);
                        if (cm)
                            con[cm[1]] = true;
                    }
                }
                var out = [];
                var dl = (parts[0] || "").trim().split("\n");
                for (var i = 0; i < dl.length; i++) {
                    var m = dl[i].match(/^Device\s+([0-9A-F:]+)\s+(.*)$/);
                    if (m)
                        out.push({ mac: m[1], alias: m[2], connected: !!con[m[1]], icon: "" });
                }
                root.devices = out;
                for (var k = 0; k < out.length; k++)
                    infoProcFor(out[k].mac);
            }
        }
        stderr: StdioCollector {
        }
    }

    property string infoMac: ""
    function infoProcFor(mac): void {
        // serialized per-device info fetch via a single reused process
        pendingInfo.push(mac);
        if (!infoProc.running)
            nextInfo();
    }
    property var pendingInfo: []
    function nextInfo(): void {
        if (root.pendingInfo.length === 0)
            return;
        root.infoMac = root.pendingInfo.shift();
        infoProc.command = ["sh", "-c", "bluetoothctl info " + root.infoMac + " 2>/dev/null | grep -m3 -E '^(\\s*)(Name|Alias|Icon|Connected)' || true"];
        infoProc.running = true;
    }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: () => {
                var alias = "";
                var icon = "";
                var conn = null;
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var m = lines[i].trim().match(/^(Name|Alias|Icon|Connected):\s*(.*)$/);
                    if (m) {
                        if (m[1] === "Alias" || (m[1] === "Name" && alias === ""))
                            alias = m[2];
                        if (m[1] === "Icon")
                            icon = m[2];
                        if (m[1] === "Connected")
                            conn = m[2] === "yes";
                    }
                }
                var next = root.devices.slice();
                for (var j = 0; j < next.length; j++) {
                    if (next[j].mac === root.infoMac) {
                        if (alias !== "")
                            next[j].alias = alias;
                        next[j].icon = icon;
                        if (conn !== null)
                            next[j].connected = conn;
                    }
                }
                root.devices = next;
                root.nextInfo();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.nextInfo()
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "timeout 15 bluetoothctl scan on >/dev/null 2>&1; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false;
                root.refresh();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.scanning = false;
                root.refresh();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 4000
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Text {
        visible: root.absent
        anchors.horizontalCenter: parent.horizontalCenter
        text: "No Bluetooth Found"
        color: OnixTheme.mOnSurface
        font.pixelSize: OnixTheme.fontLarge
    }

    Column {
        visible: !root.absent
        width: parent.width
        spacing: 8

        OnixCatLabel {
            icon: ""
            title: "Bluetooth Adapter"
        }

        OnixSetRow {
            title: "Bluetooth"
            description: "Toggle the Bluetooth adapter on or off."
            control: Component {
                OnixSwitch {
                    checked: root.powered
                    onToggled: value => root.setPower(value)
                }
            }
        }

        OnixCatLabel {
            icon: ""
            title: "Devices"
        }

        OnixSetRow {
            title: "Paired & Discovered Devices"
            description: "Select a device to connect."
            vertical: true
            control: Component {
                Column {
                    width: 776
                    spacing: 5

                    Text {
                        visible: !root.powered
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Bluetooth is off."
                        color: OnixTheme.mOnSurfaceVariant
                        font.pixelSize: OnixTheme.fontMed
                    }
                    Text {
                        visible: root.powered && root.scanning && root.devices.length === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Scanning..."
                        color: OnixTheme.mOnSurfaceVariant
                        font.pixelSize: OnixTheme.fontMed
                    }
                    Text {
                        visible: root.powered && !root.scanning && root.devices.length === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No devices found."
                        color: OnixTheme.mOnSurfaceVariant
                        font.pixelSize: OnixTheme.fontMed
                    }

                    Repeater {
                        model: root.devices
                        delegate: Rectangle {
                            required property var modelData
                            width: 776
                            implicitHeight: 52
                            radius: 12
                            color: rowHover.containsMouse ? OnixTheme.mSurfaceContainerHighest : OnixTheme.mSurfaceContainer
                            border.color: modelData.connected ? OnixTheme.mPrimary : "transparent"
                            border.width: modelData.connected ? 1 : 0

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.devIcon(modelData.icon)
                                    color: OnixTheme.mOnSurface
                                    font.family: OnixTheme.iconFont
                                    font.pixelSize: 22
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 140
                                    text: modelData.alias || modelData.mac
                                    color: OnixTheme.mOnSurface
                                    font.pixelSize: OnixTheme.fontMed
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.connected ? "Connected" : "Not Connected"
                                    color: modelData.connected ? OnixTheme.mPrimary : OnixTheme.mOnSurfaceVariant
                                    font.pixelSize: OnixTheme.fontSmall
                                }
                            }

                            MouseArea {
                                id: rowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleDevice(modelData.mac, modelData.connected)
                            }
                        }
                    }
                }
            }
        }

        OnixSep {
        }

        OnixSetRow {
            title: "Scan for Devices"
            description: "Actively search for new Bluetooth devices in your vicinity."
            control: Component {
                M3Button {
                    btnType: "tonal"
                    size: "s"
                    icon: "bluetooth_searching"
                    label: root.scanning ? "Scanning..." : "Scan for Devices"
                    enabled: !root.scanning
                    onClicked: root.startScan()
                }
            }
        }

        OnixSep {
        }

        OnixSetRow {
            title: "Open Bluetooth Settings"
            description: "Open the Bluetooth panel in the GNOME Settings application for advanced configuration."
            control: Component {
                M3Button {
                    btnType: "tonal"
                    size: "s"
                    icon: "barefoot"
                    label: "Open Settings"
                    onClicked: Quickshell.execDetached(["sh", "-c", "XDG_CURRENT_DESKTOP=GNOME gnome-control-center bluetooth || notify-send -a 'Onix Settings' 'Error' 'GNOME Control Center not found.'"])
                }
            }
        }
    }
}
