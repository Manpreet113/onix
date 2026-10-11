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
    property bool powerOpen: false
    property bool clipboardOpen: false
    property bool keybindsOpen: false

    signal clearPopupsRequested()

    // true while quickcenter sliders drag: the OSD stays quiet (upstream
    // suppress_osd flag behavior)
    property bool osdSuppress: false

    function toggleLauncher(): void {
        root.launcherOpen = !root.launcherOpen;
        if (root.launcherOpen)
            root.closeOthers("launcher");
    }

    function toggleQuickCenter(): void {
        root.quickCenterOpen = !root.quickCenterOpen;
        if (root.quickCenterOpen)
            root.closeOthers("quickCenter");
    }

    function toggleSettings(): void {
        root.settingsOpen = !root.settingsOpen;
        if (root.settingsOpen)
            root.closeOthers("settings");
    }

    function togglePower(): void {
        root.powerOpen = !root.powerOpen;
        if (root.powerOpen)
            root.closeOthers("power");
    }

    function toggleClipboard(): void {
        root.clipboardOpen = !root.clipboardOpen;
        if (root.clipboardOpen)
            root.closeOthers("clipboard");
    }

    function toggleKeybinds(): void {
        root.keybindsOpen = !root.keybindsOpen;
        if (root.keybindsOpen)
            root.closeOthers("keybinds");
    }

    function closeOthers(except): void {
        if (except !== "launcher")
            root.launcherOpen = false;
        if (except !== "quickCenter")
            root.quickCenterOpen = false;
        if (except !== "settings")
            root.settingsOpen = false;
        if (except !== "power")
            root.powerOpen = false;
        if (except !== "clipboard")
            root.clipboardOpen = false;
        if (except !== "keybinds")
            root.keybindsOpen = false;
    }

    function closeAll(): void {
        root.launcherOpen = false;
        root.quickCenterOpen = false;
        root.settingsOpen = false;
        root.powerOpen = false;
        root.clipboardOpen = false;
        root.keybindsOpen = false;
    }
}
