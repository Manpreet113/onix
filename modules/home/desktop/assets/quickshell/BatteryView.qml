import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery panel for the Overlay host: charge, state, time estimates,
// health per battery plus power-profile switching.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property string profile: "?"

    function fmtSecs(s: real): string {
        if (!(s > 0))
            return "—";
        var m = Math.round(s / 60);
        if (m < 60)
            return m + "m";
        return Math.floor(m / 60) + "h " + (m % 60) + "m";
    }

    function pctOf(dev: var): int {
        if (!dev)
            return -1;
        var p = dev.percentage;
        return p > 1 ? Math.round(p) : Math.round(p * 100);
    }

    function stateText(dev: var): string {
        if (!dev)
            return "unknown";
        var s = dev.state;
        if (s === UPowerDeviceState.Charging)
            return "charging";
        if (s === UPowerDeviceState.Discharging)
            return "discharging";
        if (s === UPowerDeviceState.FullyCharged)
            return "full";
        if (s === UPowerDeviceState.Empty)
            return "empty";
        return "unknown";
    }

    function battIcon(p: int, charging: bool): string {
        if (charging)
            return "󰂄";
        if (p >= 90)
            return "󰁹";
        if (p >= 80)
            return "󰂂";
        if (p >= 70)
            return "󰂁";
        if (p >= 60)
            return "󰂀";
        if (p >= 50)
            return "󰁿";
        if (p >= 40)
            return "󰁾";
        if (p >= 30)
            return "󰁽";
        if (p >= 20)
            return "󰁼";
        if (p >= 10)
            return "󰁻";
        return "󰁺";
    }

    function setProfile(p: string): void {
        Quickshell.execDetached(["powerprofilesctl", "set", p]);
        // daemon applies async; re-read shortly after
        profileTimer.restart();
    }

    function batteries(): var {
        var out = [];
        var vals = UPower.devices.values;
        for (var i = 0; i < vals.length; i++) {
            var d = vals[i];
            if (d && d.isPresent && d.powerSupply)
                out.push(d);
        }
        return out;
    }

    Process {
        id: profileProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.profile = this.text.trim();
            }
        }
        stderr: StdioCollector {}
    }

    Timer {
        id: profileTimer
        interval: 800
        repeat: false
        onTriggered: profileProc.running = true
    }

    function onShown(): void {
        profileProc.running = true;
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Text {
            text: "Battery"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            font.bold: true
        }

        // headline: icon + pct + state
        RowLayout {
            width: parent.width
            spacing: 14

            Text {
                text: {
                    var d = UPower.displayDevice;
                    var p = root.pctOf(d);
                    return root.battIcon(p, !UPower.onBattery);
                }
                color: Theme.success
                font.family: Theme.fontFamily
                font.pixelSize: 44
                Layout.alignment: Qt.AlignVCenter
            }
            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: {
                        var d = UPower.displayDevice;
                        var p = root.pctOf(d);
                        return p >= 0 ? p + "%" : "—";
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                }
                Text {
                    text: {
                        var d = UPower.displayDevice;
                        var st = root.stateText(d);
                        if (st === "discharging")
                            return "discharging · " + root.fmtSecs(d.timeToEmpty) + " left";
                        if (st === "charging")
                            return "charging · " + root.fmtSecs(d.timeToFull) + " to full";
                        return st;
                    }
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMed
                }
            }
        }

        // charge bar
        Rectangle {
            width: parent.width
            height: 8
            radius: 4
            color: Theme.surface
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.pctOf(UPower.displayDevice) / 100))
                height: parent.height
                radius: 4
                color: Theme.success
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.fadeMed
                    }
                }
            }
        }

        // per-battery details
        Repeater {
            model: root.batteries()
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                implicitHeight: detailCol.implicitHeight + 20
                color: Theme.surface
                radius: Theme.radiusMed

                Column {
                    id: detailCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    Text {
                        width: parent.width
                        text: (modelData.model || modelData.vendor || "battery") + " · health " + Math.round(modelData.capacity || 100) + "%"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMed
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: {
                            var e = modelData.energy, ef = modelData.energyFull;
                            var wh = (e > 0 && ef > 0) ? e.toFixed(1) + " / " + ef.toFixed(1) + " Wh · " : "";
                            var rate = modelData.energyRate > 0 ? modelData.energyRate.toFixed(1) + " W" : "— W";
                            return wh + rate + " · " + root.stateText(modelData);
                        }
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }

        // power profiles
        Text {
            text: "power profile · " + root.profile
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: ["power-saver", "balanced", "performance"]
                delegate: Rectangle {
                    required property string modelData
                    implicitWidth: 120
                    implicitHeight: 32
                    radius: Theme.radiusSmall
                    color: root.profile === modelData ? Theme.primary : Theme.surface
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData === "power-saver" ? "saver" : modelData
                        color: root.profile === modelData ? Theme.bg : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMed
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.setProfile(modelData)
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
            text: "esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
