import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.theme

// Desktop background, one surface per screen on the background layer.
// A bare Video element busy-loops FFmpeg (>100% CPU) with no playable
// source, so it lives behind a Loader instantiated for videos only.
PanelWindow {
    id: root
    property var modelData: null
    screen: modelData ?? Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: false
    color: "#000000"
    mask: Region {}
    WlrLayershell.namespace: "onix-wallpaper"
    WlrLayershell.layer: WlrLayer.Background

    property string wallSource: {
        if (WallpaperState.current.length > 0)
            return WallpaperState.fileUrl(WallpaperState.current);
        if (WallpaperState.files.count > 0)
            return WallpaperState.fileUrl(WallpaperState.files.get(0, "filePath"));
        return "";
    }
    property bool isVideoFile: WallpaperState.isVideo(root.wallSource)
    property string prevSrc: ""
    property string wipeOld: ""
    property bool wiping: false
    property real wipeP: 0

    onWallSourceChanged: {
        if (WallpaperState.pickerOpen && prevSrc.length > 0 && !WallpaperState.isVideo(wallSource) && !WallpaperState.isVideo(prevSrc)) {
            wipeOld = prevSrc;
            wiping = true;
            wipeAnim.restart();
        } else {
            wiping = false;
        }
        prevSrc = wallSource;
    }

    NumberAnimation {
        id: wipeAnim
        target: root
        property: "wipeP"
        from: 0
        to: 1
        duration: Motion.reveal
        onFinished: root.wiping = false
    }

    // Pause the video when a fullscreen window has focus —
    // the wallpaper is invisible anyway.
    property bool fsActive: {
        const o = Hypr.activeToplevel?.lastIpcObject;
        return (o?.fullscreen === true) || ((o?.fullscreenMode ?? 0) > 0);
    }
    onFsActiveChanged: {
        if (videoLoader.item) {
            if (root.fsActive)
                videoLoader.item.pause();
            else
                videoLoader.item.play();
        }
    }

    Image {
        anchors.fill: parent
        visible: !root.isVideoFile && root.wallSource.length > 0
        source: visible ? (root.wiping ? root.wipeOld : root.wallSource) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Item {
        property real fullW: parent.width
        y: 0
        height: parent.height
        width: root.wiping ? root.wipeP * fullW : 0
        x: WallpaperState.wipeDir > 0 ? 0 : parent.width - width
        clip: true
        visible: width > 0.5

                Image {
                    width: parent.fullW
                    height: parent.height
                    x: WallpaperState.wipeDir > 0 ? 0 : parent.width - parent.fullW
                    source: root.wiping ? root.wallSource : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
    }

    Loader {
        id: videoLoader
        anchors.fill: parent
        active: root.isVideoFile
        sourceComponent: Component {
            Video {
                anchors.fill: parent
                source: root.wallSource
                fillMode: VideoOutput.PreserveAspectCrop
                muted: true
                loops: MediaPlayer.Infinite
                autoPlay: !root.fsActive
                onSourceChanged: {
                    if (!root.fsActive)
                        play();
                }
                Component.onCompleted: {
                    if (root.fsActive)
                        pause();
                    else
                        play();
                }
            }
        }
        onLoaded: {
            if (root.fsActive && item)
                item.pause();
        }
    }

    // Permanent Onix Brand Watermark (Bottom Right)
    Item {
        id: watermark
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 48
        anchors.bottomMargin: 40
        width: wmRow.implicitWidth
        height: wmRow.implicitHeight
        opacity: root.fsActive ? 0 : 0.82

        Behavior on opacity { NumberAnimation { duration: Motion.spatial } }

        Row {
            id: wmRow
            spacing: 14
            anchors.centerIn: parent

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    anchors.right: parent.right
                    text: "ONIX"
                    font.family: Theme.fontDisplay
                    font.pixelSize: 21
                    font.weight: Font.ExtraBold
                    font.letterSpacing: 4.5
                    color: Theme.watermarkText
                    style: Text.Outline
                    styleColor: Theme.watermarkOutline

                    Behavior on color { ColorAnimation { duration: Motion.effects } }
                }

                Text {
                    anchors.right: parent.right
                    text: "SYSTEM OS"
                    font.family: Theme.fontPrimary
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: Theme.watermarkSubtext
                    style: Text.Outline
                    styleColor: Theme.watermarkOutline

                    Behavior on color { ColorAnimation { duration: Motion.effects } }
                }
            }

            OnixLogo {
                size: 52
                color: Theme.watermarkLogo
                shadow: true
                shadowColor: Theme.watermarkShadow
                shadowOpacity: 0.90
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
