import QtQuick
import Quickshell.Services.UPower
import qs.components

Pill {
    id: root
    visible: UPower.displayDevice != null

    // percentage is a 0-1 fraction despite the name; tolerate 0-100 too.
    property real pctRaw: UPower.displayDevice?.percentage ?? 0
    property real pct: pctRaw > 1 ? pctRaw : pctRaw * 100
    // FullyCharged also means on AC (UPower reports it, not Charging).
    property bool charging: {
        const s = UPower.displayDevice?.state;
        return s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged;
    }

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: root.fg
        text: root.charging ? "󰂄" : "󰁹"
    }
    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: root.fg
        text: Math.round(root.pct) + "%"
    }
}
