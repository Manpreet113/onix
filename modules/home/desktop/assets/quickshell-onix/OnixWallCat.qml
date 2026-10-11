// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWallCat: wallpaper preview + file row (ports upstream
// WallpaperCategory). The preview shows the live wallpaper_path; Set writes
// a path through OnixWallpaper (skeinc set + settings). No native file
// dialog exists in QML, so a path field covers custom locations.
import QtQuick
import QtQuick.Controls
import Quickshell

Column {
    id: root
    spacing: 0
    width: 800

    property string draftPath: ""
    property string title: "Wallpaper"

    OnixCatLabel {
        visible: root.title !== ""
        icon: "image"
        title: root.title
    }

    Rectangle {
        width: parent.width
        implicitHeight: 300
        radius: OnixTheme.radiusLarge
        color: OnixTheme.mSurfaceContainerLow
        border.color: OnixTheme.mOutlineVariant
        border.width: 1
        clip: true

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: {
                var p = OnixSettings.get(["appearance", "wallcolors", "wallpaper_path"], "");
                return p !== "" ? "file://" + p : "";
            }
            asynchronous: true
        }

        Text {
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 10
            }
            text: {
                var p = OnixSettings.get(["appearance", "wallcolors", "wallpaper_path"], "");
                if (p === "")
                    return "Click Set to choose a wallpaper";
                var parts = p.split("/");
                return parts[parts.length - 1];
            }
            color: "white"
            font.pixelSize: OnixTheme.fontMed
        }
    }

    Row {
        width: parent.width
        spacing: 8
        topPadding: 8

        TextField {
            id: pathField
            width: parent.width - setBtn.width - 8
            placeholderText: OnixSettings.get(["appearance", "wallcolors", "wallpaper_path"], "") || "~/Pictures/Wallpapers/…"
            color: OnixTheme.mOnSurface
            placeholderTextColor: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontMed
            background: Rectangle {
                color: OnixTheme.mSurfaceContainerHigh
                radius: OnixTheme.radiusFull
            }
            leftPadding: 16
            rightPadding: 16
            onTextChanged: root.draftPath = text
        }

        M3Button {
            id: setBtn
            btnType: "filled"
            size: "s"
            icon: "image"
            label: "Set"
            onClicked: {
                var p = root.draftPath.trim();
                if (p.indexOf("~") === 0)
                    p = Quickshell.env("HOME") + p.slice(1);
                if (p !== "")
                    OnixWallpaper.setWall(p);
            }
        }
    }
}
