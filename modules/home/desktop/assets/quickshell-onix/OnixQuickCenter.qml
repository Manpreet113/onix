// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixQuickCenter: control sidebar (ports upstream QuickCenter). Notification
// history on top, volume + brightness M3 sliders, and power / settings /
// clear-all controls at the bottom. Docks to the systray bar's side like
// upstream; slides in from that edge. Toggle with
// `ipc call onixQuickCenter toggle`.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: OnixUi.quickCenterOpen
    focusable: true

    readonly property int trayBarId: OnixSettings.get(["interface", "modules", "bar_id", "systeminfotray"], 0)
    readonly property string traySide: OnixSettings.get(["interface", trayBarId === 0 ? "bar" : "bar2", "side"], "bottom")
    readonly property int trayLoc: OnixSettings.get(["interface", "modules", "location", "systeminfotray"], 2)
    // vertical bars dock to their own edge; horizontal bars to the location side
    readonly property string dockSide: (traySide === "left" || traySide === "right") ? traySide : (trayLoc === 0 ? "left" : "right")
    readonly property bool alignStart: root.dockSide === "left" || root.dockSide === "top"

    property bool shown: false
    onVisibleChanged: {
        if (visible) {
            root.shown = false;
            showTimer.restart();
            volPoll.running = true;
            brightPoll.running = true;
            brightMaxProc.running = true;
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
        onTriggered: OnixUi.quickCenterOpen = false
    }

    Keys.onEscapePressed: root.close()

    // ---- volume + brightness state ----

    property real volLevel: 0
    property bool volBusy: false
    property real brightLevel: 0
    property real brightMax: 100
    property bool brightBusy: false
    property bool hasBright: true

    Process {
        id: volPoll
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var m = this.text.trim().match(/Volume:\s*([0-9.]+)/);
                if (m && !root.volBusy)
                    root.volLevel = Math.min(1, parseFloat(m[1])) * 100;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: brightMaxProc
        command: ["brightnessctl", "max"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var v = parseInt(this.text.trim(), 10);
                if (isNaN(v) || v <= 0)
                    root.hasBright = false;
                else
                    root.brightMax = v;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.hasBright = false
        }
    }

    Process {
        id: brightPoll
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var v = parseInt(this.text.trim(), 10);
                if (!isNaN(v) && !root.brightBusy && root.brightMax > 0)
                    root.brightLevel = Math.min(100, (v / root.brightMax) * 100);
            }
        }
        stderr: StdioCollector {
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: {
            volPoll.running = true;
            if (root.hasBright)
                brightPoll.running = true;
        }
    }

    IpcHandler {
        target: "onixQuickCenter"
        function toggle(): void {
            OnixUi.toggleQuickCenter();
        }
        function open(): void {
            OnixUi.quickCenterOpen = true;
        }
        function close(): void {
            root.close();
        }
    }

    anchors {
        top: true
        bottom: true
        left: root.dockSide === "left"
        right: root.dockSide === "right"
    }
    implicitWidth: 410
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: root.alignStart ? parent.left : undefined
            right: root.alignStart ? undefined : parent.right
        }
        width: 400
        anchors.margins: 5
        color: OnixTheme.mSurfaceDim
        radius: 20
        border.color: Qt.rgba(OnixTheme.mOutlineVariant.r, OnixTheme.mOutlineVariant.g, OnixTheme.mOutlineVariant.b, 0.5)
        border.width: 1

        x: root.shown ? 0 : (root.alignStart ? -40 : 40)
        opacity: root.shown ? 1 : 0
        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // notification history
            Flickable {
                width: parent.width
                height: Math.min(380, historyCol.implicitHeight)
                contentHeight: historyCol.implicitHeight
                clip: true

                Column {
                    id: historyCol
                    width: parent.width
                    spacing: 6

                    Column {
                        visible: OnixNotifHistory.items.length === 0
                        width: parent.width
                        spacing: 5
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "notifications_off"
                            color: OnixTheme.mOnSurfaceVariant
                            font.family: OnixTheme.iconFont
                            font.pixelSize: 48
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No notifications"
                            color: OnixTheme.mOnSurfaceVariant
                            font.pixelSize: OnixTheme.fontMed
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: OnixNotifHistory.items
                        delegate: OnixNotifCard {
                            required property var modelData
                            required property int index
                            width: historyCol.width
                            implicitWidth: historyCol.width
                            summary: modelData.summary
                            body: modelData.body
                            iconName: modelData.appIcon
                            born: modelData.born
                            compact: false
                            actions: null
                            onDismissed: OnixNotifHistory.removeAt(index)
                        }
                    }
                }
            }

            // sliders
            Column {
                width: parent.width
                spacing: 2

                M3Slider {
                    icon: "volume_up"
                    from: 0
                    to: 100
                    step: 1
                    value: root.volLevel
                    width: parent.width
                    onMoved: value => {
                        root.volBusy = true;
                        root.volLevel = value;
                        OnixUi.osdSuppress = true;
                        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)]);
                    }
                    onInteractionDone: {
                        root.volBusy = false;
                        OnixUi.osdSuppress = false;
                        volPoll.running = true;
                    }
                }

                M3Slider {
                    visible: root.hasBright
                    icon: "brightness_6"
                    from: 0
                    to: 100
                    step: 1
                    value: root.brightLevel
                    width: parent.width
                    onMoved: value => {
                        root.brightBusy = true;
                        root.brightLevel = value;
                        OnixUi.osdSuppress = true;
                        Quickshell.execDetached(["brightnessctl", "set", Math.round(value) + "%"]);
                    }
                    onInteractionDone: {
                        root.brightBusy = false;
                        OnixUi.osdSuppress = false;
                        brightPoll.running = true;
                    }
                }
            }

            // bottom controls
            Row {
                width: parent.width
                spacing: 5

                M3Button {
                    btnType: "tonal"
                    size: "xs"
                    icon: "power_settings_new"
                    onClicked: {
                        root.close();
                        OnixUi.togglePower();
                    }
                }
                M3Button {
                    btnType: "tonal"
                    size: "xs"
                    icon: "settings"
                    onClicked: {
                        root.close();
                        OnixUi.toggleSettings();
                    }
                }
                Item {
                    width: 10
                    height: 10
                }
                M3Button {
                    visible: OnixNotifHistory.items.length > 0
                    btnType: "text"
                    size: "xs"
                    icon: "clear_all"
                    label: "Clear all"
                    onClicked: {
                        OnixNotifHistory.clear();
                        OnixUi.clearPopupsRequested();
                    }
                }
            }
        }
    }
}
