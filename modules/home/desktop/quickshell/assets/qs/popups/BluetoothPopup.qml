import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.components
import qs.services
import qs.theme

// Caelestia / Dynamic Island Full-Featured Bluetooth Pop-up
Rectangle {
    id: btPopupRoot
    width: 360
    implicitHeight: mainCol.implicitHeight + 28
    height: implicitHeight

    property bool embedded: false
    property bool isScanning: false

    color: embedded ? "transparent" : Theme.glassBg
    border.color: embedded ? "transparent" : Theme.glassBorder
    border.width: embedded ? 0 : 1
    radius: embedded ? 0 : 20
    clip: true

    // Top specular highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: !btPopupRoot.embedded
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
        visible: !btPopupRoot.embedded
    }

    ListModel { id: connModel }
    ListModel { id: pairedModel }

    // Query connected devices
    Process {
        id: connDevicesProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const match = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.+)$/);
                if (match) {
                    const mac = match[1];
                    const name = match[2];
                    let icon = "bluetooth";
                    const lower = name.toLowerCase();
                    if (lower.includes("buds") || lower.includes("headphone") || lower.includes("plt") || lower.includes("audio"))
                        icon = "headphones";
                    else if (lower.includes("keyboard"))
                        icon = "keyboard";
                    else if (lower.includes("mouse"))
                        icon = "mouse";

                    connModel.append({
                        mac: mac,
                        name: name,
                        icon: icon,
                        battery: Sys.btBattery > 0 ? Sys.btBattery : -1
                    });
                }
            }
        }
    }

    // Query paired devices
    Process {
        id: pairedDevicesProc
        command: ["bluetoothctl", "devices"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const match = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.+)$/);
                if (match) {
                    const mac = match[1];
                    const name = match[2];

                    // Check if already in connected model
                    for (let c = 0; c < connModel.count; c++) {
                        if (connModel.get(c).mac === mac) return;
                    }

                    let icon = "bluetooth";
                    const lower = name.toLowerCase();
                    if (lower.includes("buds") || lower.includes("headphone") || lower.includes("plt") || lower.includes("audio"))
                        icon = "headphones";
                    else if (lower.includes("keyboard"))
                        icon = "keyboard";
                    else if (lower.includes("mouse"))
                        icon = "mouse";

                    pairedModel.append({
                        mac: mac,
                        name: name,
                        icon: icon
                    });
                }
            }
        }
    }

    function refresh(): void {
        connModel.clear();
        pairedModel.clear();
        Sys.refreshBt();
        if (!connDevicesProc.running) connDevicesProc.running = true;
        if (!pairedDevicesProc.running) pairedDevicesProc.running = true;
    }

    function toggleScan(): void {
        btPopupRoot.isScanning = !btPopupRoot.isScanning;
        Quickshell.execDetached(["bluetoothctl", "scan", btPopupRoot.isScanning ? "on" : "off"]);
        if (btPopupRoot.isScanning) {
            scanStopTimer.restart();
        }
    }

    Timer {
        id: scanStopTimer
        interval: 15000
        repeat: false
        onTriggered: {
            if (btPopupRoot.isScanning) {
                btPopupRoot.isScanning = false;
                Quickshell.execDetached(["bluetoothctl", "scan", "off"]);
                btPopupRoot.refresh();
            }
        }
    }

    Component.onCompleted: refresh()

    Connections {
        target: PopupState
        function onActivePopupChanged() {
            if (PopupState.activePopup === "bluetooth") {
                btPopupRoot.refresh();
            }
        }
    }

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 12

        // 1. Header with Bluetooth Master Toggle Switch
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
                    color: Sys.btEnabled ? Theme.accent : Theme.dim
                    text: Sys.btEnabled ? "bluetooth" : "bluetooth_disabled"
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
                    text: "Bluetooth"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    color: Theme.dim
                    text: Sys.btEnabled ? (Sys.btConnectedCount > 0 ? `${Sys.btConnectedCount} device connected` : "Ready to connect") : "Bluetooth is Off"
                }
            }

            // Master Bluetooth Power Switch
            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 24
                radius: 12
                color: Sys.btEnabled ? Theme.accent : Theme.surfaceVariant

                Behavior on color { ColorAnimation { duration: Motion.snappy } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    x: Sys.btEnabled ? parent.width - width - 3 : 3

                    Behavior on x {
                        SpringAnimation {
                            spring: 3.0
                            damping: 0.70
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Sys.toggleBluetooth();
                        btPopupRoot.refresh();
                    }
                }
            }
        }

        // 2. Connected Devices Hero Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Sys.btEnabled && connModel.count > 0

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.dim
                text: "CONNECTED DEVICES"
            }

            Repeater {
                model: connModel

                delegate: Rectangle {
                    required property var model
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 10
                    color: Theme.cardBg
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: Theme.accent

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontIcons
                                font.pixelSize: 18
                                color: Theme.textOnPrimary
                                text: model.icon
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: Theme.text
                                text: model.name
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 6

                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: Theme.signalLed
                                }

                                Text {
                                    font.family: Theme.fontPrimary
                                    font.pixelSize: 10
                                    color: Theme.accent
                                    text: "Connected"
                                }

                                Text {
                                    font.family: Theme.fontPrimary
                                    font.pixelSize: 10
                                    color: Theme.dim
                                    visible: Sys.btBattery > 0
                                    text: `• Battery ${Sys.btBattery}%`
                                }
                            }
                        }

                        // Disconnect Button
                        Rectangle {
                            Layout.preferredWidth: discBtnText.implicitWidth + 14
                            Layout.preferredHeight: 24
                            radius: 6
                            color: discMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                            border.color: Theme.cardBorder
                            border.width: 1

                            Text {
                                id: discBtnText
                                anchors.centerIn: parent
                                font.family: Theme.fontPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: Theme.dim
                                text: "Disconnect"
                            }

                            MouseArea {
                                id: discMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Sys.disconnectBt(model.mac);
                                    connModel.remove(model.index);
                                    btPopupRoot.refresh();
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. Paired Devices Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Sys.btEnabled && pairedModel.count > 0

            RowLayout {
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.dim
                    text: "PAIRED DEVICES"
                }

                Item { Layout.fillWidth: true }

                // Scan / Pair button
                Rectangle {
                    Layout.preferredWidth: scanBtnText.implicitWidth + 14
                    Layout.preferredHeight: 22
                    radius: 6
                    color: scanMouse.containsMouse ? Theme.chipHover : (btPopupRoot.isScanning ? Theme.accent : Theme.chipBg)
                    border.color: Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        id: scanBtnText
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 12
                            color: btPopupRoot.isScanning ? Theme.textOnPrimary : Theme.accent
                            text: btPopupRoot.isScanning ? "sensors" : "refresh"
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: btPopupRoot.isScanning ? Theme.textOnPrimary : Theme.text
                            text: btPopupRoot.isScanning ? "Scanning..." : "Scan"
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btPopupRoot.toggleScan()
                    }
                }
            }

            Repeater {
                model: pairedModel

                delegate: Rectangle {
                    required property var model
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 8
                    color: pairedItemMouse.containsMouse ? Theme.chipHover : Theme.cardBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: Theme.dim
                            text: model.icon
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Theme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            text: model.name
                        }

                        // Connect Button
                        Rectangle {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 22
                            radius: 6
                            color: Theme.chipBg
                            border.color: Theme.cardBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: Theme.accent
                                text: "Connect"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Sys.connectBt(model.mac);
                                    btPopupRoot.refresh();
                                }
                            }
                        }

                        // Forget / Remove Button
                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontIcons
                                font.pixelSize: 14
                                color: Theme.dim
                                text: "close"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Sys.removeBt(model.mac);
                                    pairedModel.remove(model.index);
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: pairedItemMouse
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                    }
                }
            }
        }

        // Empty state when Bluetooth is on but no paired or connected devices
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            font.family: Theme.fontPrimary
            font.pixelSize: 11
            color: Theme.dim
            visible: Sys.btEnabled && connModel.count === 0 && pairedModel.count === 0
            text: "No paired Bluetooth devices"
        }

        // 4. Footer Quick Action
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: bluemanMouse.containsMouse ? Theme.chipHover : Theme.chipBg
            border.color: Theme.cardBorder
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                    color: Theme.accent
                    text: "bluetooth_searching"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.text
                    text: "Open Bluetooth Manager (GUI)"
                }
            }

            MouseArea {
                id: bluemanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["blueman-manager"]);
                    PopupState.close();
                }
            }
        }
    }
}
