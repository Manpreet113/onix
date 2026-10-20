import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.components
import qs.theme

// Ambxst / Caelestia Inspired Power & Battery Pop-up
Rectangle {
    id: root
    width: 340
    implicitHeight: mainCol.implicitHeight + 28
    height: implicitHeight

    property bool embedded: false
    property real pctRaw: UPower.displayDevice?.percentage ?? 0
    property real pct: pctRaw > 1 ? pctRaw : pctRaw * 100
    property bool charging: {
        const s = UPower.displayDevice?.state;
        return s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged;
    }

    property string currentProfile: "balanced"

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

    // Power Profiles Process
    Process {
        id: profileGetProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim();
                if (p) root.currentProfile = p;
            }
        }
    }

    function checkProfile(): void {
        if (!profileGetProc.running)
            profileGetProc.running = true;
    }

    Component.onCompleted: checkProfile()

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
                    color: root.charging ? Theme.signalLed : (root.pct <= 20 ? Theme.error : Theme.accent)
                    text: root.charging ? "battery_charging_full" : (root.pct <= 20 ? "battery_alert" : "battery_full")
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
                    text: "Power & Battery"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    color: Theme.dim
                    text: root.charging ? "Connected to Power Supply" : "Running on Battery"
                }
            }
        }

        // 2. Hero Battery Gauge Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            radius: 14
            color: Theme.cardBg
            border.color: Theme.cardBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 30
                        font.weight: Font.ExtraBold
                        color: Theme.text
                        text: Math.round(root.pct) + "%"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        radius: 6
                        color: root.charging ? Qt.rgba(0, 0.9, 0.46, 0.15) : Theme.chipBg
                        border.color: root.charging ? Theme.signalLed : Theme.cardBorder
                        border.width: 1
                        implicitWidth: statusText.implicitWidth + 14
                        implicitHeight: 24

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: root.charging ? Theme.signalLed : Theme.dim
                            }

                            Text {
                                id: statusText
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: root.charging ? Theme.signalLed : Theme.subtext
                                text: root.charging ? "Charging" : (root.pct >= 98 ? "Fully Charged" : "Discharging")
                            }
                        }
                    }
                }

                // Smooth Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Theme.surfaceVariant

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        radius: 4
                        width: Math.max(0, Math.min(parent.width, parent.width * (root.pct / 100.0)))
                        color: root.charging ? Theme.signalLed : (root.pct <= 20 ? Theme.error : Theme.accent)

                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
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

        // 3. Power Profiles Selector
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.dim
                text: "PERFORMANCE MODE"
            }

            Repeater {
                model: [
                    { id: "performance", label: "Performance", icon: "rocket_launch", sub: "Maximum system performance" },
                    { id: "balanced", label: "Balanced", icon: "balance", sub: "Standard balance of power & speed" },
                    { id: "power-saver", label: "Power Saver", icon: "energy_savings_leaf", sub: "Lower power consumption" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isActive: root.currentProfile === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 10
                    color: isActive ? Theme.chipHover : Theme.cardBg
                    border.color: isActive ? Theme.accent : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 20
                            color: isActive ? Theme.accent : Theme.dim
                            text: modelData.icon
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 12
                                font.weight: isActive ? Font.Bold : Font.DemiBold
                                color: isActive ? Theme.text : Theme.subtext
                                text: modelData.label
                            }

                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 10
                                color: Theme.dim
                                text: modelData.sub
                            }
                        }

                        // Radio indicator
                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: isActive ? Theme.accent : "transparent"
                            border.color: isActive ? Theme.accent : Theme.dim
                            border.width: 1.5

                            Rectangle {
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.textOnPrimary
                                visible: isActive
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentProfile = modelData.id;
                            Quickshell.execDetached(["powerprofilesctl", "set", modelData.id]);
                        }
                    }
                }
            }
        }
    }
}
