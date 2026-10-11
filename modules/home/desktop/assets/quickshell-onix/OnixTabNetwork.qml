// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixTabNetwork: Wi-Fi + Ethernet manager (ports upstream NetworkTab,
// nmcli edition). Row click connects (password field appears for secured
// unknowns) or disconnects the active network.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Column {
    id: root
    spacing: 8
    width: 800

    property bool wifiOn: true
    property var aps: []
    property bool scanning: false
    property string pendingSsid: ""
    property string ethState: "…"

    function splitEscaped(line): var {
        var parts = [];
        var cur = "";
        for (var i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) {
                cur += line[i + 1];
                i++;
            } else if (line[i] === ":") {
                parts.push(cur);
                cur = "";
            } else {
                cur += line[i];
            }
        }
        parts.push(cur);
        return parts;
    }

    function refresh(): void {
        root.scanning = true;
        radioProc.running = true;
        ethProc.running = true;
        scanProc.running = true;
    }

    function setWifi(on): void {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        refreshTimer.restart();
    }

    function connectOpen(ssid): void {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid]);
        refreshTimer.restart();
    }

    function connectSecured(ssid, pass): void {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid, "password", pass]);
        root.pendingSsid = "";
        refreshTimer.restart();
    }

    function disconnect(ssid): void {
        Quickshell.execDetached(["nmcli", "con", "down", "id", ssid]);
        refreshTimer.restart();
    }

    function wifiIcon(ap): string {
        var s = ap.signal;
        var base = "network_wifi";
        if (s > 75)
            base = "network_wifi_3_bar";
        else if (s > 50)
            base = "network_wifi_2_bar";
        else if (s > 25)
            base = "network_wifi_1_bar";
        return ap.secured ? base + "_locked" : base;
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiOn = this.text.trim() === "enabled";
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: ethProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var eth = "Disconnected";
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("ethernet:connected") === 0)
                        eth = "Connected";
                }
                root.ethState = eth;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var out = [];
                var seen = {};
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "")
                        continue;
                    var p = root.splitEscaped(lines[i]);
                    if (p.length < 4 || p[1] === "")
                        continue;
                    if (seen[p[1]])
                        continue;
                    seen[p[1]] = true;
                    out.push({
                        active: p[0] === "*",
                        ssid: p[1],
                        signal: parseInt(p[2], 10) || 0,
                        secured: (p[3] || "") !== "" && p[3] !== "--"
                    });
                }
                out.sort(function (a, b) {
                    return b.signal - a.signal;
                });
                root.aps = out;
                root.scanning = false;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.aps = [];
                root.scanning = false;
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

    OnixCatLabel {
        icon: ""
        title: "Wi-Fi & Ethernet"
    }

    OnixSetRow {
        title: "Wi-Fi"
        description: "Toggle Wi-Fi on or off."
        control: Component {
            OnixSwitch {
                checked: root.wifiOn
                onToggled: value => root.setWifi(value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Available Networks"
        description: "Select a network to connect."
        vertical: true
        control: Component {
            Column {
                width: 776
                spacing: 5

                Text {
                    visible: !root.wifiOn
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Wi-Fi is disabled."
                    color: OnixTheme.mOnSurfaceVariant
                    font.pixelSize: OnixTheme.fontMed
                }
                Text {
                    visible: root.wifiOn && root.scanning && root.aps.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Scanning..."
                    color: OnixTheme.mOnSurfaceVariant
                    font.pixelSize: OnixTheme.fontMed
                }
                Text {
                    visible: root.wifiOn && !root.scanning && root.aps.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No networks found."
                    color: OnixTheme.mOnSurfaceVariant
                    font.pixelSize: OnixTheme.fontMed
                }

                Repeater {
                    model: root.aps
                    delegate: Column {
                        required property var modelData
                        width: 776
                        spacing: 5

                        Rectangle {
                            width: parent.width
                            implicitHeight: 52
                            radius: 12
                            color: rowHover.containsMouse ? OnixTheme.mSurfaceContainerHighest : OnixTheme.mSurfaceContainer
                            border.color: modelData.active ? OnixTheme.mPrimary : "transparent"
                            border.width: modelData.active ? 1 : 0

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.wifiIcon(modelData)
                                    color: OnixTheme.mOnSurface
                                    font.family: OnixTheme.iconFont
                                    font.pixelSize: 22
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 120
                                    text: modelData.ssid
                                    color: OnixTheme.mOnSurface
                                    font.pixelSize: OnixTheme.fontMed
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: modelData.active
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Connected"
                                    color: OnixTheme.mPrimary
                                    font.pixelSize: OnixTheme.fontSmall
                                }
                            }

                            MouseArea {
                                id: rowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.active)
                                        root.disconnect(modelData.ssid);
                                    else if (!modelData.secured)
                                        root.connectOpen(modelData.ssid);
                                    else
                                        root.pendingSsid = (root.pendingSsid === modelData.ssid) ? "" : modelData.ssid;
                                }
                            }
                        }

                        Row {
                            visible: root.pendingSsid === modelData.ssid
                            width: parent.width
                            spacing: 8
                            TextField {
                                id: passField
                                width: parent.width - passBtn.width - 8
                                placeholderText: "Password"
                                echoMode: TextInput.Password
                                color: OnixTheme.mOnSurface
                                placeholderTextColor: OnixTheme.mOnSurfaceVariant
                                font.pixelSize: OnixTheme.fontMed
                                background: Rectangle {
                                    color: OnixTheme.mSurfaceContainerHigh
                                    radius: OnixTheme.radiusFull
                                }
                                leftPadding: 16
                                rightPadding: 16
                            }
                            M3Button {
                                id: passBtn
                                btnType: "filled"
                                size: "s"
                                label: "Connect"
                                onClicked: root.connectSecured(modelData.ssid, passField.text)
                            }
                        }
                    }
                }
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Ethernet Status"
        description: "Status of your Ethernet connection."
        vertical: true
        control: Component {
            Text {
                text: root.ethState
                color: root.ethState === "Connected" ? OnixTheme.mPrimary : OnixTheme.mOnSurfaceVariant
                font.pixelSize: OnixTheme.fontMed
                font.bold: true
            }
        }
    }

    OnixCatLabel {
        icon: ""
        title: "Miscellaneous"
    }

    OnixSetRow {
        title: "Open Network Settings"
        description: "Open the network panel in the GNOME Settings application for advanced configuration."
        control: Component {
            M3Button {
                btnType: "tonal"
                size: "s"
                icon: "barefoot"
                label: "Open Settings"
                onClicked: Quickshell.execDetached(["sh", "-c", "XDG_CURRENT_DESKTOP=GNOME gnome-control-center network || notify-send -a 'Onix Settings' 'Error' 'GNOME Control Center not found.'"])
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Refresh Network Status"
        description: "Manually refresh the status of all network connections."
        control: Component {
            M3Button {
                btnType: "tonal"
                size: "s"
                icon: "refresh"
                label: "Refresh"
                onClicked: root.refresh()
            }
        }
    }
}
