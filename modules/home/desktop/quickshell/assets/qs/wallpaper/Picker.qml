import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Bottom-emerging arc wallpaper picker. Thumbnails rise from the bottom
// edge and settle along an upward-facing semicircular fan; Left/Right
// rotate, Up applies live, Down/Esc restores and retracts.
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
    mask: Region {}
    WlrLayershell.namespace: "onix-picker"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property int sel: 0
    property string appliedPath: ""
    property bool open: false
    property bool motionOK: true
    property int count: WallpaperState.files.count
    property string wipeOld: ""
    property string wipeNew: ""
    property int wipeDir: 1
    property bool wiping: false
    property real wipeP: 0

    property real step: 0.1571
    property real arcr: Math.min(width * 0.75, 1400)
    property real cx: width / 2
    property real cy: (height - 180) + arcr
    property real thumbW: 200
    property real thumbH: 125
    property real selScale: 1.6

    function indexOf(path: string): int {
        for (var i = 0; i < count; i++)
            if (fileAt(i) === path)
                return i;
        return -1;
    }

    function fileAt(i: int): string {
        if (i < 0 || i >= count)
            return "";
        return WallpaperState.files.get(i, "filePath");
    }

    function rel(i: int): int {
        if (count === 0)
            return 0;
        var k = (((i - sel) % count) + count) % count;
        if (k > count / 2)
            k -= count;
        return k;
    }

    function thumbFor(path: string): string {
        if (!WallpaperState.isVideo(path) || path.length === 0)
            return path.length > 0 ? WallpaperState.fileUrl(path) : "";
        var base = path.split("/").pop().replace(/\.[^.]+$/, "");
        return "file://" + Quickshell.env("HOME") + "/.cache/onix-shell/thumbs/" + base + ".png";
    }

    function ensureVideoThumbs(): void {
        var cache = Quickshell.env("HOME") + "/.cache/onix-shell/thumbs";
        Quickshell.execDetached(["mkdir", "-p", cache]);
        for (var i = 0; i < count; i++) {
            var p = fileAt(i);
            if (!WallpaperState.isVideo(p))
                continue;
            var base = p.split("/").pop().replace(/\.[^.]+$/, "");
            Quickshell.execDetached(["ffmpeg", "-n", "-loglevel", "error", "-i", p, "-vframes", "1", cache + "/" + base + ".png"]);
        }
    }

    function move(d: int): void {
        if (count === 0 || !open)
            return;
        var oldCenter = fileAt(sel);
        sel = (((sel + d) % count) + count) % count;
        if (wiping)
            wipeOld = wipeNew;
        else
            wipeOld = thumbFor(oldCenter);
        wipeNew = thumbFor(fileAt(sel));
        wipeDir = d > 0 ? 1 : -1;
        WallpaperState.wipeDir = wipeDir;
        wiping = true;
        wipeAnim.restart();
        WallpaperState.set(fileAt(sel));
    }

    function apply(): void {
        if (!open)
            return;
        wiping = false;
        open = false;
        closeTimer.restart();
    }

    function cancel(): void {
        if (!open)
            return;
        if (appliedPath.length > 0)
            WallpaperState.set(appliedPath);
        wiping = false;
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
        onTriggered: WallpaperState.pickerOpen = false
    }

    NumberAnimation {
        id: wipeAnim
        target: root
        property: "wipeP"
        from: 0
        to: 1
        duration: root.motionOK ? 300 : 0
        onFinished: root.wiping = false
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
        sequence: "Left"
        enabled: root.open
        onActivated: root.move(-1)
    }
    Shortcut {
        sequence: "Right"
        enabled: root.open
        onActivated: root.move(1)
    }
    Shortcut {
        sequence: "Up"
        enabled: root.open
        onActivated: root.apply()
    }
    Shortcut {
        sequence: "Return"
        enabled: root.open
        onActivated: root.apply()
    }
    Shortcut {
        sequence: "Down"
        enabled: root.open
        onActivated: root.cancel()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.cancel()
    }

    Repeater {
        model: root.count

        delegate: Rectangle {
            required property int index
            property int k: root.rel(index)
            property string path: root.fileAt(index)
            property real theta: k * root.step
            property real u: root.open ? 1 : 0
            property real eu: 1 - Math.pow(1 - u, 3)
            property real rr: 120 + (root.arcr - 120) * eu

            width: root.thumbW
            height: root.thumbH
            color: "#0F0F0F"
            border.width: k === 0 ? 2 : 1
            border.color: k === 0 ? "#F2F2F2" : "#2B2B2B"
            radius: 8

            x: root.cx + rr * Math.sin(theta) - width / 2
            y: root.cy - rr * Math.cos(theta) - height / 2
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

            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: (k === 0 && root.wiping) ? root.wipeOld : root.thumbFor(path)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            Item {
                property real fullW: parent.width - 4
                y: 2
                height: parent.height - 4
                width: (k === 0 && root.wiping) ? root.wipeP * fullW : 0
                x: root.wipeDir > 0 ? 2 : parent.width - 2 - width
                clip: true
                visible: width > 0.5

                Image {
                    width: parent.fullW
                    height: parent.height
                    x: root.wipeDir > 0 ? 0 : parent.width - parent.fullW
                    source: (k === 0 && root.wiping) ? root.wipeNew : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy - root.arcr + root.thumbH * root.selScale / 2 + 16
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        color: "#F2F2F2"
        opacity: root.open ? 0.85 : 0
        text: WallpaperState.displayName(root.fileAt(root.sel))

        Behavior on opacity {
            NumberAnimation {
                duration: root.motionOK ? 110 : 0
            }
        }
    }

    Component.onCompleted: {
        var i = indexOf(WallpaperState.current);
        sel = i >= 0 ? i : 0;
        appliedPath = WallpaperState.current;
        ensureVideoThumbs();
        animCheck.running = true;
        openFallback.restart();
    }
}
