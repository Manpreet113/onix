// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// Onix shell entry point (Niri session). Singletons (OnixTheme, OnixSettings,
// OnixNiri, OnixApps, OnixUi, OnixRecorder) self-register; the dual bars,
// OSD, and notification popups instantiate below. Launcher (P3),
// quickcenter (P4), and settings (P5) hook into OnixUi state next.
import QtQuick
import Quickshell

Scope {
    id: root

    // Touch singletons so load failures surface immediately in the log.
    property var theme: OnixTheme
    property var prefs: OnixSettings
    property var niri: OnixNiri
    property var apps: OnixApps
    property var ui: OnixUi
    property var recorder: OnixRecorder
    property var menu: OnixMenu

    OnixBar {
        barId: 0
    }

    OnixBar {
        barId: 1
    }

    OnixOsd {
    }

    OnixNotifs {
    }

    OnixLauncher {
    }
}
