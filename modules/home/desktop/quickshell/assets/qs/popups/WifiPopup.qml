import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.services
import qs.theme

// Caelestia / Dynamic Island Full-Featured Wi-Fi Pop-up
Rectangle {
    id: root
    width: 360
    implicitHeight: mainCol.implicitHeight + 28
    height: implicitHeight

    property bool embedded: false

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

    // Wi-Fi Networks Model
    ListModel {
        id: wifiListModel
    }

    property string connectingSsid: ""
    property string wifiPassword: ""

    // Wi-Fi Scanning Process
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
                    if (!ssid || ssid === "--") return;
                    const signal = parseInt(parts[1], 10) || 50;
                    const sec = parts[2];
                    const inUse = parts[3] === "*";

                    // Deduplicate
                    for (let i = 0; i < wifiListModel.count; i++) {
                        if (wifiListModel.get(i).ssid === ssid) {
                            if (inUse) wifiListModel.setProperty(i, "inUse", true);
                            return;
                        }
                    }

                    let icon = "signal_wifi_4_bar";
                    if (signal < 25) icon = "network_wifi_1_bar";
                    else if (signal < 50) icon = "network_wifi_2_bar";
                    else if (signal < 75) icon = "network_wifi_3_bar";

                    wifiListModel.append({
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

    function scan(): void {
        wifiListModel.clear();
        Sys.refreshWifi();
        if (!wifiScanProc.running) {
            wifiScanProc.running = true;
        }
    }

    Component.onCompleted: scan()

    Connections {
        target: PopupState
        function onActivePopupChanged() {
            if (PopupState.activePopup === "wifi" || PopupState.activePopup === "network") {
                root.scan();
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

        // 1. Header with Wi-Fi Master Toggle Switch
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
                    color: Sys.wifiEnabled ? Theme.accent : Theme.dim
                    text: Sys.wifiEnabled ? "wifi" : "wifi_off"
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
                    text: "Wi-Fi Networks"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    color: Theme.dim
                    text: Sys.wifiEnabled ? (Sys.wifiConnected ? `Connected to ${Sys.wifiSsid}` : "Disconnected") : "Wi-Fi is Off"
                }
            }

            // Master Wi-Fi Power Switch
            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 24
                radius: 12
                color: Sys.wifiEnabled ? Theme.accent : Theme.surfaceVariant

                Behavior on color { ColorAnimation { duration: Motion.snappy } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    x: Sys.wifiEnabled ? parent.width - width - 3 : 3

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
                    onClicked: Sys.toggleWifi()
                }
            }
        }

        // 2. Active Connected Wi-Fi Card (Hero visual)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 12
            color: Theme.cardBg
            border.color: Sys.wifiConnected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40) : Theme.cardBorder
            border.width: 1
            visible: Sys.wifiEnabled && Sys.wifiConnected

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcons
                        font.pixelSize: 20
                        color: Theme.accent
                        text: "signal_wifi_4_bar"
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6
                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Theme.text
                            text: Sys.wifiSsid
                        }

                        Rectangle {
                            radius: 4
                            color: Theme.chipBg
                            implicitWidth: sigText.implicitWidth + 8
                            implicitHeight: 16

                            Text {
                                id: sigText
                                anchors.centerIn: parent
                                font.family: Theme.fontPrimary
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: Theme.accent
                                text: `${Sys.wifiSignal}%`
                            }
                        }
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 10
                        color: Theme.dim
                        text: Sys.wifiIp ? `IP: ${Sys.wifiIp}` : "Active Interface: wlp0s20f3"
                    }
                }

                // Disconnect Button
                Rectangle {
                    Layout.preferredWidth: discText.implicitWidth + 14
                    Layout.preferredHeight: 24
                    radius: 6
                    color: discMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    Text {
                        id: discText
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
                        onClicked: Sys.disconnectWifi()
                    }
                }
            }
        }

        // 3. Inline Password Input Dialog (when user clicked Connect on a secured network)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 82
            radius: 10
            color: Theme.cardBg
            border.color: Theme.accent
            border.width: 1
            visible: root.connectingSsid.length > 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.accent
                    text: `Connect to "${root.connectingSsid}"`
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 6
                        color: Theme.surfaceVariant
                        border.color: Theme.cardBorder
                        border.width: 1

                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            color: Theme.text
                            echoMode: TextInput.Password
                            selectByMouse: true
                            onAccepted: joinBtn.clicked()

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                color: Theme.dim
                                text: "Enter Wi-Fi Password..."
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Join Button
                    Rectangle {
                        id: joinBtn
                        signal clicked
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 26
                        radius: 6
                        color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.textOnPrimary
                            text: "Join"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Sys.connectWifi(root.connectingSsid, passInput.text);
                                root.connectingSsid = "";
                                passInput.text = "";
                            }
                        }
                    }

                    // Cancel Button
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 6
                        color: Theme.chipBg
                        border.color: Theme.cardBorder
                        border.width: 1

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
                                root.connectingSsid = "";
                                passInput.text = "";
                            }
                        }
                    }
                }
            }
        }

        // 4. Available Networks Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Sys.wifiEnabled

            RowLayout {
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.dim
                    text: "AVAILABLE NETWORKS"
                }

                Item { Layout.fillWidth: true }

                // Scan / Refresh Button
                Rectangle {
                    Layout.preferredWidth: scanText.implicitWidth + 12
                    Layout.preferredHeight: 22
                    radius: 6
                    color: scanMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        id: scanText
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 12
                            color: wifiScanProc.running ? Theme.accent : Theme.text
                            text: "refresh"

                            NumberAnimation on rotation {
                                from: 0; to: 360; duration: 900
                                loops: Animation.Infinite
                                running: wifiScanProc.running
                            }
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: Theme.text
                            text: "Scan"
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.scan()
                    }
                }
            }

            // Networks List
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: wifiListModel

                    delegate: Rectangle {
                        required property var model
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 8
                        color: netMouse.containsMouse ? Theme.chipHover : Theme.cardBg
                        border.color: model.inUse ? Theme.accent : Theme.cardBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                font.family: Theme.fontIcons
                                font.pixelSize: 16
                                color: model.inUse ? Theme.accent : Theme.dim
                                text: model.icon
                            }

                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 12
                                font.weight: model.inUse ? Font.Bold : Font.Medium
                                color: Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                text: model.ssid
                            }

                            Text {
                                font.family: Theme.fontIcons
                                font.pixelSize: 13
                                color: Theme.dim
                                visible: model.secured
                                text: "lock"
                            }

                            // Connect / Connected Action
                            Rectangle {
                                Layout.preferredWidth: model.inUse ? 68 : 56
                                Layout.preferredHeight: 22
                                radius: 6
                                color: model.inUse ? Theme.accent : Theme.chipBg
                                border.color: model.inUse ? Theme.accent : Theme.cardBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontPrimary
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: model.inUse ? Theme.textOnPrimary : Theme.text
                                    text: model.inUse ? "Connected" : "Connect"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !model.inUse
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (model.secured) {
                                            root.connectingSsid = model.ssid;
                                        } else {
                                            Sys.connectWifi(model.ssid, "");
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                        }
                    }
                }

                // Empty Placeholder
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    color: Theme.dim
                    visible: wifiListModel.count === 0
                    text: wifiScanProc.running ? "Scanning for nearby networks..." : "No Wi-Fi networks found"
                }
            }
        }

        // 5. Footer Quick Actions
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: nmtuiMouse.containsMouse ? Theme.chipHover : Theme.chipBg
            border.color: Theme.cardBorder
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                    color: Theme.accent
                    text: "settings"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.text
                    text: "Open Network Connections (GUI)"
                }
            }

            MouseArea {
                id: nmtuiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["nm-connection-editor"]);
                    PopupState.close();
                }
            }
        }
    }
}
