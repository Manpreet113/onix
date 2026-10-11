// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWRecIndicator: recording indicator + timer (ports upstream
// RecordingIndicator). Visibility follows the `recording_indicator` option:
// "always" shows the idle icon, "recording" only while OnixRecorder runs.
// Click stops/starts, right-click pauses; recording state turns the pill
// error-container, paused turns it tertiary-container.
import QtQuick

Item {
    id: root

    property int barId: 0

    readonly property string barSec: root.barId === 0 ? "bar" : "bar2"
    readonly property bool vertical: OnixSettings.get(["interface", root.barSec, "vertical"], false)
    readonly property string mode: OnixSettings.get(["interface", "modules", "options", "recording_indicator"], "recording")

    readonly property bool shown: root.mode === "always" || OnixRecorder.active
    property int elapsed: 0

    implicitWidth: root.vertical ? 40 : pill.implicitWidth
    implicitHeight: root.vertical ? pill.implicitHeight : 32
    visible: root.shown

    Timer {
        interval: 1000
        running: OnixRecorder.active && !OnixRecorder.paused
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed = OnixRecorder.elapsedSecs()
    }

    function mmss(): string {
        var m = Math.floor(root.elapsed / 60);
        var s = root.elapsed % 60;
        return (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" + s : "" + s);
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: content.implicitWidth + 20
        implicitHeight: root.vertical ? content.implicitHeight + 10 : 32
        color: {
            if (OnixRecorder.active && OnixRecorder.paused)
                return OnixTheme.mTertiaryContainer;
            if (OnixRecorder.active)
                return OnixTheme.mErrorContainer;
            return "transparent";
        }
        radius: OnixTheme.radiusLarge

        Text {
            visible: !OnixRecorder.active
            anchors.centerIn: parent
            text: "screen_record"
            color: OnixTheme.mOnSurface
            font.family: OnixTheme.iconFont
            font.pixelSize: 20
        }

        Column {
            id: content
            visible: OnixRecorder.active
            anchors.centerIn: parent
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: OnixRecorder.paused ? "pause" : "screen_record"
                color: OnixRecorder.paused ? OnixTheme.mOnTertiaryContainer : OnixTheme.mOnErrorContainer
                font.family: OnixTheme.iconFont
                font.pixelSize: 18
            }
            Text {
                visible: !root.vertical
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.mmss()
                color: OnixRecorder.paused ? OnixTheme.mOnTertiaryContainer : OnixTheme.mOnErrorContainer
                font.pixelSize: OnixTheme.fontSmall
            }
            Text {
                visible: root.vertical
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.floor(root.elapsed / 60) < 10 ? "0" + Math.floor(root.elapsed / 60) : "" + Math.floor(root.elapsed / 60)
                color: OnixRecorder.paused ? OnixTheme.mOnTertiaryContainer : OnixTheme.mOnErrorContainer
                font.pixelSize: OnixTheme.fontSmall
            }
            Text {
                visible: root.vertical
                anchors.horizontalCenter: parent.horizontalCenter
                text: (root.elapsed % 60) < 10 ? "0" + (root.elapsed % 60) : "" + (root.elapsed % 60)
                color: OnixRecorder.paused ? OnixTheme.mOnTertiaryContainer : OnixTheme.mOnErrorContainer
                font.pixelSize: OnixTheme.fontSmall
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    if (OnixRecorder.active)
                        OnixRecorder.togglePause();
                    else
                        OnixRecorder.recordRegion(OnixSettings.get(["services", "recorder", "record_audio"], true));
                } else {
                    if (OnixRecorder.active)
                        OnixRecorder.stopRecording();
                    else if (root.mode === "always")
                        OnixRecorder.recordScreen(OnixSettings.get(["services", "recorder", "record_audio"], true));
                }
            }
        }
    }
}
