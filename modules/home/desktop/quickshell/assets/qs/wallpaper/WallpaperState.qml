pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

// Single source of truth for the desktop wallpaper, reachable as
// WallpaperState.* from any component.
// Files live in ~/Pictures/Wallpapers (outside the repo); the chosen
// file persists in ~/.local/share/onix-shell/wallpaper.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/share/onix-shell/wallpaper"

    property string current: ""
    property bool pickerOpen: false
    property int wipeDir: 1

    // screen name -> file map for future per-monitor wallpapers
    property var perScreen: ({})

    function isVideo(path: string): bool {
        var p = path.toLowerCase();
        return p.endsWith(".mp4") || p.endsWith(".mkv") || p.endsWith(".webm");
    }

    function fileUrl(path: string): string {
        return path.startsWith("file://") ? path : "file://" + path;
    }

    function displayName(path: string): string {
        var parts = path.split("/");
        var base = parts[parts.length - 1];
        var dot = base.lastIndexOf(".");
        return dot > 0 ? base.slice(0, dot) : base;
    }

    function set(path: string): void {
        root.current = path;
        saver.setText(path + "\n");
    }

    property FolderListModel files: FolderListModel {
        folder: "file://" + root.dir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.mp4", "*.mkv", "*.webm"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    property FileView saver: FileView {
        path: root.stateFile
        printErrors: false
    }

    property FileView loader: FileView {
        path: root.stateFile
        printErrors: false
        blockLoading: true
        onLoaded: {
            var t = loader.text().trim();
            if (t.length > 0)
                root.current = t;
            else if (files.count > 0)
                root.current = files.get(0, "filePath");
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/onix-shell"]);
    }
}
