import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

// Right-edge app fan. Icons rise along a vertical arc with the hero
// centered; Up/Down glide, Left launches, Right/Esc dismisses,
// wheel scrolls, click launches.
PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "onix-launcher"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int sel: LauncherState.sel
    property bool open: false
    property bool motionOK: true
    property int count: DesktopEntries.applications?.values.length ?? 0

    property real step: 0.1571
    property real arcr: Math.min(height * 0.75, 1000)
    property real cyy: height / 2
    property real cxx: (width - 100) + arcr
    property real iconS: 64
    property real selScale: 1.5

    function entryAt(i: int): var {
        if (i < 0 || i >= count)
            return null;
        return DesktopEntries.applications.values[i];
    }

    function rel(i: int): int {
        if (count === 0)
            return 0;
        var k = (((i - sel) % count) + count) % count;
        if (k > count / 2)
            k -= count;
        return k;
    }

    function move(d: int): void {
        if (count === 0 || !open)
            return;
        sel = (((sel + d) % count) + count) % count;
        LauncherState.sel = sel;
    }

    function launchEntry(entry: var): void {
        if (!open || !entry)
            return;
        entry.execute();
        open = false;
        closeTimer.restart();
    }

    function launchSel(): void {
        launchEntry(entryAt(sel));
    }

    function close(): void {
        if (!open)
            LauncherState.open = false;
        open = false;
        closeTimer.restart();
    }

    function stagger(k: int): int {
        if (!motionOK)
            return 0;
        var a = Math.min(Math.abs(k), 3);
        return open ? a * 70 : (3 - a) * 50;
    }

    Timer {
        id: closeTimer
        interval: root.motionOK ? 800 : 50
        repeat: false
        onTriggered: LauncherState.open = false
    }

    Process {
        id: animCheck
        command: ["hyprctl", "getoption", "animations:enabled"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.indexOf("int: 0") !== -1)
                    root.motionOK = false;
                root.open = true;
            }
        }
        onExited: {
            if (!root.open)
                root.open = true;
        }
    }

    Timer {
        id: openFallback
        interval: 500
        repeat: false
        onTriggered: {
            if (!root.open)
                root.open = true;
        }
    }

    Shortcut {
        sequence: "Up"
        enabled: root.open
        onActivated: root.move(-1)
    }
    Shortcut {
        sequence: "Down"
        enabled: root.open
        onActivated: root.move(1)
    }
    Shortcut {
        sequence: "Left"
        enabled: root.open
        onActivated: root.launchSel()
    }
    Shortcut {
        sequence: "Return"
        enabled: root.open
        onActivated: root.launchSel()
    }
    Shortcut {
        sequence: "Right"
        enabled: root.open
        onActivated: root.close()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.close()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        onClicked: root.close()
        onWheel: wheel => root.move(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    Repeater {
        model: root.count

        delegate: Rectangle {
            required property int index
            property int k: root.rel(index)
            property var entry: root.entryAt(index)
            property real theta: k * root.step
            property real u: root.open ? 1 : 0
            property real eu: 1 - Math.pow(1 - u, 3)
            property real rr: 120 + (root.arcr - 120) * eu

            width: root.iconS
            height: root.iconS
            color: "#0F0F0F"
            border.width: k === 0 ? 2 : 1
            border.color: k === 0 ? "#F2F2F2" : "#2B2B2B"
            radius: 14

            x: root.cxx - rr * Math.cos(theta) - width / 2
            y: root.cyy + rr * Math.sin(theta) - height / 2
            z: 10 - Math.abs(k)
            opacity: root.open ? Math.max(0.25, 1 - 0.16 * Math.abs(k)) : 0
            scale: (k === 0 ? root.selScale : Math.max(0.72, 1 - 0.07 * Math.abs(k))) * (0.55 + 0.45 * eu)
            rotation: (theta * 180 / Math.PI) * 0.8 * eu

            Behavior on u {
                SequentialAnimation {
                    PauseAnimation {
                        duration: root.stagger(k)
                    }
                    NumberAnimation {
                        duration: root.motionOK ? 550 : 0
                    }
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: root.motionOK ? 110 : 0
                }
            }

            property string iconSrc: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""

            IconImage {
                anchors.fill: parent
                anchors.margins: 10
                source: iconSrc
            }

            Text {
                anchors.centerIn: parent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                font.bold: true
                color: "#F2F2F2"
                text: entry ? entry.name.charAt(0).toUpperCase() : ""
                visible: iconSrc === ""
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launchEntry(entry)
            }
        }
    }

    Text {
        x: root.cxx - root.arcr - root.iconS * root.selScale / 2 - 12 - width
        y: root.cyy - height / 2
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: "#F2F2F2"
        opacity: root.open ? 0.85 : 0
        text: {
            var e = root.entryAt(root.sel);
            return e ? e.name : "";
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.motionOK ? 110 : 0
            }
        }
    }

    Component.onCompleted: {
        sel = LauncherState.sel;
        animCheck.running = true;
        openFallback.restart();
    }
}
