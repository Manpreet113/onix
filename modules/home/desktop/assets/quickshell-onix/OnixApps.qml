// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixApps: desktop-entry lookup + pinned apps (ports upstream AppIcon fuzzy
// matching and ApplicationsService.pinned). Pins persist to
// ~/.local/share/onix-shell/onix-pinned.json as entry-id list.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/share/onix-shell"

    property var pinned: []

    function sameApp(a, b): bool {
        if (!a || !b)
            return false;
        var x = String(a).toLowerCase();
        var y = String(b).toLowerCase();
        return x.indexOf(y) >= 0 || y.indexOf(x) >= 0;
    }

    function findEntry(appId): var {
        if (!appId)
            return null;
        var vals = DesktopEntries.applications.values;
        for (var i = 0; i < vals.length; i++) {
            if (root.sameApp(vals[i].id, appId))
                return vals[i];
        }
        return null;
    }

    function iconFor(appId, title): string {
        var e = root.findEntry(appId) || root.findEntry(title);
        if (e && e.icon)
            return e.icon;
        return "application-x-executable";
    }

    function isPinned(id): bool {
        return root.pinned.indexOf(id) >= 0;
    }

    function pin(id): void {
        if (!root.isPinned(id)) {
            root.pinned = root.pinned.concat([id]);
            root.save();
        }
    }

    function unpin(id): void {
        if (root.isPinned(id)) {
            root.pinned = root.pinned.filter(function (x) {
                return x !== id;
            });
            root.save();
        }
    }

    function launchEntry(e): void {
        if (!e)
            return;
        if (e.runInTerminal)
            Quickshell.execDetached({
                command: ["ghostty", "-e"].concat(e.command),
                workingDirectory: e.workingDirectory
            });
        else
            e.execute();
    }

    function load(): void {
        try {
            var t = pinsLoader.text().trim();
            var v = t.length > 0 ? JSON.parse(t) : [];
            root.pinned = Array.isArray(v) ? v : [];
        } catch (e) {
            root.pinned = [];
        }
    }

    function save(): void {
        pinsSaver.setText(JSON.stringify(root.pinned));
    }

    property FileView pinsSaver: FileView {
        path: root.stateDir + "/onix-pinned.json"
        printErrors: false
    }

    property FileView pinsLoader: FileView {
        path: root.stateDir + "/onix-pinned.json"
        printErrors: false
        blockLoading: true
        onLoaded: root.load()
    }
}
