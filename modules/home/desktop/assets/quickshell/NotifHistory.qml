pragma Singleton

import QtQuick
import Quickshell

// Notification history: snapshots recorded on post, independent of the
// live popup lifecycle (expire/dismiss only affects popups).
Singleton {
    id: root

    property var items: []

    function push(n: var): void {
        var entry = {
            app: (n && n.appName) || "",
            summary: (n && n.summary) || "",
            body: (n && n.body) || "",
            time: Date.now()
        };
        var next = [entry].concat(root.items);
        if (next.length > 30)
            next = next.slice(0, 30);
        root.items = next;
    }

    function removeAt(i: int): void {
        var next = root.items.slice();
        if (i >= 0 && i < next.length)
            next.splice(i, 1);
        root.items = next;
    }

    function clear(): void {
        root.items = [];
    }
}
