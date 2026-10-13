import QtQuick
import qs.services

Text {
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
    color: "#5D5D5D"
    text: {
        const t = (Hypr.activeToplevel?.title ?? "").trim();
        if (!t)
            return "Desktop";
        return t.length > 44 ? t.slice(0, 43) + "…" : t;
    }
}
