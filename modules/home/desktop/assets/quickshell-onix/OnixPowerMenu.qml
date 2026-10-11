// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixPowerMenu: session power grid (ports upstream PowerMenu). Six 150px
// cards: power off, reboot, lock, log out (Niri quit), suspend, restart
// shell. The lock card arms the onix lock screen (lands in P6); until then
// it is a safe no-op. Toggle with `ipc call onixPower toggle`.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: OnixUi.powerOpen
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(OnixTheme.mScrim.r, OnixTheme.mScrim.g, OnixTheme.mScrim.b, 0.6)

    property bool shown: false
    onVisibleChanged: {
        if (visible) {
            root.shown = false;
            showTimer.restart();
        }
    }

    Timer {
        id: showTimer
        interval: 30
        repeat: false
        onTriggered: root.shown = true
    }

    function close(): void {
        root.shown = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 200
        repeat: false
        onTriggered: OnixUi.powerOpen = false
    }

    Keys.onEscapePressed: root.close()

    function run(cmd): void {
        Quickshell.execDetached(cmd);
        root.close();
    }

    IpcHandler {
        target: "onixPower"
        function toggle(): void {
            OnixUi.togglePower();
        }
        function open(): void {
            OnixUi.powerOpen = true;
        }
        function close(): void {
            root.close();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Grid {
        anchors.centerIn: parent
        columns: 3
        columnSpacing: 12
        rowSpacing: 12
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: [
                { icon: "power_settings_new", label: "Power Off", cmd: ["systemctl", "poweroff"] },
                { icon: "restart_alt", label: "Reboot", cmd: ["systemctl", "reboot"] },
                { icon: "lock", label: "Lock Screen", cmd: ["quickshell", "--config", "onix", "ipc", "call", "onixLock", "lock"] },
                { icon: "logout", label: "Log Out", cmd: ["niri", "msg", "action", "quit"] },
                { icon: "dark_mode", label: "Sleep", cmd: ["systemctl", "suspend"] },
                { icon: "frame_reload", label: "Restart Shell", cmd: ["systemctl", "--user", "restart", "quickshell.service"] }
            ]
            delegate: Rectangle {
                required property var modelData
                implicitWidth: 150
                implicitHeight: 150
                color: hover.containsMouse ? OnixTheme.mPrimaryContainer : OnixTheme.mSurfaceContainer
                radius: 20
                border.color: OnixTheme.mOutlineVariant
                border.width: 1
                Behavior on color {
                    NumberAnimation {
                        duration: OnixTheme.fadeFast
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.icon
                        color: hover.containsMouse ? OnixTheme.mOnPrimaryContainer : OnixTheme.mOnSurface
                        font.family: OnixTheme.iconFont
                        font.pixelSize: 40
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: hover.containsMouse ? OnixTheme.mOnPrimaryContainer : OnixTheme.mOnSurface
                        font.pixelSize: OnixTheme.fontMed
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.run(modelData.cmd)
                }
            }
        }
    }

    // NOTE: the Lock Screen card targets `onixLock`, which lands with the
    // lock screen in P6; until then it is a safe no-op.
}
