import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Wallpaper picker content for the Overlay host.
// The host owns window/dim/card/IPC/keys; this owns highlight + preview.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

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
    }

    function onShown(): void {
        var i = indexOf(WallpaperState.current);
        highlight = i >= 0 ? i : 0;
        previewPath = fileAt(highlight);
        showPreview();
        preview.opacity = 1;
    }

    function apply(): void {
        if (previewPath.length > 0)
            WallpaperState.set(previewPath);
        requestClose();
    }

    Timer {
        id: swapTimer
        interval: Theme.fadeFast
        repeat: false
        onTriggered: {
            showPreview();
            preview.opacity = 1;
        }
    }

    property bool previewIsVideo: WallpaperState.isVideo(previewPath)

    onPreviewPathChanged: {
        preview.opacity = 0;
    }

    Column {
        anchors.fill: parent
        spacing: 16

        // live preview in screen aspect ratio
        Item {
            id: previewBox
            width: parent.width
            height: width / root.screenRatio

            Rectangle {
                anchors.fill: parent
                color: Theme.preview
                radius: Theme.radiusMed
            }

            Item {
                id: preview
                anchors.fill: parent
                opacity: 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.fadeFast
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
                Loader {
                    anchors.fill: parent
                    active: root.previewIsVideo
                    sourceComponent: Component {
                        Video {
                            anchors.fill: parent
                            source: WallpaperState.fileUrl(root.previewPath)
                            fillMode: VideoOutput.PreserveAspectCrop
                            muted: true
                            loops: MediaPlayer.Infinite
                            autoPlay: true
                        }
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 12
                text: WallpaperState.displayName(previewPath)
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
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
                            duration: Theme.fadeMed
                            easing.type: Easing.OutBack
                        }
                    }
                    z: selected ? 10 : 0

                    Rectangle {
                        anchors.fill: parent
                        color: selected ? Theme.blue : Theme.border
                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.fadeMed
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
                        color: Theme.surface
                        visible: video
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: Theme.cyan
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 6
                        text: WallpaperState.displayName(filePath)
                        color: Theme.text
                        font.family: Theme.fontFamily
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
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
