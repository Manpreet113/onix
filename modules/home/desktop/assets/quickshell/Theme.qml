pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Onix shell design tokens. Every overlay component reads from here —
// change the feel of the whole shell in one place.
//
// Colors are skein-driven: skeind snapshots the wallpaper palette to
// ~/.cache/skein/theme.json on every change and this reloads it live.
// Daemon off / file absent = classic Nord fallbacks below, so the shell
// looks exactly like it always did. Shape/type/motion (and the neutral
// failure/preview tones) stay static by design.
Singleton {
    id: root

    property var data: ({})

    // skein roles (12) -> shell tokens (11); surface_variant unused
    readonly property color bg: data.background || "#2e3440"
    readonly property color surface: data.surface || "#3b4252"
    readonly property color border: data.border || "#4c566a"
    readonly property color text: data.text || "#eceff4"
    readonly property color subtext: data.subtext || "#d8dee9"
    readonly property color dim: data.dim || "#6c7a96"
    readonly property color blue: data.primary || "#81a1c1"
    readonly property color cyan: data.accent || "#88c0d0"
    readonly property color red: data.red || "#bf616a"
    readonly property color green: data.green || "#a3be8c"
    readonly property color yellow: data.yellow || "#ebcb8b"
    readonly property color backdrop: "#000000"

    // neutral one-offs (not wallpaper-driven)
    readonly property color failure: "#4a2f38"
    readonly property color preview: "#1a1d24"

    // shape
    readonly property int radiusSmall: 6
    readonly property int radiusMed: 8
    readonly property int radiusLarge: 14

    // type
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSmall: 12
    readonly property int fontMed: 13
    readonly property int fontLarge: 15
    readonly property int fontTitle: 22

    // motion (ms)
    readonly property int fadeFast: 130
    readonly property int fadeMed: 160
    readonly property int openSpring: 220

    function load(): void {
        try {
            var t = themeFile.text().trim();
            root.data = t.length > 0 ? JSON.parse(t) : ({});
        } catch (e) {
            root.data = ({});
        }
    }

    property FileView themeFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/skein/theme.json"
        printErrors: false
        watchChanges: true
        onFileChanged: themeFile.reload()
        blockLoading: true
        onLoaded: root.load()
    }

    // backstop: if the file appears after us (daemon starts later),
    // pick it up within seconds instead of waiting for a change event
    Timer {
        interval: 5000
        running: Object.keys(root.data).length === 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            themeFile.reload();
        }
    }
}
