// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixOsd: volume / brightness on-screen display (ports upstream OSD).
// Position + orientation come from OnixSettings.services.osd; like upstream
// it pops up on its own whenever the level actually changes (1s poll over
// wpctl / brightnessctl) and also answers `ipc call osd volume|brightness`
// for the keybinds. Auto-hides 2s after the last change.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: false
    focusable: false

    readonly property var anchorNames: OnixSettings.get(["services", "osd", "anchor"], ["bottom", "right"])
    readonly property bool anchorTop: anchorNames.indexOf("top") >= 0
    readonly property bool anchorBottom: anchorNames.indexOf("bottom") >= 0
    readonly property bool anchorLeft: anchorNames.indexOf("left") >= 0
    readonly property bool anchorRight: anchorNames.indexOf("right") >= 0
    readonly property bool singleSide: anchorNames.length === 1
    readonly property bool vertical: {
        if (!singleSide)
            return OnixSettings.get(["services", "osd", "vertical"], false);
        if (anchorTop || anchorBottom)
            return false;
        return true;
    }

    anchors {
        top: root.anchorTop
        bottom: root.anchorBottom
        left: root.anchorLeft
        right: root.anchorRight
    }
    margins {
        top: 20
        bottom: 20
        left: 20
        right: 20
    }
    implicitWidth: root.vertical ? 76 : 264
    implicitHeight: root.vertical ? 264 : 76
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property string kind: "volume"
    property real level: 0
    property bool muted: false
    // set via OnixUi.osdSuppress while quickcenter sliders drag so the OSD
    // doesn't double up (upstream suppress_osd flag behavior)
    readonly property bool suppress: OnixUi.osdSuppress
    property real lastVol: -1
    property real lastBright: -1

    function showVolume(): void {
        root.kind = "volume";
        volProc.running = true;
    }

    function showBrightness(): void {
        root.kind = "brightness";
        brightProc.running = true;
    }

    function poke(): void {
        if (root.suppress)
            return;
        root.visible = true;
        card.opacity = 1;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: card.opacity = 0
    }

    // reveal + crossfade, like upstream's 250ms crossfade revealer
    Rectangle {
        id: card
        anchors.centerIn: parent
        implicitWidth: root.vertical ? 76 : 264
        implicitHeight: root.vertical ? 264 : 76
        color: OnixTheme.mSurfaceContainer
        radius: OnixTheme.radiusLarge
        border.color: OnixTheme.mOutlineVariant
        border.width: 1
        opacity: 0
        onOpacityChanged: {
            if (opacity === 0)
                zeroTimer.restart();
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        Timer {
            id: zeroTimer
            interval: 260
            repeat: false
            onTriggered: {
                if (card.opacity === 0)
                    root.visible = false;
            }
        }

        Column {
            id: colLayout
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.kind === "brightness" ? "brightness_medium" : (root.muted ? "volume_off" : "volume_up")
                color: OnixTheme.mOnSurface
                font.family: OnixTheme.iconFont
                font.pixelSize: 24
            }
            Item {
                width: 20
                height: 200
                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: parent.height
                    radius: 3
                    color: OnixTheme.mSecondaryContainer
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * (1 - root.level)
                    width: 6
                    height: parent.height * root.level
                    radius: 3
                    color: OnixTheme.mPrimary
                    Behavior on y {
                        NumberAnimation {
                            duration: OnixTheme.fadeFast
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: OnixTheme.fadeFast
                        }
                    }
                }
            }
        }

        Row {
            id: rowLayout
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.kind === "brightness" ? "brightness_medium" : (root.muted ? "volume_off" : "volume_up")
                color: OnixTheme.mOnSurface
                font.family: OnixTheme.iconFont
                font.pixelSize: 24
            }
            Item {
                width: 200
                height: 20
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: OnixTheme.mSecondaryContainer
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.level
                    height: 6
                    radius: 3
                    color: OnixTheme.mPrimary
                    Behavior on width {
                        NumberAnimation {
                            duration: OnixTheme.fadeFast
                        }
                    }
                }
            }
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var l = this.text.trim();
                var m = l.match(/Volume:\s*([0-9.]+)/);
                root.level = m ? Math.min(1, parseFloat(m[1])) : 0;
                root.muted = l.indexOf("MUTED") >= 0;
                root.poke();
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var parts = this.text.trim().split(",");
                var pct = parts.length >= 4 ? parseFloat(parts[3]) : NaN;
                root.level = isNaN(pct) ? 0 : Math.min(1, pct / 100);
                root.muted = false;
                root.poke();
            }
        }
        stderr: StdioCollector {
        }
    }

    // upstream auto-show: poll levels, pop up only on real change
    Process {
        id: volWatch
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var l = this.text.trim();
                var m = l.match(/Volume:\s*([0-9.]+)/);
                var v = m ? Math.min(1, parseFloat(m[1])) : -1;
                var mu = l.indexOf("MUTED") >= 0;
                if (v !== root.lastVol || mu !== root.lastMuted) {
                    root.lastVol = v;
                    root.lastMuted = mu;
                    if (root.lastVol >= 0) {
                        root.kind = "volume";
                        root.level = v;
                        root.muted = mu;
                        root.poke();
                    }
                }
            }
        }
        stderr: StdioCollector {
        }
    }

    property bool lastMuted: false

    Process {
        id: brightWatch
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var parts = this.text.trim().split(",");
                var pct = parts.length >= 4 ? parseFloat(parts[3]) : NaN;
                var v = isNaN(pct) ? -1 : Math.min(1, pct / 100);
                if (v !== root.lastBright) {
                    root.lastBright = v;
                    if (v >= 0) {
                        root.kind = "brightness";
                        root.level = v;
                        root.muted = false;
                        root.poke();
                    }
                }
            }
        }
        stderr: StdioCollector {
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volWatch.running = true;
            brightWatch.running = true;
        }
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
}
