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

    property string pendingThemeTarget: ""

    Timer {
        id: skeinDebounceTimer
        interval: 220
        repeat: false
        onTriggered: {
            if (root.pendingThemeTarget.length > 0) {
                Quickshell.execDetached(["skeinc", "set", root.pendingThemeTarget]);
            }
        }
    }

    function set(path: string, immediate: var): void {
        const isImmediate = immediate === true;
        root.current = path;
        saver.setText(path + "\n");

        let cleanPath = path;
        if (cleanPath.startsWith("file://")) {
            cleanPath = cleanPath.slice(7);
        }

        let targetImage = cleanPath;
        if (isVideo(cleanPath)) {
            const parts = cleanPath.split("/");
            const base = parts[parts.length - 1];
            const dot = base.lastIndexOf(".");
            const stem = dot > 0 ? base.slice(0, dot) : base;
            targetImage = Quickshell.env("HOME") + "/.cache/onix-shell/thumbs/" + stem + ".png";
        }

        root.pendingThemeTarget = targetImage;
        syncToGreeter(cleanPath);
        if (isImmediate) {
            skeinDebounceTimer.stop();
            Quickshell.execDetached(["skeinc", "set", targetImage]);
        } else {
            skeinDebounceTimer.restart();
        }
    }

    function syncToGreeter(sourcePath: string): void {
        if (!sourcePath || sourcePath.length === 0)
            return;
        let p = sourcePath;
        if (p.startsWith("file://")) {
            p = p.slice(7);
        }
        Quickshell.execDetached([
            "sh", "-c",
            "for d in /var/cache/onix /tmp/onix; do " +
            "  mkdir -p \"$d\" 2>/dev/null; " +
            "  ext=\"${1##*.}\"; " +
            "  cp \"$1\" \"$d/wallpaper.$ext\" 2>/dev/null && chmod 644 \"$d/wallpaper.$ext\" 2>/dev/null; " +
            "  echo \"wallpaper.$ext\" > \"$d/wallpaper.type\" 2>/dev/null && chmod 644 \"$d/wallpaper.type\" 2>/dev/null; " +
            "  if [ -f \"$HOME/.cache/skein/theme.json\" ]; then " +
            "    cp \"$HOME/.cache/skein/theme.json\" \"$d/theme.json\" 2>/dev/null && chmod 644 \"$d/theme.json\" 2>/dev/null; " +
            "  fi; " +
            "done",
            "--", p
        ]);
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
            if (root.current.length > 0)
                syncToGreeter(root.current);
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/onix-shell"]);
        if (root.current.length > 0)
            syncToGreeter(root.current);
    }
}
