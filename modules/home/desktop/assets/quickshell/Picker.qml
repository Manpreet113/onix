import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Centered wallpaper picker: parallelogram film strip, big live preview,
// arrow-key navigation. Toggle via `quickshell ipc call wallpaper toggle`.
PanelWindow {
    id: root

    visible: false
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property int highlight: 0
    property string previewPath: ""

    property real screenRatio: {
        var m = Hyprland.focusedMonitor;
        if (m && m.width > 0 && m.height > 0)
            return m.width / m.height;
        return 16 / 10;
    }

    function fileCount(): int {
        return WallpaperState.files.count;
    }

    function fileAt(i: int): string {
        if (i < 0 || i >= WallpaperState.files.count)
            return "";
        return WallpaperState.files.get(i, "filePath");
    }

    function indexOf(path: string): int {
        for (var i = 0; i < WallpaperState.files.count; i++)
            if (WallpaperState.files.get(i, "filePath") === path)
                return i;
        return -1;
    }

    function move(d: int): void {
        var n = fileCount();
        if (n === 0)
            return;
        highlight = (highlight + d + n) % n;
        previewPath = fileAt(highlight);
        swapTimer.restart();
    }

    function showPreview(): void {
        previewImage.source = previewIsVideo ? "" : WallpaperState.fileUrl(previewPath);
        previewVideo.source = previewIsVideo ? WallpaperState.fileUrl(previewPath) : "";
    }

    function open(): void {
        var i = indexOf(WallpaperState.current);
        highlight = i >= 0 ? i : 0;
        previewPath = fileAt(highlight);
        showPreview();
        preview.opacity = 1;
        visible = true;
        card.scale = 0.94;
        card.opacity = 0;
        card.scale = 1.0;
        card.opacity = 1.0;
    }

    function close(): void {
        visible = false;
    }

    function apply(): void {
        if (previewPath.length > 0)
            WallpaperState.set(previewPath);
        close();
    }

    Timer {
        id: swapTimer
        interval: 130
        repeat: false
        onTriggered: {
            showPreview();
            preview.opacity = 1;
        }
    }

    property bool previewIsVideo: WallpaperState.isVideo(previewPath)

    onPreviewPathChanged: {
        if (visible)
            preview.opacity = 0;
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.visible ? root.close() : root.open();
        }
    }

    Shortcut {
        sequence: "Left"
        enabled: root.visible
        onActivated: root.move(-1)
    }
    Shortcut {
        sequence: "Right"
        enabled: root.visible
        onActivated: root.move(1)
    }
    Shortcut {
        sequence: "Return"
        enabled: root.visible
        onActivated: root.apply()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }

    // dim backdrop, click-through close
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.visible ? 0.55 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, 980)
        implicitHeight: previewBox.implicitHeight + strip.implicitHeight + hint.implicitHeight + 72
        color: "#2e3440"
        radius: 14
        border.color: "#4c566a"
        border.width: 1

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // live preview in screen aspect ratio
            Item {
                id: previewBox
                width: parent.width
                implicitHeight: width / root.screenRatio

                Rectangle {
                    anchors.fill: parent
                    color: "#1a1d24"
                    radius: 10
                }

                Item {
                    id: preview
                    anchors.fill: parent
                    opacity: 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 130
                            easing.type: Easing.OutCubic
                        }
                    }

                    Image {
                        id: previewImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: !root.previewIsVideo
                    }
                    Video {
                        id: previewVideo
                        anchors.fill: parent
                        visible: root.previewIsVideo
                        fillMode: VideoOutput.PreserveAspectCrop
                        muted: true
                        loops: MediaPlayer.Infinite
                        autoPlay: true
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 12
                    text: WallpaperState.displayName(previewPath)
                    color: "#eceff4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    font.bold: true
                }
            }

            // parallelogram film strip
            Row {
                id: strip
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Repeater {
                    model: WallpaperState.files
                    delegate: Item {
                        required property string filePath
                        required property string fileName
                        required property int index

                        property bool selected: root.highlight === index
                        property bool video: WallpaperState.isVideo(filePath)

                        width: 104
                        height: 64

                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.22, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                        scale: selected ? 1.16 : (thumbMouse.containsMouse ? 1.06 : 1.0)
                        Behavior on scale {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutBack
                            }
                        }
                        z: selected ? 10 : 0

                        Rectangle {
                            anchors.fill: parent
                            color: selected ? "#81a1c1" : "#4c566a"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 160
                                }
                            }
                        }
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: video ? "" : WallpaperState.fileUrl(filePath)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: !video
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: "#3b4252"
                            visible: video
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#88c0d0"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                            }
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            text: WallpaperState.displayName(filePath)
                            color: "#eceff4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            width: parent.width - 12
                        }
                        MouseArea {
                            id: thumbMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.highlight = index;
                                root.previewPath = filePath;
                                root.swapTimer.restart();
                            }
                            onDoubleClicked: {
                                root.highlight = index;
                                root.previewPath = filePath;
                                root.apply();
                            }
                        }
                    }
                }
            }

            Text {
                id: hint
                anchors.horizontalCenter: parent.horizontalCenter
                text: "← → preview · enter apply · esc close"
                color: "#6c7a96"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
        }
    }
}
