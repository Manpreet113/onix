// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixNotifHistory: notification-center store (backs upstream's
// NotificationCenter history). Quickshell destroys Notification objects on
// dismiss/expire, so history keeps plain snapshots (newest first, cap 50).
// Live popups still use the real objects in OnixNotifs.
pragma Singleton

import QtQuick

QtObject {
    id: root

    property var items: []

    function push(summary, body, appIcon, appName): void {
        var next = [{
            summary: summary || "",
            body: body || "",
            appIcon: appIcon || "",
            appName: appName || "",
            born: Date.now() / 1000
        }].concat(root.items);
        if (next.length > 50)
            next = next.slice(0, 50);
        root.items = next;
    }

    function clear(): void {
        root.items = [];
    }

    function removeAt(i): void {
        var next = root.items.slice();
        if (i >= 0 && i < next.length)
            next.splice(i, 1);
        root.items = next;
    }
}
