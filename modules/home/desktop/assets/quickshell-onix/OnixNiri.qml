// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// Niri IPC bridge for the Onix shell. Niri exposes a JSON protocol over
// $NIRI_SOCKET: one persistent connection subscribed to "EventStream" for
// live updates, fire-and-forget JSON requests for actions, and
// `niri msg -j` one-shots for initial state. (Socket + SplitParser approach
// informed by iNiR's NiriService, GPL-3.0, github.com/snowarch/iNiR.)
//
// Degrades cleanly: with no NIRI_SOCKET (Hyprland session, sandbox) every
// property sits at its empty default and `available` is false, so views can
// render placeholders instead of crashing. Event shapes are parsed
// defensively — unknown events are counted, never fatal. Protocol shapes to
// re-verify against `niri msg event-stream` once running on Niri (P6).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET")
    readonly property bool available: socketPath !== ""

    property var workspaces: []
    property var windows: []
    property var outputs: ({})
    property var activeWindow: null
    property var focusedWorkspace: null
    property string activeOutput: ""
    property bool inOverview: false
    property var keyboardLayoutNames: []
    property int keyboardLayoutIndex: 0

    // diagnostics (surfaced in the P5 about tab later)
    property string lastEvent: ""
    property int unknownEvents: 0

    // ---- actions (fire-and-forget JSON requests) ----

    function sendRequest(obj): void {
        if (!root.available)
            return;
        requestSocket.write(JSON.stringify(obj) + "\n");
        requestSocket.flush();
    }

    function focusWorkspaceById(id): void {
        sendRequest({
            "Action": {
                "FocusWorkspace": {
                    "reference": {
                        "Id": id
                    }
                }
            }
        });
    }

    function focusWorkspaceDown(): void {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]);
    }

    function focusWorkspaceUp(): void {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]);
    }

    function focusWindowById(id): void {
        sendRequest({
            "Action": {
                "FocusWindow": {
                    "id": id
                }
            }
        });
    }

    // ---- state derivation ----

    function derive(): void {
        var fw = null;
        for (var i = 0; i < root.workspaces.length; i++) {
            if (root.workspaces[i].is_focused) {
                fw = root.workspaces[i];
                break;
            }
        }
        if (fw === null) {
            for (var j = 0; j < root.workspaces.length; j++) {
                if (root.workspaces[j].is_active) {
                    fw = root.workspaces[j];
                    break;
                }
            }
        }
        root.focusedWorkspace = fw;
        root.activeOutput = (fw !== null && fw.output !== undefined) ? fw.output : "";

        var aw = null;
        for (var k = 0; k < root.windows.length; k++) {
            if (root.windows[k].is_focused) {
                aw = root.windows[k];
                break;
            }
        }
        root.activeWindow = aw;
    }

    // ---- event stream ----

    function handleLine(line): void {
        var trimmed = line.trim();
        if (trimmed.length === 0)
            return;
        var event = null;
        try {
            event = JSON.parse(trimmed);
        } catch (e) {
            return;
        }
        var keys = Object.keys(event);
        if (keys.length === 0)
            return;
        var name = keys[0];
        var body = event[name];
        root.lastEvent = name;

        if (name === "WorkspacesChanged" && body.workspaces !== undefined) {
            root.workspaces = body.workspaces;
            root.derive();
        } else if (name === "WorkspaceActivated") {
            for (var i = 0; i < root.workspaces.length; i++)
                root.workspaces[i].is_focused = (root.workspaces[i].id === body.id);
            root.workspacesChanged();
            root.derive();
        } else if (name === "WindowsChanged" && body.windows !== undefined) {
            root.windows = body.windows;
            root.derive();
        } else if (name === "WindowOpenedOrChanged" && body.window !== undefined) {
            var next = root.windows.slice();
            var replaced = false;
            for (var j = 0; j < next.length; j++) {
                if (next[j].id === body.window.id) {
                    next[j] = body.window;
                    replaced = true;
                    break;
                }
            }
            if (!replaced)
                next.push(body.window);
            root.windows = next;
            root.derive();
        } else if (name === "WindowClosed") {
            root.windows = root.windows.filter(function (w) {
                return w.id !== body.id;
            });
            root.derive();
        } else if (name === "WindowFocusChanged") {
            for (var k = 0; k < root.windows.length; k++)
                root.windows[k].is_focused = (root.windows[k].id === body.id);
            root.windowsChanged();
            root.derive();
        } else if (name === "KeyboardLayoutsChanged" && body.keyboard_layouts !== undefined) {
            root.keyboardLayoutNames = body.keyboard_layouts.names || [];
        } else if (name === "KeyboardLayoutSwitched") {
            root.keyboardLayoutIndex = body.idx || 0;
        } else if (name.indexOf("OverviewOpened") === 0) {
            root.inOverview = true;
        } else if (name.indexOf("OverviewClosed") === 0) {
            root.inOverview = false;
        } else if (name === "WorkspaceActiveWindowChanged" || name === "WindowUrgencyChanged") {
            root.refreshWindows();
        } else {
            root.unknownEvents++;
        }
    }

    Socket {
        id: streamSocket
        path: root.socketPath
        connected: root.available
        onConnectionStateChanged: {
            if (connected) {
                streamSocket.write('"EventStream"\n');
                streamSocket.flush();
                root.refresh();
            }
        }
        parser: SplitParser {
            onRead: line => root.handleLine(line)
        }
    }

    Socket {
        id: requestSocket
        path: root.socketPath
        connected: root.available
        // responses to action requests are always "Handled" — discard
        parser: SplitParser {
            onRead: line => {}
        }
    }

    // ---- one-shot state fetches ----

    function refresh(): void {
        if (!root.available)
            return;
        fetchWorkspaces.running = true;
        fetchWindows.running = true;
        fetchOutputs.running = true;
    }

    function refreshWindows(): void {
        if (!root.available)
            return;
        fetchWindows.running = true;
    }

    property Process fetchWorkspaces: Process {
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var names = this.text;
                    var parsed = JSON.parse(names);
                    root.workspaces = Array.isArray(parsed) ? parsed : (parsed.workspaces || []);
                    root.derive();
                } catch (e) {}
            }
        }
    }

    property Process fetchWindows: Process {
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    root.windows = Array.isArray(parsed) ? parsed : (parsed.windows || []);
                    root.derive();
                } catch (e) {}
            }
        }
    }

    property Process fetchOutputs: Process {
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.outputs = JSON.parse(this.text);
                } catch (e) {}
            }
        }
    }

    // backstop poll: event stream is authoritative, this only heals races
    Timer {
        interval: 5000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.refresh();
    }
}
