// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWallpaper: wallpaper + theme state backend (ports upstream
// scripts/wallpaper.py, skein edition). Setting a still hands it to the
// skein daemon (`skeinc set`), which re-themes the shell live. Scheme and
// dark-mode choices persist to settings; the daemon honors them as its CLI
// surface grows (skein currently exposes Vibrant/Tonal/Muted + dark mode
// through its TUI, so the eight Material scheme names are stored verbatim
// for schema parity and mapped to the closest skein scheme where one exists).
pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    // Exo scheme name -> closest skein scheme (for future CLI wiring)
    function skeinScheme(name): string {
        switch (name) {
        case "monochrome":
        case "neutral":
            return "muted";
        case "content":
        case "expressive":
        case "fidelity":
        case "fruit-salad":
        case "rainbow":
            return "vibrant";
        default:
            return "tonal";
        }
    }

    function setWall(path): void {
        if (!path)
            return;
        Quickshell.execDetached(["skeinc", "set", path]);
        OnixSettings.set(["appearance", "wallcolors", "wallpaper_path"], path);
    }

    function setColors(scheme): void {
        OnixSettings.set(["appearance", "wallcolors", "color_scheme"], scheme || "tonal-spot");
    }

    function setDarkMode(dark): void {
        OnixSettings.set(["appearance", "wallcolors", "dark_mode"], dark);
    }
}
