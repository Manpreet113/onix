pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reactive Skein Theme Engine
// Subscribes directly to skeind's Unix domain socket for 0-latency live color broadcasts,
// with FileView fallback on ~/.cache/skein/theme.json.
Singleton {
    id: root

    readonly property string themeFile: Quickshell.env("HOME") + "/.cache/skein/theme.json"
    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000") + "/skeind.sock"

    // Material You / Skein tonal scheme core tokens (with solid dark fallbacks)
    property color background: "#060606"
    property color surface: "#0F0F0F"
    property color surfaceVariant: "#1B1B1B"
    property color surface2: surfaceVariant
    property color primary: "#555555"
    property color accent: "#777777"
    property color textOnPrimary: "#060606"
    property color secondary: "#555555"
    property color text: "#F2F2F2"
    property color subtext: "#C4C4C4"
    property color fg: text
    property color dim: "#5D5D5D"
    property color muted: dim
    property color border: "#2B2B2B"
    property color error: "#B69690"
    readonly property color red: error
    readonly property color blue: accent
    property color success: "#8DA692"
    property color warning: "#A2A084"
    property bool darkMode: true

    // Computed translucent colors for floating islands, cards, and pills
    readonly property color islandBg: Qt.rgba(Math.max(0.06, background.r), Math.max(0.07, background.g), Math.max(0.09, background.b), 0.78)
    readonly property color islandBorder: Qt.rgba(1, 1, 1, 0.10)
    readonly property color pillHover: Qt.rgba(1, 1, 1, 0.12)
    readonly property color powerHover: Qt.rgba(error.r, error.g, error.b, 0.25)
    readonly property color dotBorder: Qt.rgba(1, 1, 1, 0.15)
    readonly property color wsHover: Qt.rgba(1, 1, 1, 0.10)
    readonly property color occupiedBg: Qt.rgba(text.r, text.g, text.b, 0.70)

    // Caelestia Material 3 Soft Luxury Frosted Glass Tokens
    readonly property color glassBg: Qt.rgba(Math.max(0.07, background.r), Math.max(0.07, background.g), Math.max(0.10, background.b), 0.82)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.11)
    readonly property color glassSpecular: Qt.rgba(1, 1, 1, 0.18)
    readonly property color glassShadow: Qt.rgba(0, 0, 0, 0.55)
    readonly property color cardBg: Qt.rgba(Math.max(0.11, surface.r * 1.5), Math.max(0.11, surface.g * 1.5), Math.max(0.14, surface.b * 1.5), 0.72)
    readonly property color cardBorder: Qt.rgba(1, 1, 1, 0.09)
    readonly property color chipBg: Qt.rgba(1, 1, 1, 0.06)
    readonly property color chipHover: Qt.rgba(1, 1, 1, 0.14)
    readonly property color chipActive: accent
    readonly property color chipActiveText: "#060606"

    // Clean status signal colors
    readonly property color signalLed: "#00E676"
    readonly property color signalAmber: "#FFB300"
    readonly property color signalOrange: "#FF5722"

    // Modern Geometric & Iconic Typography (Ambxst / Caelestia / Noctalia)
    readonly property string fontPrimary: "Plus Jakarta Sans"
    readonly property string fontDisplay: "Plus Jakarta Sans"
    readonly property string fontIcons: "Material Symbols Rounded"
    readonly property string fontMono: "JetBrainsMono Nerd Font"

    // Seed extraction parameters from Skein
    property real seedLightness: 0.38
    property real seedChroma: 0.05
    property real seedHue: 0.0
    readonly property bool isLightWallpaper: seedLightness > 0.58 || (!darkMode)

    // Dynamic brand watermark colors sourced from Skein (adapts to light/dark wallpapers)
    readonly property color watermarkText: isLightWallpaper ? "#0A0A0C" : text
    readonly property color watermarkSubtext: isLightWallpaper ? (seedChroma > 0.03 ? primary : "#333333") : accent
    readonly property color watermarkLogo: isLightWallpaper ? (seedChroma > 0.03 ? primary : "#0A0A0C") : accent
    readonly property color watermarkOutline: isLightWallpaper ? "transparent" : Qt.rgba(0, 0, 0, 0.75)
    readonly property color watermarkShadow: isLightWallpaper ? Qt.rgba(0, 0, 0, 0.20) : Qt.rgba(0, 0, 0, 0.85)

    function parseTheme(raw: string): void {
        if (!raw || raw.trim().length === 0)
            return;
        try {
            const data = JSON.parse(raw);
            if (data.background) root.background = data.background;
            if (data.surface) root.surface = data.surface;
            if (data.surface_variant) root.surfaceVariant = data.surface_variant;
            if (data.primary) root.primary = data.primary;
            if (data.accent) root.accent = data.accent;
            if (data.text) root.text = data.text;
            if (data.subtext) root.subtext = data.subtext;
            if (data.dim) root.dim = data.dim;
            if (data.border) root.border = data.border;
            if (data.error) root.error = data.error;
            if (data.success) root.success = data.success;
            if (data.warning) root.warning = data.warning;
            if (data.dark_mode !== undefined) root.darkMode = data.dark_mode;
            if (data.seed_oklch) {
                if (data.seed_oklch.lightness !== undefined)
                    root.seedLightness = data.seed_oklch.lightness;
                if (data.seed_oklch.chroma !== undefined)
                    root.seedChroma = data.seed_oklch.chroma;
                if (data.seed_oklch.hue !== undefined)
                    root.seedHue = data.seed_oklch.hue;
            }
            console.log(`[onix-theme] Live theme applied! Accent: ${root.accent}, Primary: ${root.primary}, SeedL: ${root.seedLightness.toFixed(2)}, isLight: ${root.isLightWallpaper}`);
        } catch (e) {
            console.warn("[onix-theme] Failed to parse theme.json:", e);
        }
    }

    // Direct IPC socket stream from skeind daemon
    Socket {
        id: skeinSocket
        path: root.socketPath
        connected: true

        parser: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                root.parseTheme(data);
            }
        }

        onConnectionStateChanged: {
            if (!connected)
                reconnectTimer.restart();
        }
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!skeinSocket.connected)
                skeinSocket.connected = true;
        }
    }

    // Initial bootstrap before socket connects
    FileView {
        id: fileView
        path: root.themeFile
        printErrors: false
        blockLoading: true

        onLoaded: {
            if (!skeinSocket.connected)
                root.parseTheme(fileView.text());
        }
    }

    Component.onCompleted: {
        root.parseTheme(fileView.text());
    }
}
