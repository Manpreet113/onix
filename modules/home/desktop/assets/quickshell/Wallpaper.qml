import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland

// Desktop background, one surface per screen on the background layer.
// NOTE: inside Variants delegates, `parent.*` does NOT resolve to the
// delegate root (reload-scope wrapping) — always use the `wallpaper` id.
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

                Image {
                    anchors.fill: parent
                    visible: !wallpaper.isVideoFile && wallpaper.wallSource.length > 0
                    source: wallpaper.visible ? wallpaper.wallSource : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Video {
                    anchors.fill: parent
                    visible: wallpaper.isVideoFile
                    source: wallpaper.visible ? wallpaper.wallSource : ""
                    fillMode: VideoOutput.PreserveAspectCrop
                    muted: true
                    loops: MediaPlayer.Infinite
                    autoPlay: true
                }
            }
        }
    }
}
