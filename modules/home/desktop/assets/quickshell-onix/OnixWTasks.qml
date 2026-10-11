// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWTasks: pinned + running app dock (ports upstream Tasks, Niri
// branch). Click launches, focuses a lone window, or cycles focus across
// several. Right-click pins/unpins directly for now — the full window-list
// and action menu arrives with the shared menu component in P3.
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property int barId: 0

    readonly property string barSec: root.barId === 0 ? "bar" : "bar2"
    readonly property bool vertical: OnixSettings.get(["interface", root.barSec, "vertical"], false)
    readonly property int density: OnixSettings.get(["interface", root.barSec, "density"], 0)
    readonly property int iconPx: (root.density === 0 || root.density === 1) ? 20 : 16

    function openEntries(): var {
        var seen = {};
        var out = [];
        var wins = OnixNiri.windows;
        for (var i = 0; i < wins.length; i++) {
            var e = OnixApps.findEntry(wins[i].app_id);
            if (e && !seen[e.id] && !OnixApps.isPinned(e.id)) {
                seen[e.id] = true;
                out.push(e);
            }
        }
        return out;
    }

    function windowsFor(entryId): var {
        var out = [];
        var wins = OnixNiri.windows;
        for (var i = 0; i < wins.length; i++) {
            var e = OnixApps.findEntry(wins[i].app_id);
            if (e && e.id === entryId)
                out.push(wins[i]);
        }
        return out;
    }

    property int cycleIdx: 0

    function handleClick(entry): void {
        var wins = root.windowsFor(entry.id);
        if (wins.length === 0) {
            OnixApps.launchEntry(entry);
        } else if (wins.length === 1) {
            OnixNiri.focusWindowById(wins[0].id);
        } else {
            root.cycleIdx = (root.cycleIdx + 1) % wins.length;
            OnixNiri.focusWindowById(wins[root.cycleIdx].id);
        }
    }

    function isActive(entry): bool {
        var aw = OnixNiri.activeWindow;
        if (!aw)
            return false;
        var e = OnixApps.findEntry(aw.app_id);
        return e !== null && e.id === entry.id;
    }

    implicitWidth: root.vertical ? 40 : flow.implicitWidth + 10
    implicitHeight: root.vertical ? flow.implicitHeight + 10 : 40

    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: 4

        Repeater {
            model: {
                var items = [];
                var pins = OnixApps.pinned;
                for (var i = 0; i < pins.length; i++) {
                    var e = OnixApps.findEntry(pins[i]);
                    if (e)
                        items.push({ entry: e, open: root.windowsFor(e.id).length > 0 });
                }
                var open = root.openEntries();
                for (var j = 0; j < open.length; j++)
                    items.push({ entry: open[j], open: true });
                return items;
            }
            delegate: Item {
                required property var modelData
                implicitWidth: root.iconPx + 12
                implicitHeight: root.iconPx + 12

                Rectangle {
                    anchors.fill: parent
                    radius: OnixTheme.radiusFull
                    color: hover.containsMouse ? OnixTheme.mSurfaceContainerHighest : "transparent"

                    IconImage {
                        anchors.centerIn: parent
                        width: root.iconPx
                        height: root.iconPx
                        source: Quickshell.iconPath(modelData.entry.icon || "application-x-executable", "")
                    }

                    // running indicator dot (secondary when active)
                    Rectangle {
                        visible: modelData.open
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.vertical ? (parent.height - 4) : (parent.height - 5)
                        width: root.isActive(modelData.entry) ? 16 : 5
                        height: root.vertical ? (root.isActive(modelData.entry) ? 16 : 5) : 3
                        radius: 2
                        color: root.isActive(modelData.entry) ? OnixTheme.mSecondary : OnixTheme.mOnSurface
                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            if (OnixApps.isPinned(modelData.entry.id))
                                OnixApps.unpin(modelData.entry.id);
                            else
                                OnixApps.pin(modelData.entry.id);
                        } else {
                            root.handleClick(modelData.entry);
                        }
                    }
                }
            }
        }
    }
}
