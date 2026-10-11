// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWSysTray: tray icons + status cluster (ports upstream SystemInfoTray).
// StatusNotifier tray, wifi/ethernet, bluetooth, volume, and battery share
// one button that toggles the quickcenter (P4). Volume answers right/middle
// click (mute) and scroll (±5%); tray left-click activates.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Item {
    id: root

    property int barId: 0

    readonly property string barSec: root.barId === 0 ? "bar" : "bar2"
    readonly property bool vertical: OnixSettings.get(["interface", root.barSec, "vertical"], false)

    // network state
    property bool ethConnected: false
    property bool wifiEnabled: true
    property bool wifiConnected: false
    property int wifiSignal: 0
    // bluetooth state
    property bool btHasDevices: false
    property bool btPowered: false
    property bool btConnected: false
    // audio state
    property real volume: 0
    property bool muted: false
    // battery state
    property bool battPresent: false
    property int battPct: 0
    property bool battCharging: false

    readonly property string wifiIcon: {
        if (root.ethConnected)
            return "settings_ethernet";
        if (!root.wifiEnabled)
            return "";
        if (!root.wifiConnected)
            return "signal_wifi_off";
        if (root.wifiSignal >= 75)
            return "signal_wifi_4_bar";
        if (root.wifiSignal >= 50)
            return "network_wifi_3_bar";
        if (root.wifiSignal >= 25)
            return "network_wifi_2_bar";
        if (root.wifiSignal > 0)
            return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }
    readonly property string btIcon: {
        if (!root.btHasDevices)
            return "";
        if (!root.btPowered)
            return "bluetooth_disabled";
        return root.btConnected ? "bluetooth_connected" : "bluetooth";
    }
    readonly property string volIcon: {
        if (root.muted)
            return "volume_off";
        if (root.volume < 0.33)
            return "volume_mute";
        if (root.volume < 0.67)
            return "volume_down";
        return "volume_up";
    }
    readonly property string battIcon: {
        if (root.battCharging)
            return "bolt";
        if (root.battPct >= 100)
            return "battery_android_full";
        if (root.battPct >= 96)
            return "battery_android_6";
        if (root.battPct >= 81)
            return "battery_android_5";
        if (root.battPct >= 61)
            return "battery_android_4";
        if (root.battPct >= 41)
            return "battery_android_3";
        if (root.battPct >= 26)
            return "battery_android_2";
        if (root.battPct >= 11)
            return "battery_android_1";
        if (root.battPct >= 0)
            return "battery_android_0";
        return "battery_android_question";
    }

    implicitWidth: root.vertical ? 40 : cluster.implicitWidth + 20
    implicitHeight: root.vertical ? cluster.implicitHeight + 20 : 40

    // ---- data polls (compositor-agnostic CLI, same approach as the OSD) ----

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var eth = false;
                var wena = false;
                var wcon = false;
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split(":");
                    if (p[0] === "ethernet" && p[1] === "connected")
                        eth = true;
                    if (p[0] === "wifi") {
                        if (p[1] === "connected")
                            wcon = true;
                        if (p[1] !== "unavailable")
                            wena = true;
                    }
                }
                root.ethConnected = eth;
                root.wifiEnabled = wena;
                root.wifiConnected = wcon;
                if (wcon)
                    wifiSigProc.running = true;
                else
                    root.wifiSignal = 0;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: wifiSigProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("*:") === 0) {
                        root.wifiSignal = parseInt(lines[i].split(":")[1], 10) || 0;
                        return;
                    }
                }
                root.wifiSignal = 0;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl show | grep -m1 Powered; echo ---; bluetoothctl devices Connected; echo ---; bluetoothctl devices"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var parts = this.text.split("---");
                root.btPowered = parts.length > 0 && parts[0].indexOf("yes") >= 0;
                var connected = parts.length > 1 ? parts[1].trim() : "";
                var all = parts.length > 2 ? parts[2].trim() : "";
                root.btConnected = connected.length > 0;
                root.btHasDevices = all.length > 0;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var l = this.text.trim();
                var m = l.match(/Volume:\s*([0-9.]+)/);
                root.volume = m ? Math.min(1, parseFloat(m[1])) : 0;
                root.muted = l.indexOf("MUTED") >= 0;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        stdout: StdioCollector {
            onStreamFinished: volProc.running = true
        }
        stderr: StdioCollector {
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netProc.running = true;
            btProc.running = true;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    function updateBattery(): void {
        var cap = battCap.text().trim();
        var st = battStat.text().trim();
        if (cap.length === 0) {
            root.battPresent = false;
            return;
        }
        root.battPresent = true;
        root.battPct = parseInt(cap, 10) || 0;
        root.battCharging = st === "Charging";
        battCap.reload();
        battStat.reload();
    }

    property FileView battCap: FileView {
        path: "/sys/class/power_supply/BAT0/capacity"
        printErrors: false
        blockLoading: true
        onLoaded: root.updateBattery()
    }

    property FileView battStat: FileView {
        path: "/sys/class/power_supply/BAT0/status"
        printErrors: false
        blockLoading: true
        onLoaded: root.updateBattery()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.updateBattery()
    }

    // ---- visuals ----

    Flow {
        id: cluster
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: 10

        Row {
            visible: SystemTray.items.count > 0
            spacing: 10
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
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.activate()
                    }
                }
            }
        }

        Rectangle {
            id: statusBtn
            implicitWidth: root.vertical ? 32 : statusRow.implicitWidth + 20
            implicitHeight: root.vertical ? statusCol.implicitHeight + 20 : 32
            color: statusMouse.containsMouse ? OnixTheme.mPrimaryContainer : "transparent"
            radius: 15
            Behavior on color {
                NumberAnimation {
                    duration: 200
                }
            }

            Row {
                id: statusRow
                visible: !root.vertical
                anchors.centerIn: parent
                spacing: 8
                Text {
                    visible: root.wifiIcon !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wifiIcon
                    color: statusMouse.containsMouse ? OnixTheme.mOnPrimaryContainer : OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 20
                }
                Text {
                    visible: root.btIcon !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.btIcon
                    color: statusMouse.containsMouse ? OnixTheme.mOnPrimaryContainer : OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 20
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volIcon
                    color: statusMouse.containsMouse ? OnixTheme.mOnPrimaryContainer : OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 20
                }
                // battery pill (50x26, fill + status + %)
                Item {
                    visible: root.battPresent
                    anchors.verticalCenter: parent.verticalCenter
                    width: 50
                    height: 26
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: {
                            if (root.battPct <= 20 && !root.battCharging)
                                return Qt.rgba(OnixTheme.mError.r, OnixTheme.mError.g, OnixTheme.mError.b, 0.7);
                            if (root.battCharging)
                                return Qt.rgba(0x90 / 255, 0xee / 255, 0x90 / 255, 0.6);
                            return Qt.rgba(OnixTheme.mOnSurface.r, OnixTheme.mOnSurface.g, OnixTheme.mOnSurface.b, 0.6);
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * Math.min(1, root.battPct / 100)
                            height: parent.height
                            radius: 20
                            color: {
                                if (root.battPct <= 20 && !root.battCharging)
                                    return OnixTheme.mError;
                                if (root.battCharging)
                                    return "lightgreen";
                                return OnixTheme.mOnSurface;
                            }
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.battIcon
                                color: OnixTheme.mSurface
                                font.family: OnixTheme.iconFont
                                font.pixelSize: 13
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.battPct + "%"
                                color: OnixTheme.mSurface
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }
                }
            }

            Column {
                id: statusCol
                visible: root.vertical
                anchors.centerIn: parent
                spacing: 8
                Text {
                    visible: root.wifiIcon !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.wifiIcon
                    color: OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 20
                }
                Text {
                    visible: root.btIcon !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.btIcon
                    color: OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 20
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.volIcon
                    color: OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 20
                }
                Text {
                    visible: root.battPresent
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.battIcon
                    color: OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 20
                }
                Text {
                    visible: root.battPresent
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.battPct + ""
                    color: OnixTheme.mOnSurface
                    font.pixelSize: OnixTheme.fontSmall
                }
            }

            MouseArea {
                id: statusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button !== Qt.LeftButton)
                        muteProc.running = true;
                    else
                        OnixUi.toggleQuickCenter();
                }
                onWheel: wheel => {
                    var dir = wheel.angleDelta.y > 0 ? "5%+" : "5%-";
                    Quickshell.execDetached(["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + dir]);
                    volProc.running = true;
                }
            }
        }
    }
}
