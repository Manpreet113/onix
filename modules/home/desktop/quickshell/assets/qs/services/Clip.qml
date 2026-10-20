pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent Clipboard History Manager (Text & Image Clipping)
Singleton {
    id: root

    property var history: []
    readonly property int count: history.length
    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/onix/clipboard.json"
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/clipwatch.sh").toString().replace("file://", "")

    function formatSize(bytes: real): string {
        if (!bytes || bytes <= 0) return "0 B";
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
        return (bytes / 1048576).toFixed(1) + " MB";
    }

    function loadCache(): void {
        try {
            var raw = cacheFile.text().trim();
            if (raw.length > 0) {
                var list = JSON.parse(raw);
                if (Array.isArray(list)) {
                    root.history = list;
                }
            }
        } catch (e) {
            console.log("[Clip] Failed to parse cache:", e);
        }
    }

    function handlePayload(rawJson: string): void {
        if (!rawJson) return;
        var trimmed = rawJson.trim();
        if (trimmed.length === 0) return;

        try {
            var payload = JSON.parse(trimmed);
            if (!payload || !payload.type) return;

            if (payload.type === "image") {
                addImageClip(payload);
            } else if (payload.type === "text") {
                addTextClip(payload.content || "");
            }
        } catch (e) {
            // Fallback: If not JSON, treat as raw text
            addTextClip(trimmed);
        }
    }

    function addImageClip(data: var): void {
        if (!data || !data.filePath) return;
        var filePath = data.filePath;

        // Skip if identical to latest item
        if (history.length > 0 && history[0].type === "image" && history[0].filePath === filePath)
            return;

        var filtered = [];
        for (var i = 0; i < history.length; i++) {
            if (history[i].filePath !== filePath) {
                filtered.push(history[i]);
            }
        }

        var now = new Date();
        var sizeStr = root.formatSize(data.size || 0);
        var mime = data.mime || "image/png";
        var ext = mime.split("/")[1] || "png";

        var entry = {
            id: Date.now() + "_" + Math.random().toString(36).substring(2, 6),
            type: "image",
            filePath: filePath,
            mime: mime,
            size: data.size || 0,
            preview: `Image (${sizeStr} • ${ext.toUpperCase()})`,
            charCount: 0,
            lineCount: 1,
            timeStr: Qt.formatDateTime(now, "hh:mm AP"),
            timestamp: now.getTime()
        };

        var updated = [entry].concat(filtered);
        if (updated.length > 60) {
            updated = updated.slice(0, 60);
        }
        history = updated;
        saveTimer.restart();
    }

    function addTextClip(raw: string): void {
        if (!raw) return;
        var text = raw.trim();
        if (text.length === 0) return;

        // Skip if identical to latest item
        if (history.length > 0 && history[0].type === "text" && history[0].text === text)
            return;

        var filtered = [];
        for (var i = 0; i < history.length; i++) {
            if (history[i].text !== text) {
                filtered.push(history[i]);
            }
        }

        var lines = text.split("\n");
        var preview = lines[0].trim();
        if (lines.length > 1) {
            preview += ` … (${lines.length} lines)`;
        }
        if (preview.length > 80) {
            preview = preview.substring(0, 77) + "…";
        }

        var now = new Date();
        var entry = {
            id: Date.now() + "_" + Math.random().toString(36).substring(2, 6),
            type: "text",
            text: text,
            preview: preview,
            charCount: text.length,
            lineCount: lines.length,
            timeStr: Qt.formatDateTime(now, "hh:mm AP"),
            timestamp: now.getTime()
        };

        var updated = [entry].concat(filtered);
        if (updated.length > 60) {
            updated = updated.slice(0, 60);
        }
        history = updated;
        saveTimer.restart();
    }

    function copy(item: var): void {
        if (!item) return;
        if (typeof item === "object") {
            if (item.type === "image" && item.filePath) {
                Quickshell.execDetached(["bash", "-c", `wl-copy --type "${item.mime || "image/png"}" < "${item.filePath}"`]);
                return;
            }
            var text = item.text || item.content || "";
            Quickshell.clipboardText = text;
            Quickshell.execDetached(["wl-copy", text]);
        } else {
            var str = String(item);
            Quickshell.clipboardText = str;
            Quickshell.execDetached(["wl-copy", str]);
        }
    }

    function remove(id: string): void {
        var out = [];
        for (var i = 0; i < history.length; i++) {
            if (history[i].id !== id) {
                out.push(history[i]);
            } else if (history[i].type === "image" && history[i].filePath) {
                Quickshell.execDetached(["rm", "-f", history[i].filePath]);
            }
        }
        history = out;
        saveTimer.restart();
    }

    function clear(): void {
        for (var i = 0; i < history.length; i++) {
            if (history[i].type === "image" && history[i].filePath) {
                Quickshell.execDetached(["rm", "-f", history[i].filePath]);
            }
        }
        history = [];
        saveTimer.restart();
    }

    FileView {
        id: cacheFile
        path: root.cachePath
        printErrors: false
        blockLoading: true
        onLoaded: root.loadCache()
    }

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            try {
                cacheFile.setText(JSON.stringify(root.history.slice(0, 60)));
            } catch (e) {
                console.log("[Clip] Save error:", e);
            }
        }
    }

    // Wayland clipboard selection watcher (captures text AND images)
    Process {
        id: clipProc
        command: ["bash", "-c", `exec wl-paste -w "${root.scriptPath}"`]
        running: true
        stdout: SplitParser {
            splitMarker: "\x1e"
            onRead: data => root.handlePayload(data)
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["touch", root.cachePath]);
        root.loadCache();
    }
}
