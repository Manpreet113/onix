pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Font Loaders
    readonly property FontLoader outfit: FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Outfit-Variable.ttf")
    }
    readonly property FontLoader jakartaBold: FontLoader {
        source: Qt.resolvedUrl("assets/fonts/PlusJakartaSans-Bold.ttf")
    }
    readonly property FontLoader jakartaExtraBold: FontLoader {
        source: Qt.resolvedUrl("assets/fonts/PlusJakartaSans-ExtraBold.ttf")
    }
    readonly property FontLoader materialIcons: FontLoader {
        source: Qt.resolvedUrl("assets/fonts/MaterialSymbolsRounded.ttf")
    }

    readonly property string fontDisplay: outfit.status === FontLoader.Ready ? outfit.name : "Outfit"
    readonly property string fontBody: jakartaBold.status === FontLoader.Ready ? jakartaBold.name : "Plus Jakarta Sans"
    readonly property string fontIcons: materialIcons.status === FontLoader.Ready ? materialIcons.name : "Material Symbols Rounded"

    // Material You / Onix Tonal Tokens (matching desktop Theme.qml)
    property color background: "#060605"
    property color surface: "#0F0F0F"
    property color surfaceVariant: "#1B1B1A"
    property color primary: "#9F9E9B"
    property color accent: "#C5C4C0"
    property color text: "#F2F2F1"
    property color subtext: "#C4C4C4"
    property color dim: "#5E5D5D"
    property color border: "#2B2B2B"
    property color error: "#B69690"
    property color success: "#8DA692"
    property color warning: "#A2A084"

    // Caelestia / Onix Soft Frosted Glass Tokens
    readonly property color glassBg: Qt.rgba(0.06, 0.06, 0.08, 0.72)
    readonly property color glassBorder: Qt.rgba(1.0, 1.0, 1.0, 0.10)
    readonly property color glassSpecular: Qt.rgba(1.0, 1.0, 1.0, 0.18)
    readonly property color glassShadow: Qt.rgba(0.0, 0.0, 0.0, 0.60)

    readonly property color chipBg: Qt.rgba(1.0, 1.0, 1.0, 0.06)
    readonly property color chipBorder: Qt.rgba(1.0, 1.0, 1.0, 0.12)
    readonly property color chipHover: Qt.rgba(1.0, 1.0, 1.0, 0.14)

    readonly property color errorBg: Qt.rgba(0.71, 0.59, 0.56, 0.18)

    // Dynamic Theme Loader from Onix session
    FileView {
        id: varThemeView
        path: "/var/cache/onix/theme.json"
        printErrors: false
        onLoaded: {
            const t = varThemeView.text().trim();
            if (t.length > 0) root.parseTheme(t);
        }
    }

    FileView {
        id: tmpThemeView
        path: "/tmp/onix/theme.json"
        printErrors: false
        onLoaded: {
            const t = tmpThemeView.text().trim();
            if (t.length > 0) root.parseTheme(t);
        }
    }

    function parseTheme(raw: string): void {
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
        } catch (e) {
            console.log("[Greeter Theme] parseTheme error:", e);
        }
    }

    Component.onCompleted: {
        const vt = varThemeView.text().trim();
        if (vt.length > 0) {
            parseTheme(vt);
            return;
        }
        const tt = tmpThemeView.text().trim();
        if (tt.length > 0) {
            parseTheme(tt);
        }
    }
}
