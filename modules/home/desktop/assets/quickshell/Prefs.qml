pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell-wide persisted preferences (lives outside the repo by design).
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/share/onix-shell"

    // Do-not-disturb: popups suppressed, history still recorded.
    property bool dnd: false

    function setDnd(v: bool): void {
        root.dnd = v;
        dndSaver.setText(v ? "1\n" : "0\n");
    }

    function toggleDnd(): void {
        setDnd(!dnd);
    }

    property FileView dndSaver: FileView {
        path: root.stateDir + "/dnd"
        printErrors: false
    }

    property FileView dndLoader: FileView {
        path: root.stateDir + "/dnd"
        printErrors: false
        blockLoading: true
        onLoaded: {
            root.dnd = dndLoader.text().trim() === "1";
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.stateDir]);
    }
}
