import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Desktop background, one surface per screen on the background layer.
// NOTE: inside Variants delegates, `parent.*` does NOT resolve to the
// delegate root (reload-scope wrapping) — always use the `wallpaper` id.
// NOTE 2: the Video element busy-loops FFmpeg (>100% CPU) when it merely
// exists without a playable source, so it lives behind a Loader and is
// only instantiated for actual video files.
Scope {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: wallpaper
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                aboveWindows: false
                color: "#282828"

                property string wallSource: {
                    var mapped = WallpaperState.perScreen[modelData.name];
                    if (mapped && mapped.length > 0)
                        return WallpaperState.fileUrl(mapped);
                    if (WallpaperState.current.length > 0)
                        return WallpaperState.fileUrl(WallpaperState.current);
                    if (WallpaperState.files.count > 0)
                        return WallpaperState.fileUrl(WallpaperState.files.get(0, "filePath"));
                    return "";
                }
                property bool isVideoFile: WallpaperState.isVideo(wallSource)

                // Pause the video when a fullscreen window has focus —
                // the wallpaper is invisible anyway.
                property bool fsActive: {
                    var t = Hyprland.activeToplevel;
                    if (!t || !t.lastIpcObject)
                        return false;
                    var o = t.lastIpcObject;
                    return o.fullscreen === true || o.fullscreenMode > 0;
                }
                onFsActiveChanged: {
                    if (videoLoader.item) {
                        if (fsActive)
                            videoLoader.item.pause();
                        else
                            videoLoader.item.play();
                    }
                }

                Image {
                    anchors.fill: parent
                    visible: !wallpaper.isVideoFile && wallpaper.wallSource.length > 0
                    source: visible ? wallpaper.wallSource : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Loader {
                    id: videoLoader
                    anchors.fill: parent
                    active: wallpaper.isVideoFile
                    sourceComponent: Component {
                        Video {
                            anchors.fill: parent
                            source: wallpaper.wallSource
                            fillMode: VideoOutput.PreserveAspectCrop
                            muted: true
                            loops: MediaPlayer.Infinite
                            autoPlay: !wallpaper.fsActive
                            Component.onCompleted: {
                                if (wallpaper.fsActive)
                                    pause();
                            }
                        }
                    }
                    onLoaded: {
                        if (wallpaper.fsActive && item)
                            item.pause();
                    }
                }
            }
        }
    }
}
