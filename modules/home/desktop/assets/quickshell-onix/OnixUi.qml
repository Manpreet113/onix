// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixUi: shell-wide window state (ports the upstream WindowManager window
// toggling for shell surfaces). Bar buttons flip these flags; the launcher /
// quickcenter / settings windows (P3–P5) bind their visibility to them.
pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool launcherOpen: false
    property bool quickCenterOpen: false
    property bool settingsOpen: false

    function toggleLauncher(): void {
        root.launcherOpen = !root.launcherOpen;
        if (root.launcherOpen) {
            root.quickCenterOpen = false;
            root.settingsOpen = false;
        }
    }

    function toggleQuickCenter(): void {
        root.quickCenterOpen = !root.quickCenterOpen;
        if (root.quickCenterOpen) {
            root.launcherOpen = false;
            root.settingsOpen = false;
        }
    }

    function toggleSettings(): void {
        root.settingsOpen = !root.settingsOpen;
        if (root.settingsOpen) {
            root.launcherOpen = false;
            root.quickCenterOpen = false;
        }
    }

    function closeAll(): void {
        root.launcherOpen = false;
        root.quickCenterOpen = false;
        root.settingsOpen = false;
    }
}
