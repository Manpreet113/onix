import QtQuick
import Quickshell.Bluetooth

Pill {
    id: root
    property bool powered: Bluetooth.defaultAdapter?.enabled ?? false

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: root.fg
        text: "󰖩"
    }
    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: root.fg
        text: root.powered ? "󰂯" : "󰂲"
    }
}
