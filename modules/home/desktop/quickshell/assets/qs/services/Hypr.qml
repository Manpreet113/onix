pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Central Hyprland access: fresh-state discipline lives here so
// widgets stay dumb. Pattern mirrors Caelestia's Hypr service.
Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces
    readonly property var toplevels: Hyprland.toplevels
    readonly property bool usingLua: Hyprland.usingLua

    // Guarded active toplevel: raw Hyprland.activeToplevel goes stale
    // when focus leaves to an empty desktop.
    readonly property HyprlandToplevel activeToplevel: {
        const t = Hyprland.activeToplevel;
        const hasWindows = (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) > 0;
        return (t?.workspace?.name ?? "").startsWith("special:") || hasWindows ? t : null;
    }

    function focusWorkspace(id: int): void {
        Hyprland.dispatch(usingLua ? `hl.dsp.focus({ workspace = "${id}" })` : `workspace ${id}`);
    }

    // Keep cached objects fresh: without these, lists and focus state
    // silently go stale (occupied dots never fill, titles stick).
    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;
            if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || ["fullscreen", "changefloatingmode"].includes(n)) {
                Hyprland.refreshToplevels();
            }
        }
        target: Hyprland
    }
}
