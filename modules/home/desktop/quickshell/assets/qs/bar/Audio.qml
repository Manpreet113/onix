import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.popups
import qs.theme

GlassChip {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property real vol: sink?.audio.volume ?? 0
    property bool muted: sink?.audio.muted ?? false

    active: PopupState.activePopup === "audio"
    fg: root.muted ? Theme.error : (root.active ? Theme.textOnPrimary : Theme.text)
    squircleRadius: 13
    implicitWidth: 28
    implicitHeight: 28

    onClicked: PopupState.toggle("audio")

    onWheel: wheel => {
        if (!root.sink?.audio) return;
        const delta = wheel.angleDelta.y > 0 ? 0.04 : -0.04;
        const nextVol = Math.max(0.0, Math.min(1.5, root.vol + delta));
        root.sink.audio.volume = nextVol;
        if (delta > 0 && root.muted)
            root.sink.audio.muted = false;
    }

    Text {
        Layout.alignment: Qt.AlignCenter
        font.family: Theme.fontIcons
        font.pixelSize: 16
        color: root.fg
        text: root.muted ? "volume_off" : (root.vol > 0.5 ? "volume_up" : "volume_down")
    }
}
