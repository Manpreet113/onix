pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.services

// Central hardware and system controls service (Brightness, WiFi, Bluetooth, DND)
Singleton {
    id: root

    // --- BRIGHTNESS ---
    property real brightness: 1.0
    property real maxBrightness: 15360.0

    readonly property string brightPath: "/sys/class/backlight/intel_backlight/brightness"
    readonly property string maxBrightPath: "/sys/class/backlight/intel_backlight/max_brightness"

    FileView {
        id: brightView
        path: root.brightPath
        watchChanges: true
        printErrors: false
        blockLoading: true

        onLoaded: root.updateBrightness(brightView.text())
        onFileChanged: root.updateBrightness(brightView.text())
        onTextChanged: root.updateBrightness(brightView.text())
    }

    FileView {
        id: maxBrightView
        path: root.maxBrightPath
        printErrors: false
        blockLoading: true
        onLoaded: {
            const m = parseFloat(maxBrightView.text().trim());
            if (m > 0) root.maxBrightness = m;
        }
    }

    Process {
        id: brightProc
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                const parts = line.split(",");
                if (parts.length >= 4) {
                    const pctStr = parts[3].replace("%", "").trim();
                    const p = parseFloat(pctStr) / 100.0;
                    if (!isNaN(p)) {
                        root.brightness = Math.max(0.01, Math.min(1.0, p));
                        Osd.trigger(p > 0.6 ? "brightness_high" : (p > 0.3 ? "brightness_medium" : "brightness_low"), p, false, "Brightness");
                    }
                }
            }
        }
    }

    function adjustBrightness(step: string): void {
        brightProc.command = ["brightnessctl", "set", step, "-m"];
        brightProc.running = true;
    }

    function updateBrightness(raw: string): void {
        const val = parseFloat((raw || "").trim());
        if (!isNaN(val) && root.maxBrightness > 0) {
            root.brightness = Math.max(0.05, Math.min(1.0, val / root.maxBrightness));
        }
    }

    function setBrightness(pct: real): void {
        const p = Math.max(0.05, Math.min(1.0, pct));
        root.brightness = p;
        const targetPercent = Math.round(p * 100);
        brightProc.command = ["brightnessctl", "set", targetPercent + "%", "-m"];
        brightProc.running = true;
    }

    // --- DO NOT DISTURB ---
    property bool dnd: false

    function toggleDnd(): void {
        dnd = !dnd;
    }

    // --- WI-FI ---
    property bool wifiEnabled: true
    property bool wifiConnected: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property string wifiIp: ""
    property string wifiDevice: "wlp0s20f3"

    Process {
        id: wifiRadioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = (data.trim() === "enabled");
            }
        }
    }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "-t", "-f", "active,ssid,signal", "dev", "wifi"]
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split("\n");
                let foundActive = false;
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts[0] === "yes" && parts.length >= 3) {
                        foundActive = true;
                        root.wifiConnected = true;
                        root.wifiSsid = parts[1] || "Connected";
                        root.wifiSignal = parseInt(parts[2], 10) || 50;
                        break;
                    }
                }
                if (!foundActive) {
                    root.wifiConnected = false;
                    root.wifiSsid = "";
                    root.wifiSignal = 0;
                }
            }
        }
    }

    Process {
        id: wifiIpProc
        command: ["sh", "-c", "ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n 1"]
        stdout: SplitParser {
            onRead: data => {
                root.wifiIp = data.trim();
            }
        }
    }

    function refreshWifi(): void {
        if (!wifiRadioProc.running) wifiRadioProc.running = true;
        if (!wifiStatusProc.running) wifiStatusProc.running = true;
        if (!wifiIpProc.running) wifiIpProc.running = true;
    }

    function toggleWifi(): void {
        root.wifiEnabled = !root.wifiEnabled;
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"]);
        wifiRefreshTimer.restart();
    }

    function disconnectWifi(): void {
        Quickshell.execDetached(["nmcli", "dev", "disconnect", root.wifiDevice]);
        wifiRefreshTimer.restart();
    }

    function connectWifi(ssid: string, password: string): void {
        if (password && password.length > 0) {
            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid, "password", password]);
        } else {
            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", ssid]);
        }
        wifiRefreshTimer.restart();
    }

    Timer {
        id: wifiRefreshTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.refreshWifi()
    }

    // --- BLUETOOTH ---
    property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    property int btConnectedCount: 0
    property string btConnectedDevice: ""
    property string btConnectedMac: ""
    property int btBattery: -1

    Process {
        id: btStatusProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const match = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.+)$/);
                if (match) {
                    root.btConnectedCount++;
                    root.btConnectedMac = match[1];
                    root.btConnectedDevice = match[2];
                    fetchBtBattery(match[1]);
                }
            }
        }
    }

    Process {
        id: btBatteryProc
        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/Battery Percentage:\s*0x[0-9a-fA-F]+\s*\(([0-9]+)\)/);
                if (match) {
                    root.btBattery = parseInt(match[1], 10);
                }
            }
        }
    }

    function fetchBtBattery(mac: string): void {
        if (!mac) return;
        btBatteryProc.command = ["bluetoothctl", "info", mac];
        if (!btBatteryProc.running) btBatteryProc.running = true;
    }

    function refreshBt(): void {
        root.btConnectedCount = 0;
        root.btConnectedDevice = "";
        root.btConnectedMac = "";
        root.btBattery = -1;
        if (!btStatusProc.running) btStatusProc.running = true;
    }

    function toggleBluetooth(): void {
        const target = !root.btEnabled;
        root.btEnabled = target;
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = target;
        }
        Quickshell.execDetached(["bluetoothctl", "power", target ? "on" : "off"]);
        btRefreshTimer.restart();
    }

    function connectBt(mac: string): void {
        Quickshell.execDetached(["bluetoothctl", "connect", mac]);
        btRefreshTimer.restart();
    }

    function disconnectBt(mac: string): void {
        Quickshell.execDetached(["bluetoothctl", "disconnect", mac]);
        btRefreshTimer.restart();
    }

    function removeBt(mac: string): void {
        Quickshell.execDetached(["bluetoothctl", "remove", mac]);
        btRefreshTimer.restart();
    }

    Timer {
        id: btRefreshTimer
        interval: 8000
        repeat: true
        running: true
        onTriggered: root.refreshBt()
    }

    Component.onCompleted: {
        root.updateBrightness(brightView.text());
        root.refreshWifi();
        root.refreshBt();
    }
}
