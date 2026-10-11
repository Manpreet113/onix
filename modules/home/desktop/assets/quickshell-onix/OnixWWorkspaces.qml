// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWWorkspaces: Niri workspace switcher (ports upstream Workspaces,
// Niri branch). Styles: numbers / windows (app icons per workspace) / dots.
// Fixed-workspace paging renders a stable slot window with dimmed dummies;
// without Niri the slots render dimmed until the compositor appears.
// Click focuses, scroll moves focus down/up.
import QtQuick
import Quickshell.Widgets

Item {
    id: root

    property int barId: 0

    readonly property string barSec: root.barId === 0 ? "bar" : "bar2"
    readonly property bool vertical: OnixSettings.get(["interface", root.barSec, "vertical"], false)
    readonly property string style: OnixSettings.get(["interface", "modules", "options", "workspaces_style"], "numbers")
    readonly property bool fixedEnabled: OnixSettings.get(["interface", "modules", "options", "fixed_workspaces_enabled"], true)
    readonly property int fixedAmount: OnixSettings.get(["interface", "modules", "options", "fixed_workspaces_amount"], 5)

    function windowsOn(wsId): var {
        var out = [];
        var wins = OnixNiri.windows;
        for (var i = 0; i < wins.length; i++) {
            if (wins[i].workspace_id === wsId)
                out.push(wins[i]);
        }
        return out;
    }

    function buildSlots(): var {
        var byIdx = {};
        var wins = OnixNiri.windows;
        var wss = OnixNiri.workspaces;
        var activeIdx = -1;
        for (var i = 0; i < wss.length; i++) {
            byIdx[wss[i].idx] = wss[i];
            if (wss[i].is_active)
                activeIdx = wss[i].idx;
        }
        var slots = [];
        function pushSlot(ws, idx) {
            var id = ws ? ws.id : -idx;
            slots.push({
                ws: ws,
                idx: idx,
                id: id,
                active: ws ? !!ws.is_active : false,
                empty: root.windowsOn(id).length === 0
            });
        }
        if (root.fixedEnabled && root.fixedAmount > 0) {
            var start = 1;
            if (activeIdx > 0) {
                if (root.fixedAmount === 1)
                    start = activeIdx;
                else
                    start = Math.floor((activeIdx - 1) / root.fixedAmount) * root.fixedAmount + 1;
            }
            for (var k = start; k < start + root.fixedAmount; k++)
                pushSlot(byIdx[k] || null, k);
        } else {
            var idxs = Object.keys(byIdx).map(function (x) {
                return parseInt(x, 10);
            }).sort(function (a, b) {
                return a - b;
            });
            for (var j = 0; j < idxs.length; j++)
                pushSlot(byIdx[idxs[j]], idxs[j]);
        }
        return slots;
    }

    property var slots: root.buildSlots()

    implicitWidth: root.vertical ? 40 : flow.implicitWidth + 4
    implicitHeight: root.vertical ? flow.implicitHeight + 4 : 32

    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: root.style === "windows" ? 2 : 5

        Repeater {
            model: root.slots
            delegate: Rectangle {
                required property var modelData

                readonly property bool isDots: root.style === "dots"
                readonly property bool showIcons: root.style === "windows"

                implicitWidth: {
                    if (isDots)
                        return modelData.active ? 20 : 6;
                    if (showIcons)
                        return Math.max(25, iconRow.implicitWidth + 20);
                    return modelData.active ? 45 : 25;
                }
                implicitHeight: {
                    if (isDots)
                        return modelData.active ? 10 : 6;
                    return 25;
                }
                color: {
                    if (isDots)
                        return modelData.active ? OnixTheme.mOnSurface : Qt.rgba(OnixTheme.mOnSurface.r, OnixTheme.mOnSurface.g, OnixTheme.mOnSurface.b, 0.5);
                    if (modelData.active)
                        return OnixTheme.mPrimary;
                    return hover.containsMouse ? OnixTheme.mSurfaceContainerHighest : "transparent";
                }
                radius: 20
                opacity: (!isDots && modelData.empty && !modelData.active) ? 0.5 : 1

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutExpo
                    }
                }

                Text {
                    visible: !isDots && !showIcons
                    anchors.centerIn: parent
                    text: modelData.idx.toString()
                    color: modelData.active ? OnixTheme.mOnPrimary : OnixTheme.mOnSurface
                    font.pixelSize: OnixTheme.fontMed
                    font.bold: modelData.active
                    opacity: (!modelData.ws) ? 0.5 : 1
                }

                Row {
                    id: iconRow
                    visible: showIcons
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.idx.toString()
                        color: modelData.active ? OnixTheme.mOnPrimary : OnixTheme.mOnSurface
                        font.pixelSize: OnixTheme.fontSmall
                    }
                    Repeater {
                        model: root.windowsOn(modelData.id)
                        delegate: IconImage {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            source: Quickshell.iconPath(OnixApps.iconFor(modelData.app_id, modelData.title), "")
                        }
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.ws)
                            OnixNiri.focusWorkspaceById(modelData.ws.id);
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y < 0)
                OnixNiri.focusWorkspaceDown();
            else if (wheel.angleDelta.y > 0)
                OnixNiri.focusWorkspaceUp();
        }
    }
}
