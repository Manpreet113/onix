// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// Onix shell Material-3 tokens. Every Onix component reads color from here —
// change the feel of the whole shell in one place.
//
// Colors are skein-driven: skeind snapshots the wallpaper palette to
// ~/.cache/skein/theme.json on every change and this reloads it live.
// Daemon off / file absent = classic Nord fallbacks below. Shape/type/motion
// (and the neutral failure/preview tones) stay static by design.
//
// Role mapping (skein -> Material 3): the M3 roles below are DERIVED from the
// eleven skein tokens above them, so no new theming engine was introduced for
// this port. Containers are deterministic darker/lighter steps of bg/surface,
// which keeps the full M3 tonal ladder tracking the wallpaper.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var data: ({})

    // skein base tokens (Nord fallbacks when skein is absent)
    readonly property color bg: data.background || "#2e3440"
    readonly property color surface: data.surface || "#3b4252"
    readonly property color border: data.border || "#4c566a"
    readonly property color text: data.text || "#eceff4"
    readonly property color subtext: data.subtext || "#d8dee9"
    readonly property color dim: data.dim || "#6c7a96"
    readonly property color primary: data.primary || "#81a1c1"
    readonly property color accent: data.accent || "#88c0d0"
    readonly property color error: data.error || "#bf616a"
    readonly property color success: data.success || "#a3be8c"
    readonly property color warning: data.warning || "#ebcb8b"
    readonly property color backdrop: "#000000"

    // neutral one-offs (not wallpaper-driven)
    readonly property color failure: "#4a2f38"
    readonly property color preview: "#1a1d24"

    // Material-3 roles derived from the skein tokens above
    readonly property color mPrimary: root.primary
    readonly property color mOnPrimary: root.bg
    readonly property color mPrimaryContainer: root.surface
    readonly property color mOnPrimaryContainer: root.text
    readonly property color mSecondary: root.accent
    readonly property color mOnSecondary: root.bg
    readonly property color mSecondaryContainer: Qt.darker(root.accent, 1.7)
    readonly property color mOnSecondaryContainer: root.accent
    readonly property color mTertiary: root.success
    readonly property color mOnTertiary: root.bg
    readonly property color mSurface: root.bg
    readonly property color mOnSurface: root.text
    readonly property color mOnSurfaceVariant: root.subtext
    readonly property color mSurfaceContainerLowest: Qt.darker(root.bg, 1.25)
    readonly property color mSurfaceContainerLow: root.bg
    readonly property color mSurfaceContainer: root.surface
    readonly property color mSurfaceContainerHigh: Qt.lighter(root.surface, 1.1)
    readonly property color mSurfaceContainerHighest: root.border
    readonly property color mOutline: root.dim
    readonly property color mOutlineVariant: root.border
    readonly property color mError: root.error
    readonly property color mOnError: root.bg
    readonly property color mErrorContainer: root.failure
    readonly property color mScrim: root.backdrop

    // shape
    readonly property int radiusSmall: 6
    readonly property int radiusMed: 8
    readonly property int radiusLarge: 14
    readonly property int radiusFull: 999

    // type
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    // Material Symbols ligature icons (upstream icon set; package installed
    // via home.packages). Labels intentionally use the system default sans.
    readonly property string iconFont: "Material Symbols Outlined"
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

    // NOTE: no compositor reload hook here. Niri live-reloads config.kdl on
    // save, and Niri border theming arrives in P6 via the skein deploy table
    // (a generated colors snippet included from config.kdl), so the shell
    // never needs to poke the compositor on theme switches.

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
