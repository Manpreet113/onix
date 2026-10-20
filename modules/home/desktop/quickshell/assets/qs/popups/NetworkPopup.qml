import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.components
import qs.services
import qs.theme

// Ambxst / Caelestia Inspired Network & Bluetooth Connectivity Pop-up
Rectangle {
    id: root
    width: 350
    implicitHeight: mainCol.implicitHeight + 28
    height: implicitHeight

    property bool embedded: false
    property bool wifiEnabled: Sys.wifiEnabled
    property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false

    color: embedded ? "transparent" : Theme.glassBg
    border.color: embedded ? "transparent" : Theme.glassBorder
    border.width: embedded ? 0 : 1
    radius: embedded ? 0 : 20
    clip: true

    // Specular highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: !root.embedded
    }

    // Drop shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        radius: parent.radius + 2
        color: Theme.glassShadow
        opacity: 0.6
        visible: !root.embedded
    }

    // Models
    ListModel { id: wifiModel }
    ListModel { id: btModel }

    // Wi-Fi Scan Process
    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const parts = line.split(":");
                if (parts.length >= 4) {
                    const ssid = parts[0];
                    if (!ssid) return;
                    const signal = parseInt(parts[1], 10) || 50;
                    const sec = parts[2];
                    const inUse = parts[3] === "*";

                    // Prevent duplicate SSIDs in scan
                    for (let i = 0; i < wifiModel.count; i++) {
                        if (wifiModel.get(i).ssid === ssid) return;
                    }

                    let icon = "signal_wifi_4_bar";
                    if (signal < 25) icon = "network_wifi_1_bar";
                    else if (signal < 50) icon = "network_wifi_2_bar";
                    else if (signal < 75) icon = "network_wifi_3_bar";

                    wifiModel.append({
                        ssid: ssid,
                        signal: signal,
                        secured: sec.length > 0 && sec !== "--",
                        inUse: inUse,
                        icon: icon
                    });
                }
            }
        }
    }

    // Bluetooth Devices Process
    Process {
        id: btScanProc
        command: ["bluetoothctl", "devices"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const match = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.+)$/);
                if (match) {
                    const mac = match[1];
                    const name = match[2];
                    let icon = "bluetooth";
                    if (name.toLowerCase().includes("buds") || name.toLowerCase().includes("headphone") || name.toLowerCase().includes("plt"))
                        icon = "headphones";
                    else if (name.toLowerCase().includes("keyboard"))
                        icon = "keyboard";
                    else if (name.toLowerCase().includes("mouse"))
                        icon = "mouse";

                    btModel.append({
                        mac: mac,
                        name: name,
                        icon: icon
                    });
                }
            }
        }
    }

    function refresh(): void {
        wifiModel.clear();
        btModel.clear();
        if (!wifiScanProc.running) wifiScanProc.running = true;
        if (!btScanProc.running) btScanProc.running = true;
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 14

        // 1. Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: Theme.accent
                    text: "rss_feed"
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.text
                    text: "Connectivity"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    color: Theme.dim
                    text: "Wi-Fi & Bluetooth Devices"
                }
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: Theme.text
                    text: "refresh"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refresh()
                }
            }
        }

        // 2. Master Toggle Tiles (Wi-Fi and Bluetooth)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Wi-Fi Tile
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 12
                color: root.wifiEnabled ? Theme.chipHover : Theme.cardBg
                border.color: root.wifiEnabled ? Theme.accent : Theme.cardBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 22
                        color: root.wifiEnabled ? Theme.accent : Theme.dim
                        text: root.wifiEnabled ? "wifi" : "wifi_off"
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.text
                            text: "Wi-Fi"
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 10
                            color: root.wifiEnabled ? Theme.accent : Theme.dim
                            text: root.wifiEnabled ? "Enabled" : "Disabled"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Sys.toggleWifi()
                }
            }

            // Bluetooth Tile
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 12
                color: root.btEnabled ? Theme.chipHover : Theme.cardBg
                border.color: root.btEnabled ? Theme.accent : Theme.cardBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 22
                        color: root.btEnabled ? Theme.accent : Theme.dim
                        text: root.btEnabled ? "bluetooth" : "bluetooth_disabled"
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.text
                            text: "Bluetooth"
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 10
                            color: root.btEnabled ? Theme.accent : Theme.dim
                            text: root.btEnabled ? "Enabled" : "Disabled"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bluetoothctl", "power", root.btEnabled ? "off" : "on"]);
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.cardBorder
        }

        // 3. Wi-Fi Networks Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.dim
                text: "WI-FI NETWORKS"
            }

            Repeater {
                model: wifiModel

                delegate: Rectangle {
                    required property var model
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: model.inUse ? Theme.chipHover : Theme.cardBg
                    border.color: model.inUse ? Theme.accent : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: model.inUse ? Theme.accent : Theme.text
                            text: model.icon
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 12
                            font.weight: model.inUse ? Font.Bold : Font.Normal
                            color: model.inUse ? Theme.text : Theme.subtext
                            text: model.ssid
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                            color: Theme.dim
                            text: "lock"
                            visible: model.secured
                        }

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: Theme.accent
                            text: "check"
                            visible: model.inUse
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!model.inUse) {
                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid]);
                            }
                        }
                    }
                }
            }
        }

        // 4. Bluetooth Devices Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: btModel.count > 0

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.dim
                text: "PAIRED BLUETOOTH DEVICES"
            }

            Repeater {
                model: btModel

                delegate: Rectangle {
                    required property var model
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: Theme.cardBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: Theme.accent
                            text: model.icon
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 12
                            font.weight: Font.Normal
                            color: Theme.text
                            text: model.name
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Connect button chip
                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 24
                            radius: 6
                            color: Theme.chipBg
                            border.color: Theme.cardBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontPrimary
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.accent
                                text: "Connect"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["bluetoothctl", "connect", model.mac]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
