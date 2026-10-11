// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixRecorder: screen-recording backend state (ports upstream
// scripts/recorder.py). P2 ships the state machine + CLI hooks; the full
// backend (output paths, start/stop notifications, region select via slurp,
// pause signaling) lands with the recorder packages in P6. Calls are safe
// no-ops until then.
pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    property bool active: false
    property bool paused: false
    property date startedAt: new Date(0)

    signal started()
    signal stopped()

    function elapsedSecs(): int {
        if (!root.active)
            return 0;
        return Math.max(0, Math.floor((Date.now() - root.startedAt.getTime()) / 1000));
    }

    function recordScreen(withAudio: bool): void {
        if (root.active)
            return;
        var cmd = ["gpu-screen-recorder", "-w", "screen", "-f", "60"];
        if (withAudio)
            cmd.push("-a", "default_output");
        cmd.push("-o", Quickshell.env("HOME") + "/Videos/onix-recording.mp4");
        Quickshell.execDetached(cmd);
        root.active = true;
        root.paused = false;
        root.startedAt = new Date(Date.now());
        root.started();
    }

    function recordRegion(withAudio: bool): void {
        if (root.active)
            return;
        // region geometry via slurp arrives in P6; fullscreen for now
        root.recordScreen(withAudio);
    }

    function stopRecording(): void {
        if (!root.active)
            return;
        Quickshell.execDetached(["pkill", "-INT", "gpu-screen-recorder"]);
        root.active = false;
        root.paused = false;
        root.stopped();
    }

    function togglePause(): void {
        if (!root.active)
            return;
        root.paused = !root.paused;
        Quickshell.execDetached(["pkill", "-USR1", "gpu-screen-recorder"]);
    }
}
