import QtQuick
import Quickshell.Hyprland

Text {
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    color: "#5D5D5D"
    text: {
        const t = (Hyprland.activeToplevel?.title ?? "").trim();
        if (!t)
            return "Desktop";
        return t.length > 44 ? t.slice(0, 43) + "…" : t;
    }
}
