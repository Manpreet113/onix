// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixTabAppearance: wallpaper, themes, auto-dark schedule, color schemes,
// and the quick-select gallery (ports upstream AppearanceTab; the GTK font
// picker has no QML equivalent and stays Nix-managed, so it is omitted).
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Column {
    id: root
    spacing: 8
    width: 800

    property var gallery: []
    property bool galleryLoading: true

    function galleryDir(): string {
        var q = OnixSettings.get(["appearance", "wallcolors", "quickselect_path"], "");
        if (q !== "")
            return q.replace(/^~(?=\/|$)/, Quickshell.env("HOME"));
        return Quickshell.env("HOME") + "/Pictures/Wallpapers";
    }

    function refreshGallery(): void {
        root.galleryLoading = true;
        galleryProc.command = ["sh", "-c", "find '" + root.galleryDir().replace(/'/g, "'\\''") + "' -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort"];
        galleryProc.running = true;
    }

    Process {
        id: galleryProc
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim();
                root.gallery = t.length > 0 ? t.split("\n") : [];
                root.galleryLoading = false;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.gallery = [];
                root.galleryLoading = false;
            }
        }
    }

    Component.onCompleted: root.refreshGallery()

    OnixWallCat {
    }

    OnixCatLabel {
        icon: "palette"
        title: "Colors"
    }

    OnixSetRow {
        title: "Themes"
        description: "Set your theme."
        vertical: true
        control: Component {
            OnixThemePreviews {
                width: 776
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Auto Dark"
        description: "Automatically set the dark theme based on the time of day."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["appearance", "wallcolors", "auto_dark", "enabled"], false)
                onToggled: value => OnixSettings.set(["appearance", "wallcolors", "auto_dark", "enabled"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Start Time"
        description: "Time of day to enable dark mode when Auto Dark is enabled."
        control: Component {
            Row {
                spacing: 8
                OnixSpin {
                    min: 0
                    max: 23
                    value: OnixSettings.get(["appearance", "wallcolors", "auto_dark", "start_hour"], 22)
                    onChanged: value => OnixSettings.set(["appearance", "wallcolors", "auto_dark", "start_hour"], Math.round(value))
                }
                OnixSpin {
                    min: 0
                    max: 59
                    value: OnixSettings.get(["appearance", "wallcolors", "auto_dark", "start_min"], 0)
                    onChanged: value => OnixSettings.set(["appearance", "wallcolors", "auto_dark", "start_min"], Math.round(value))
                }
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "End Time"
        description: "Time of day to disable dark mode when Auto Dark is enabled."
        control: Component {
            Row {
                spacing: 8
                OnixSpin {
                    min: 0
                    max: 23
                    value: OnixSettings.get(["appearance", "wallcolors", "auto_dark", "end_hour"], 6)
                    onChanged: value => OnixSettings.set(["appearance", "wallcolors", "auto_dark", "end_hour"], Math.round(value))
                }
                OnixSpin {
                    min: 0
                    max: 59
                    value: OnixSettings.get(["appearance", "wallcolors", "auto_dark", "end_min"], 0)
                    onChanged: value => OnixSettings.set(["appearance", "wallcolors", "auto_dark", "end_min"], Math.round(value))
                }
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Color Schemes"
        description: "Set your color scheme."
        vertical: true
        control: Component {
            OnixSchemeRow {
                cols: 8
            }
        }
    }

    OnixCatLabel {
        icon: "image"
        title: "Quick Select"
    }

    Row {
        width: parent.width
        spacing: 8

        TextField {
            id: folderField
            width: parent.width - folderBtn.width - 8
            placeholderText: root.galleryDir()
            color: OnixTheme.mOnSurface
            placeholderTextColor: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontMed
            background: Rectangle {
                color: OnixTheme.mSurfaceContainerHigh
                radius: OnixTheme.radiusFull
            }
            leftPadding: 16
            rightPadding: 16
        }

        M3Button {
            id: folderBtn
            btnType: "filled"
            size: "s"
            icon: "folder_open"
            label: "Select a Folder"
            onClicked: {
                var p = folderField.text.trim();
                if (p.indexOf("~") === 0)
                    p = Quickshell.env("HOME") + p.slice(1);
                if (p !== "") {
                    OnixSettings.set(["appearance", "wallcolors", "quickselect_path"], p);
                    root.refreshGallery();
                }
            }
        }
    }

    Text {
        visible: root.galleryLoading
        text: "Loading wallpapers..."
        color: OnixTheme.mOnSurfaceVariant
        font.pixelSize: OnixTheme.fontMed
    }

    Text {
        visible: !root.galleryLoading && root.gallery.length === 0
        text: "No wallpapers found in the directory."
        color: OnixTheme.mOnSurfaceVariant
        font.pixelSize: OnixTheme.fontMed
    }

    Grid {
        visible: !root.galleryLoading && root.gallery.length > 0
        width: parent.width
        columns: 4
        columnSpacing: 5
        rowSpacing: 5

        Repeater {
            model: root.gallery
            delegate: Rectangle {
                required property string modelData
                readonly property bool isCurrent: modelData === OnixSettings.get(["appearance", "wallcolors", "wallpaper_path"], "")

                implicitWidth: (800 - 15) / 4
                implicitHeight: 100
                radius: 12
                color: OnixTheme.mSurfaceContainerLow
                border.color: isCurrent ? OnixTheme.mPrimary : "transparent"
                border.width: isCurrent ? 2 : 0
                clip: true

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: "file://" + modelData
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: OnixWallpaper.setWall(modelData)
                }
            }
        }
    }
}
