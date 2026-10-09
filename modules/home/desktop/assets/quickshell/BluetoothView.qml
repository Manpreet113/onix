import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// Bluetooth panel for the Overlay host: adapter power, scan, and a
// per-device list with connect / disconnect / remove.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property bool scanning: false

    function devName(d: var): string {
        if (!d)
            return "?";
        return d.name || d.alias || d.address || "?";
    }

    function setPower(on: bool): void {
        Quickshell.execDetached(["bluetoothctl", "power", on ? "on" : "off"]);
    }

    function setScan(on: bool): void {
        root.scanning = on;
        Quickshell.execDetached(["bluetoothctl", "scan", on ? "on" : "off"]);
        if (on)
            scanTimer.restart();
    }

    function devAction(d: var, what: string): void {
        if (!d || !d.address)
            return;
        Quickshell.execDetached(["bluetoothctl", what, d.address]);
    }

    Timer {
        id: scanTimer
        interval: 15000
        repeat: false
        onTriggered: root.setScan(false)
    }

    Column {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            width: parent.width
            spacing: 12

            Text {
                text: "Bluetooth"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                font.bold: true
                Layout.fillWidth: true
            }

            // adapter power pill
            Rectangle {
                implicitWidth: 76
                implicitHeight: 26
                radius: 13
                color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Theme.blue : Theme.surface
                border.color: Theme.border
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fadeFast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? "on" : "off"
                    color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Theme.bg : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var a = Bluetooth.defaultAdapter;
                        if (a)
                            root.setPower(!a.enabled);
                    }
                }
            }

            // scan pill
            Rectangle {
                implicitWidth: 76
                implicitHeight: 26
                radius: 13
                color: root.scanning ? Theme.cyan : Theme.surface
                border.color: Theme.border
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.scanning ? "stop" : "scan"
                    color: root.scanning ? Theme.bg : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.setScan(!root.scanning)
                }
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: !Bluetooth.defaultAdapter
            text: "no adapter found"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMed
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - 120
            clip: true
            spacing: 8
            model: Bluetooth.devices

            delegate: Rectangle {
                required property var modelData
                width: list.width
                implicitHeight: 62
                color: Theme.surface
                radius: Theme.radiusMed
                border.color: modelData.connected ? Theme.blue : Theme.border
                border.width: modelData.connected ? 1 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: modelData.connected ? "󰂯" : "󰂲"
                        color: modelData.connected ? Theme.blue : Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            width: parent.width
                            text: root.devName(modelData)
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMed
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: {
                                var bits = [];
                                if (modelData.address)
                                    bits.push(modelData.address);
                                bits.push(modelData.connected ? "connected" : (modelData.paired ? "paired" : "unpaired"));
                                return bits.join(" · ");
                            }
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }

                    // connect / disconnect
                    Rectangle {
                        implicitWidth: 86
                        implicitHeight: 28
                        radius: Theme.radiusSmall
                        color: modelData.connected ? Theme.bg : Theme.blue
                        border.color: Theme.border
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "disconnect" : "connect"
                            color: modelData.connected ? Theme.text : Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.devAction(modelData, modelData.connected ? "disconnect" : "connect")
                        }
                    }
                    // remove
                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 28
                        radius: Theme.radiusSmall
                        color: Theme.bg
                        border.color: Theme.border
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.red
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.devAction(modelData, "remove")
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "click connect to pair + connect · esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
