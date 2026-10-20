pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// OSD state manager: triggers the morphing center island when volume or media state changes
Singleton {
    id: root

    property bool active: false
    property real value: 0.0
    property bool muted: false
    property string icon: "󰕾"
    property string label: "Volume"

    property bool _ready: false

    function trigger(newIcon: string, val: real, isMuted: bool, lbl: string): void {
        icon = newIcon;
        value = Math.max(0.0, Math.min(1.0, val));
        muted = isMuted;
        label = lbl || "Volume";
        active = true;
        osdTimer.restart();
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged(): void {
            if (!root._ready) return;
            const sink = Pipewire.defaultAudioSink;
            if (!sink || !sink.audio) return;
            const v = sink.audio.volume;
            const m = sink.audio.muted;
            const ic = m ? "󰝟" : (v > 0.66 ? "󰕾" : (v > 0.33 ? "󰖀" : "󰕿"));
            root.trigger(ic, v, m, "Volume");
        }

        function onMutedChanged(): void {
            if (!root._ready) return;
            const sink = Pipewire.defaultAudioSink;
            if (!sink || !sink.audio) return;
            const v = sink.audio.volume;
            const m = sink.audio.muted;
            const ic = m ? "󰝟" : (v > 0.66 ? "󰕾" : (v > 0.33 ? "󰖀" : "󰕿"));
            root.trigger(ic, v, m, "Volume");
        }
    }

    Timer {
        id: readyTimer
        interval: 1200
        running: true
        repeat: false
        onTriggered: root._ready = true
    }

    Timer {
        id: osdTimer
        interval: 1500
        repeat: false
        onTriggered: root.active = false
    }
}
