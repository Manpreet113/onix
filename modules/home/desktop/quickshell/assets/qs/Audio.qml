import QtQuick
import Quickshell.Services.Pipewire

Pill {
    id: root

    // NOTE: node must be bound via the PwObjectTracker in shell.qml,
    // otherwise volume/muted read invalid.
    property var sink: Pipewire.defaultAudioSink
    property real vol: sink?.audio.volume ?? 0
    property bool muted: sink?.audio.muted ?? false

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: root.fg
        text: root.muted ? "󰝟" : (root.vol > 0.66 ? "󰕾" : (root.vol > 0.33 ? "󰖀" : "󰕿"))
    }
    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: root.fg
        text: Math.round(root.vol * 100) + "%"
    }
}
