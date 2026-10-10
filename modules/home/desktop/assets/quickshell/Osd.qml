import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// On-screen display: volume / brightness pill under the bar.
// Trigger via `quickshell --config shell ipc call osd volume|brightness`.
// Auto-hides after a quiet period; retriggering refreshes instantly.
PanelWindow {
    id: root

    visible: false
    focusable: false

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 48
        left: 8
        right: 8
    }
    implicitHeight: 44
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property string kind: "volume"
    property real level: 0
    property bool muted: false

    function showVolume(): void {
        kind = "volume";
        volProc.running = true;
        poke();
    }

    function showBrightness(): void {
        kind = "brightness";
        brightProc.running = true;
        poke();
    }

    function poke(): void {
        visible = true;
        pill.opacity = 1;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: {
            pill.opacity = 0;
            fadeTimer.restart();
        }
    }

    Timer {
        id: fadeTimer
        interval: Theme.fadeMed
        repeat: false
        onTriggered: root.visible = false
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { onStreamFinished: () => {
            var l = this.text.trim();
            var m = l.match(/Volume:\s*([0-9.]+)/);
            root.level = m ? Math.min(1, parseFloat(m[1])) : 0;
            root.muted = l.indexOf("MUTED") >= 0;
            root.poke();
        } }
        stderr: StdioCollector {}
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector { onStreamFinished: () => {
            var parts = this.text.trim().split(",");
            var pct = parts.length >= 4 ? parseFloat(parts[3]) : NaN;
            root.level = isNaN(pct) ? 0 : Math.min(1, pct / 100);
            root.muted = false;
            root.poke();
        } }
        stderr: StdioCollector {}
    }

    IpcHandler {
        target: "osd"
        function volume(): void {
            root.showVolume();
        }
        function brightness(): void {
            root.showBrightness();
        }
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320
        implicitHeight: 44
        color: Theme.bg
        radius: Theme.radiusMed
        border.color: Theme.border
        border.width: 1
        opacity: 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.fadeFast
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: pillRow
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Text {
                id: iconText
                visible: text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (root.kind === "brightness")
                        return "";
                    return root.muted ? "" : "󰕾";
                }
                color: root.kind === "brightness" ? Theme.warning : Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                font.bold: true
            }

            Item {
                width: pillRow.width - iconText.implicitWidth - pctText.implicitWidth - 48
                height: parent.height

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.surface
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.level
                    height: 6
                    radius: 3
                    color: root.kind === "brightness" ? Theme.warning : Theme.primary
                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.fadeFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                id: pctText
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted && root.kind === "volume" ? "muted" : Math.round(root.level * 100) + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
                font.bold: true
            }
        }
    }
}
