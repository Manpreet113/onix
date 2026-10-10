import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Network panel for the Overlay host: active connection, wifi radio
// toggle, access-point list with connect (incl. password entry) and
// disconnect. Backed by nmcli, same as the bar pill.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property string activeName: ""
    property string activeType: ""
    property bool wifiOn: true
    property var nets: []
    property string error: ""
    property string joinSsid: ""
    property string joinPw: ""

    // nmcli -t escapes literal colons as \: — split on bare colons only
    function splitEsc(s: string): var {
        var parts = [];
        var cur = "";
        for (var i = 0; i < s.length; i++) {
            var c = s[i];
            if (c === "\\" && i + 1 < s.length && s[i + 1] === ":") {
                cur += ":";
                i++;
            } else if (c === ":") {
                parts.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        parts.push(cur);
        return parts;
    }

    function refresh(): void {
        root.error = "";
        activeProc.running = true;
        radioProc.running = true;
        scanProc.running = true;
    }

    function onShown(): void {
        root.joinSsid = "";
        root.joinPw = "";
        refresh();
    }

    function setWifi(on: bool): void {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        refreshTimer.restart();
    }

    function connectOpen(ssid: string): void {
        root.error = "";
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid]);
        refreshTimer.restart();
    }

    function connectJoin(): void {
        if (root.joinSsid.length === 0)
            return;
        root.error = "";
        var cmd = ["nmcli", "dev", "wifi", "connect", root.joinSsid];
        if (root.joinPw.length > 0)
            cmd = cmd.concat(["password", root.joinPw]);
        Quickshell.execDetached(cmd);
        root.joinPw = "";
        joinBox.text = "";
        refreshTimer.restart();
    }

    function disconnectActive(): void {
        if (root.activeName.length === 0)
            return;
        Quickshell.execDetached(["nmcli", "con", "down", root.activeName]);
        refreshTimer.restart();
    }

    function sigIcon(sig: int): string {
        if (sig >= 75)
            return "󰖩";
        if (sig >= 50)
            return "󰖨";
        if (sig >= 25)
            return "󰖧";
        return "󰖦";
    }

    Timer {
        id: refreshTimer
        interval: 2500
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: activeProc
        command: ["sh", "-c", "nmcli -t -f TYPE,NAME con show --active"]
        stdout: StdioCollector {
            onStreamFinished: {
                var wifi = "", eth = "";
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var idx = lines[i].indexOf(":");
                    if (idx < 0)
                        continue;
                    var t = lines[i].slice(0, idx), n = lines[i].slice(idx + 1);
                    if (t.indexOf("wireless") >= 0 && wifi === "")
                        wifi = n;
                    else if (t.indexOf("ethernet") >= 0 && eth === "")
                        eth = n;
                }
                if (wifi !== "") {
                    root.activeType = "wireless";
                    root.activeName = wifi;
                } else if (eth !== "") {
                    root.activeType = "ethernet";
                    root.activeName = eth;
                } else {
                    root.activeType = "";
                    root.activeName = "";
                }
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: radioProc
        command: ["sh", "-c", "nmcli -t -f WIFI radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiOn = this.text.trim() !== "disabled";
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = [];
                var seen = ({});
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].length === 0)
                        continue;
                    var f = root.splitEsc(lines[i]);
                    if (f.length < 4)
                        continue;
                    var ssid = f[1];
                    if (ssid === "" || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    out.push({
                        active: f[0] === "*",
                        ssid: ssid,
                        signal: parseInt(f[2], 10) || 0,
                        security: f[3]
                    });
                }
                out.sort(function (a, b) {
                    return b.signal - a.signal;
                });
                root.nets = out;
            }
        }
        stderr: StdioCollector {}
    }

    Column {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            width: parent.width
            spacing: 12

            Text {
                text: "Network"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                font.bold: true
                Layout.fillWidth: true
            }

            // wifi radio pill
            Rectangle {
                implicitWidth: 76
                implicitHeight: 26
                radius: 13
                color: root.wifiOn ? Theme.primary : Theme.surface
                border.color: Theme.border
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fadeFast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: root.wifiOn ? "wifi on" : "wifi off"
                    color: root.wifiOn ? Theme.bg : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.setWifi(!root.wifiOn)
                }
            }

            Rectangle {
                implicitWidth: 76
                implicitHeight: 26
                radius: 13
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "rescan"
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.refresh()
                }
            }
        }

        // active connection card
        Rectangle {
            width: parent.width
            implicitHeight: 56
            color: Theme.surface
            radius: Theme.radiusMed

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: root.activeType === "wireless" ? "󰖩" : (root.activeType === "ethernet" ? "󰈀" : "󰖪")
                    color: root.activeName !== "" ? Theme.success : Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.activeName !== "" ? root.activeName : "disconnected"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMed
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Rectangle {
                    visible: root.activeName !== ""
                    implicitWidth: 96
                    implicitHeight: 28
                    radius: Theme.radiusSmall
                    color: Theme.bg
                    border.color: Theme.border
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        anchors.centerIn: parent
                        text: "disconnect"
                        color: Theme.error
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.disconnectActive()
                    }
                }
            }
        }

        Text {
            visible: root.error.length > 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.error
            color: Theme.error
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        // access points
        ListView {
            id: list
            width: parent.width
            height: parent.height - 290
            clip: true
            spacing: 6
            model: root.nets
            visible: root.wifiOn

            delegate: Rectangle {
                required property var modelData
                width: list.width
                implicitHeight: 44
                color: modelData.active ? Theme.bg : Theme.surface
                radius: Theme.radiusSmall
                border.color: modelData.active ? Theme.primary : Theme.border
                border.width: modelData.active ? 1 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: root.sigIcon(modelData.signal)
                        color: modelData.active ? Theme.primary : Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0
                        Text {
                            width: parent.width
                            text: modelData.ssid
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMed
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: (modelData.security !== "" ? modelData.security : "open") + " · " + modelData.signal + "%"
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        visible: modelData.active
                        text: "active"
                        color: Theme.success
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.active)
                            return;
                        if (modelData.security === "") {
                            root.connectOpen(modelData.ssid);
                        } else {
                            root.joinSsid = modelData.ssid;
                            joinBox.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // password row for secured join
        Rectangle {
            width: parent.width
            implicitHeight: 40
            visible: root.joinSsid !== ""
            color: Theme.surface
            radius: Theme.radiusMed
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "󰌆 " + root.joinSsid
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMed
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.maximumWidth: 180
                }
                TextInput {
                    id: joinBox
                    Layout.fillWidth: true
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMed
                    echoMode: TextInput.Password
                    onTextChanged: root.joinPw = text
                    Keys.onReturnPressed: root.connectJoin()
                    Keys.onEnterPressed: root.connectJoin()
                    Keys.onEscapePressed: {
                        root.joinSsid = "";
                        root.joinPw = "";
                    }
                }
                Rectangle {
                    implicitWidth: 60
                    implicitHeight: 26
                    radius: Theme.radiusSmall
                    color: Theme.primary
                    Text {
                        anchors.centerIn: parent
                        text: "join"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.connectJoin()
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "click a network to connect · esc in password cancels · esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
