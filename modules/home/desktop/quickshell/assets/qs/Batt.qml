import QtQuick
import Quickshell.Services.UPower

Pill {
    id: root
    visible: UPower.displayDevice != null

    // percentage is a 0-1 fraction despite the name; tolerate 0-100 too.
    property real pctRaw: UPower.displayDevice?.percentage ?? 0
    property real pct: pctRaw > 1 ? pctRaw : pctRaw * 100
    property bool charging: UPower.displayDevice?.state === UPowerDeviceState.Charging

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
        color: root.fg
        text: root.charging ? "󰂄" : "󰁹"
    }
    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        color: root.fg
        text: Math.round(root.pct) + "%"
    }
}
