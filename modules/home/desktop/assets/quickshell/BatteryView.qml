import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery hero panel: giant numeral, ticked charge rail, stat table,
// segmented power profiles, ghost watermark. Success green means
// healthy charge — the only place it appears here.
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

    function firstBattery(): var {
        var vals = UPower.devices.values;
        for (var i = 0; i < vals.length; i++) {
            var d = vals[i];
            if (d && d.isPresent && d.powerSupply)
                return d;
        }
        return null;
    }

    property int pct: root.pctOf(UPower.displayDevice)
    property string state: root.stateText(UPower.displayDevice)

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

    // ghost watermark
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -10
        anchors.bottomMargin: 60
        text: root.pct >= 0 ? root.pct : ""
        color: Theme.text
        opacity: 0.04
        font.family: Theme.fontFamily
        font.pixelSize: 150
        font.bold: true
    }

    // ticked charge rail
    Item {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 90
        width: 10

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: Theme.bg
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0, Math.min(1, root.pct / 100))
            radius: 5
            color: Theme.success
            Behavior on height {
                NumberAnimation {
                    duration: Theme.fadeMed
                }
            }
        }
        Repeater {
            model: 10
            delegate: Rectangle {
                required property int index
                width: index % 2 === 0 ? 18 : 12
                height: 2
                radius: 1
                color: Theme.border
                x: 0
                y: parent.height - (index + 1) * (parent.height / 10)
            }
        }
    }

    Column {
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        spacing: 10

        // hero numeral + state
        Item {
            width: parent.width
            implicitHeight: 112

            Text {
                id: heroNum
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: root.pct >= 0 ? root.pct : "—"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 96
                font.bold: true
                renderType: Text.NativeRendering
            }
            Text {
                anchors.left: heroNum.right
                anchors.leftMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                text: "%"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 36
                font.bold: true
            }
        }

        Text {
            text: {
                if (root.state === "discharging")
                    return ("DISCHARGING · " + root.fmtSecs(UPower.displayDevice.timeToEmpty) + " LEFT").toUpperCase();
                if (root.state === "charging")
                    return ("CHARGING · " + root.fmtSecs(UPower.displayDevice.timeToFull) + " TO FULL").toUpperCase();
                return root.state.toUpperCase();
            }
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
        }

        // drawn battery instrument
        Row {
            spacing: 12

            Item {
                width: 64
                height: 32
                Rectangle {
                    anchors.fill: parent
                    anchors.rightMargin: 6
                    radius: 8
                    color: "transparent"
                    border.color: Theme.subtext
                    border.width: 2
                }
                Rectangle {
                    x: 5
                    y: 9
                    width: 6
                    height: 14
                    radius: 2
                    color: Theme.subtext
                }
                Rectangle {
                    x: 6
                    y: 6
                    width: Math.max(0, 46 * Math.max(0, Math.min(1, root.pct / 100)))
                    height: 20
                    radius: 5
                    color: Theme.success
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var b = root.firstBattery();
                    if (!b || !(b.energyRate > 0))
                        return "";
                    return (b.energyRate.toFixed(1) + " W DRAW").toUpperCase();
                }
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }

        // stat table with dividers
        Row {
            width: parent.width
            spacing: 0

            Column {
                width: (parent.width - 2) / 3
                spacing: 2
                Text {
                    text: "ENERGY"
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    text: {
                        var b = root.firstBattery();
                        return (b && b.energy > 0) ? b.energy.toFixed(1) + " Wh" : "—";
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLarge
                    font.bold: true
                }
            }
            Rectangle {
                width: 1
                height: 44
                color: Theme.border
            }
            Column {
                width: (parent.width - 2) / 3
                spacing: 2
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    text: "HEALTH"
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    text: {
                        var b = root.firstBattery();
                        return Math.round((b && b.capacity) || 100) + "%";
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLarge
                    font.bold: true
                }
            }
            Rectangle {
                width: 1
                height: 44
                color: Theme.border
            }
            Column {
                width: (parent.width - 2) / 3
                spacing: 2
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    text: "PROFILE"
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    text: root.profile
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLarge
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width - 16
                }
            }
        }

        // segmented profiles
        Rectangle {
            width: parent.width
            implicitHeight: 36
            radius: 9
            color: Theme.bg
            border.color: Theme.border
            border.width: 1

            Row {
                anchors.fill: parent
                Repeater {
                    model: ["power-saver", "balanced", "performance"]
                    delegate: Item {
                        required property string modelData
                        width: parent.width / 3
                        height: parent.height
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 6
                            color: root.profile === modelData ? Theme.primary : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent
                            text: modelData === "power-saver" ? "saver" : modelData
                            color: root.profile === modelData ? Theme.bg : Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.setProfile(modelData)
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: 1
        }
    }
}
