pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification toast queue, active notification state & persistent history
Singleton {
    id: root

    property var currentNotification: null
    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property bool hasToast: currentNotification !== null

    property var history: []
    readonly property int count: history.length
    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/onix/notifications.json"

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
            console.log("[Notif] Failed to parse history cache:", e);
        }
    }

    function push(n: Notification): void {
        if (!n) return;

        var appN = n.appName || "System";
        var icon = n.appIcon || "";
        var sum = n.summary || "";
        var b = n.body || "";
        var now = new Date();

        var entry = {
            id: Date.now() + "_" + Math.random().toString(36).substring(2, 6),
            appName: appN,
            appIcon: icon,
            summary: sum,
            body: b,
            timeStr: Qt.formatDateTime(now, "hh:mm AP"),
            timestamp: now.getTime(),
            notificationRef: n
        };

        var updated = [entry].concat(root.history);
        if (updated.length > 50) {
            updated = updated.slice(0, 50);
        }
        root.history = updated;
        saveTimer.restart();

        if (Sys.dnd) return;
        currentNotification = n;
        appName = appN;
        appIcon = icon;
        summary = sum;
        body = b;

        let timeout = n.expireTimeout > 0 ? n.expireTimeout : 4500;
        toastTimer.interval = timeout;
        toastTimer.restart();
    }

    function dismiss(): void {
        if (currentNotification) {
            try {
                currentNotification.dismiss();
            } catch (e) {}
            currentNotification = null;
        }
        appName = "";
        appIcon = "";
        summary = "";
        body = "";
        toastTimer.stop();
    }

    function dismissHistory(id: string): void {
        var out = [];
        for (var i = 0; i < history.length; i++) {
            if (history[i].id !== id) {
                out.push(history[i]);
            }
        }
        history = out;
        saveTimer.restart();
    }

    function clearHistory(): void {
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
                // Strip notificationRef before saving to JSON
                var serializable = [];
                for (var i = 0; i < root.history.length; i++) {
                    var it = root.history[i];
                    serializable.push({
                        id: it.id,
                        appName: it.appName,
                        appIcon: it.appIcon,
                        summary: it.summary,
                        body: it.body,
                        timeStr: it.timeStr,
                        timestamp: it.timestamp
                    });
                }
                cacheFile.setText(JSON.stringify(serializable.slice(0, 50)));
            } catch (e) {
                console.log("[Notif] Save error:", e);
            }
        }
    }

    Timer {
        id: toastTimer
        interval: 4500
        repeat: false
        onTriggered: root.dismiss()
    }

    Component.onCompleted: {
        Quickshell.execDetached(["touch", root.cachePath]);
        root.loadCache();
    }
}
