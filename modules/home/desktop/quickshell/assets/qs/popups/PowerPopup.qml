import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.theme

// Ambxst / Caelestia Inspired Floating Power & Session Pop-up
Rectangle {
    id: root
    width: 320
    implicitHeight: mainCol.implicitHeight + 28
    height: implicitHeight

    property bool embedded: false

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

    signal actionExecuted()

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 12

        // Header
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

                OnixLogo {
                    anchors.centerIn: parent
                    size: 20
                    color: Theme.error
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
                    text: "Onix Session"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    color: Theme.dim
                    text: "Select a power action"
                }
            }
        }

        // Action Options
        Repeater {
            model: [
                { id: "lock", label: "Lock Screen", icon: "lock", key: "L", cmd: ["quickshell", "ipc", "-c", "onix", "call", "lock", "lock"], danger: false },
                { id: "suspend", label: "Sleep / Suspend", icon: "bedtime", key: "U", cmd: ["systemctl", "suspend"], danger: false },
                { id: "logout", label: "Log Out", icon: "logout", key: "E", cmd: ["hyprctl", "dispatch", "exit"], danger: false },
                { id: "reboot", label: "Restart", icon: "restart_alt", key: "R", cmd: ["systemctl", "reboot"], danger: false },
                { id: "poweroff", label: "Shut Down", icon: "power_settings_new", key: "S", cmd: ["systemctl", "poweroff"], danger: true }
            ]

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 10
                color: modelData.danger ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Theme.cardBg
                border.color: modelData.danger ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3) : Theme.cardBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 20
                        color: modelData.danger ? Theme.error : Theme.accent
                        text: modelData.icon
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: modelData.danger ? Theme.error : Theme.text
                        text: modelData.label
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 5
                        color: Theme.chipBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.dim
                            text: modelData.key
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(modelData.cmd);
                        root.actionExecuted();
                    }
                }
            }
        }
    }
}
