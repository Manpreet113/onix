pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

Singleton {
    id: root

    property bool open: false
    property string mode: "region" // "region" | "window" | "fullscreen"
    property bool copyToClipboard: true
    property bool saveToDisk: true
    property bool annotateAfter: false
    property int delaySeconds: 0 // 0, 3, 5
    property int countdown: 0

    property string freezePath: "/tmp/onix-snip-freeze.png"
    property string freezeUrl: ""
    property bool hasFreeze: false

    property var windows: []
    property int activeWorkspaceId: 1
    property var hoveredWindow: null

    // Selection rect in region mode
    property real selX: 0
    property real selY: 0
    property real selW: 0
    property real selH: 0
    readonly property bool hasSelection: Math.abs(selW) >= 8 && Math.abs(selH) >= 8

    // Result & Toast
    property string lastCapturedFile: ""
    property bool toastOpen: false
    property bool flashActive: false

    function toggle(): void {
        if (open) {
            cancel();
        } else {
            trigger();
        }
    }

    function trigger(): void {
        if (countdown > 0)
            return;

        if (delaySeconds > 0) {
            countdown = delaySeconds;
            countdownTimer.restart();
            return;
        }

        launchOverlay();
    }

    function launchOverlay(): void {
        root.mode = "region";
        root.hoveredWindow = null;
        root.selX = 0;
        root.selY = 0;
        root.selW = 0;
        root.selH = 0;

        // 1. Grab active workspace & window list from Hyprland
        if (queryWorkspaceProc.running)
            queryWorkspaceProc.running = false;
        queryWorkspaceProc.running = true;

        // 2. Capture instantaneous freeze-frame via grim
        if (freezeProc.running)
            freezeProc.running = false;
        freezeProc.running = true;
    }

    function cancel(): void {
        countdownTimer.stop();
        countdown = 0;
        open = false;
        hasFreeze = false;
        selX = 0;
        selY = 0;
        selW = 0;
        selH = 0;
        Quickshell.execDetached(["rm", "-f", root.freezePath]);
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown <= 0) {
                countdownTimer.stop();
                root.launchOverlay();
            }
        }
    }

    Process {
        id: freezeProc
        command: ["grim", root.freezePath]
        onExited: exitCode => {
            console.log("[Screenshot] freezeProc exited with code:", exitCode);
            if (exitCode === 0) {
                root.freezeUrl = "file://" + root.freezePath + "?t=" + Date.now();
                root.hasFreeze = true;
                root.open = true;
                console.log("[Screenshot] overlay opened successfully, freezeUrl:", root.freezeUrl);
            } else {
                console.log("[Screenshot] Grim freeze capture failed:", exitCode);
            }
        }
    }

    Process {
        id: queryWorkspaceProc
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: wsCollector
            waitForEnd: true
            onStreamFinished: {
                try {
                    const ws = JSON.parse(wsCollector.text);
                    if (ws && ws.id !== undefined) {
                        root.activeWorkspaceId = ws.id;
                    }
                } catch (e) {
                    console.log("[Screenshot] Failed to parse activeworkspace:", e);
                }
                if (queryClientsProc.running)
                    queryClientsProc.running = false;
                queryClientsProc.running = true;
            }
        }
    }

    Process {
        id: queryClientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            waitForEnd: true
            onStreamFinished: {
                try {
                    const list = JSON.parse(clientsCollector.text);
                    if (Array.isArray(list)) {
                        root.windows = list.filter(c => c.mapped && !c.hidden && c.workspace && c.workspace.id === root.activeWorkspaceId);
                    }
                } catch (e) {
                    console.log("[Screenshot] Failed to parse clients:", e);
                }
            }
        }
    }

    function captureSelection(): void {
        if (!hasSelection)
            return;
        const x = Math.round(Math.min(selX, selX + selW));
        const y = Math.round(Math.min(selY, selY + selH));
        const w = Math.round(Math.abs(selW));
        const h = Math.round(Math.abs(selH));
        captureGeometry(`${x},${y} ${w}x${h}`);
    }

    function captureWindow(winObj: var): void {
        if (!winObj || !winObj.at || !winObj.size)
            return;
        const x = Math.round(winObj.at[0]);
        const y = Math.round(winObj.at[1]);
        const w = Math.round(winObj.size[0]);
        const h = Math.round(winObj.size[1]);
        captureGeometry(`${x},${y} ${w}x${h}`);
    }

    function captureFullscreen(): void {
        captureGeometry("");
    }

    function captureGeometry(geom: string): void {
        // Close overlay immediately
        root.open = false;
        root.flashActive = true;
        flashTimer.restart();

        const ts = Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss");
        const dir = Quickshell.env("HOME") + "/Pictures/Screenshots";
        const finalFile = `${dir}/Screenshot_${ts}.png`;
        const tempFile = `/tmp/onix-snip-clipboard.png`;
        const targetPath = root.saveToDisk ? finalFile : tempFile;

        let cmd = root.saveToDisk ? `mkdir -p "${dir}" && ` : "";

        if (geom && geom.length > 0) {
            // geom is formatted as "X,Y WxH"
            const parts = geom.split(" ");
            const coords = parts[0].split(",");
            const sizes = parts[1].split("x");
            const x = coords[0];
            const y = coords[1];
            const w = sizes[0];
            const h = sizes[1];

            // Crop from the pristine freeze-frame captured BEFORE overlay was created!
            cmd += `if [ -f "${root.freezePath}" ]; then `
                + `ffmpeg -y -i "${root.freezePath}" -filter:v "crop=${w}:${h}:${x}:${y}" -update 1 "${targetPath}"; `
                + `else sleep 0.15 && grim -g "${geom}" "${targetPath}"; fi`;
        } else {
            // Fullscreen: copy pristine freeze-frame directly!
            cmd += `if [ -f "${root.freezePath}" ]; then `
                + `cp "${root.freezePath}" "${targetPath}"; `
                + `else sleep 0.15 && grim "${targetPath}"; fi`;
        }

        if (root.copyToClipboard) {
            cmd += ` && wl-copy --type image/png < "${targetPath}"`;
        }

        if (root.annotateAfter) {
            cmd += ` && (satty -f "${targetPath}" || swappy -f "${targetPath}") &`;
        }

        Quickshell.execDetached(["sh", "-c", cmd]);

        root.lastCapturedFile = targetPath;
        toastTimer.restart();
    }

    Timer {
        id: flashTimer
        interval: 160
        onTriggered: root.flashActive = false
    }

    Timer {
        id: toastTimer
        interval: 350
        onTriggered: {
            root.toastOpen = true;
            toastDismissTimer.restart();
        }
    }

    Timer {
        id: toastDismissTimer
        interval: 4500
        onTriggered: root.toastOpen = false
    }

    function editLast(): void {
        if (root.lastCapturedFile.length > 0) {
            Quickshell.execDetached(["sh", "-c", `satty -f "${root.lastCapturedFile}" || swappy -f "${root.lastCapturedFile}"`]);
            root.toastOpen = false;
        }
    }

    function openLast(): void {
        if (root.lastCapturedFile.length > 0) {
            Quickshell.execDetached(["xdg-open", root.lastCapturedFile]);
            root.toastOpen = false;
        }
    }

    function openFolder(): void {
        const dir = Quickshell.env("HOME") + "/Pictures/Screenshots";
        Quickshell.execDetached(["xdg-open", dir]);
        root.toastOpen = false;
    }
}
