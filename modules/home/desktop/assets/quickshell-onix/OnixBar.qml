// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixBar: dual-bar engine (ports upstream Bar + BarStyles). One instance
// per barId (0 = bar, 1 = bar2), rendered on every monitor. Side, vertical,
// density, floating, separation, centering, and both backgrounds are pure
// settings bindings — no imperative restyling. Modules route to zones by
// location / visibility / bar_id, in upstream's canonical order.
import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property int barId: 0

    readonly property string sec: root.barId === 0 ? "bar" : "bar2"
    function opt(name, fallback) {
        return OnixSettings.get(["interface", root.sec, name], fallback);
    }
    readonly property string side: root.opt("side", root.barId === 0 ? "bottom" : "top")
    readonly property bool vertical: root.opt("vertical", false)
    readonly property int density: root.opt("density", 0)
    readonly property bool floating: root.opt("floating", false)
    readonly property bool separation: root.opt("separation", false)
    readonly property bool centered: root.opt("centered", false)
    readonly property bool barBg: root.opt("bar_background", true)
    readonly property bool modBg: root.opt("module_backgrounds", true)
    readonly property bool enabled: root.barId === 0 ? true : root.opt("enabled", true)

    readonly property int barSize: [40, 35, 30, 25][Math.min(3, Math.max(0, root.density))]
    readonly property int zonePad: [5, 2, 2, 0][Math.min(3, Math.max(0, root.density))]

    readonly property var order: ["launcher", "window_info", "media", "workspaces", "tasks", "recording_indicator", "systeminfotray", "clock"]

    function zoneNames(zone): var {
        var out = [];
        for (var i = 0; i < root.order.length; i++) {
            var n = root.order[i];
            var loc = OnixSettings.get(["interface", "modules", "location", n], 1);
            var bid = OnixSettings.get(["interface", "modules", "bar_id", n], 0);
            var vis = OnixSettings.get(["interface", "modules", "visibility", n], true);
            if (loc === zone && bid === root.barId && vis)
                out.push(n);
        }
        return out;
    }

    readonly property bool anyVisible: root.zoneNames(0).length + root.zoneNames(1).length + root.zoneNames(2).length > 0

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            visible: root.enabled && root.anyVisible
            focusable: false

            anchors {
                top: root.centered ? root.side === "top" : (root.vertical ? true : root.side === "top")
                bottom: root.centered ? root.side === "bottom" : (root.vertical ? true : root.side === "bottom")
                left: root.centered ? root.side === "left" : (root.vertical ? root.side === "left" : true)
                right: root.centered ? root.side === "right" : (root.vertical ? root.side === "right" : true)
            }
            margins {
                top: root.floating ? (root.side === "top" ? 0 : 5) : 0
                bottom: root.floating ? (root.side === "bottom" ? 0 : 5) : 0
                left: root.floating ? (root.side === "left" ? 0 : 5) : 0
                right: root.floating ? (root.side === "right" ? 0 : 5) : 0
            }
            implicitWidth: root.vertical ? root.barSize : 0
            implicitHeight: root.vertical ? 0 : root.barSize
            color: "transparent"

            Rectangle {
                id: barBgRect
                anchors.fill: parent
                color: {
                    if (!root.barBg)
                        return "transparent";
                    if (root.separation)
                        return "transparent";
                    return OnixTheme.mSurface;
                }
                radius: {
                    if (root.floating)
                        return OnixTheme.radiusFull;
                    if (!root.centered)
                        return 0;
                    return 20;
                }
                // shell corners: a hugging uncentered bar rounds its two
                // outer (desktop-facing) corners, like upstream bar corners
                readonly property bool shellRound: !root.floating && !root.centered && root.barBg && !root.separation && OnixSettings.get(["interface", "misc", "shell_corners"], true)
                topLeftRadius: (root.side === "bottom" || root.side === "right") && shellRound ? 20 : radius
                topRightRadius: (root.side === "bottom" || root.side === "left") && shellRound ? 20 : radius
                bottomLeftRadius: (root.side === "top" || root.side === "right") && shellRound ? 20 : radius
                bottomRightRadius: (root.side === "top" || root.side === "left") && shellRound ? 20 : radius
                border.color: (root.floating && root.barBg && !root.separation) ? Qt.rgba(OnixTheme.mOutlineVariant.r, OnixTheme.mOutlineVariant.g, OnixTheme.mOutlineVariant.b, 0.5) : "transparent"
                border.width: (root.floating && root.barBg && !root.separation) ? 1 : 0

                Row {
                    id: hZones
                    visible: !root.vertical
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: 3
                        delegate: Item {
                            required property int index
                            readonly property int zone: index
                            readonly property var names: root.zoneNames(zone)

                            width: zone === 1 ? parent.width - hZones.children[0].width - hZones.children[2].width : implicitWidth
                            height: parent.height
                            visible: names.length > 0
                            implicitWidth: zoneRow.implicitWidth + (zone === 0 && !root.centered ? 16 : 0) + (zone === 2 && !root.centered ? 16 : 0)

                            Rectangle {
                                id: zoneBg
                                anchors.fill: parent
                                anchors.leftMargin: (zone === 0 && !root.centered) ? 16 : 0
                                anchors.rightMargin: (zone === 2 && !root.centered) ? 16 : 0
                                visible: root.separation && root.barBg && names.length > 0
                                color: OnixTheme.bg
                                radius: root.floating ? OnixTheme.radiusFull : 0
                                topLeftRadius: radius
                                topRightRadius: radius
                                bottomLeftRadius: radius
                                bottomRightRadius: radius
                                border.color: root.floating ? Qt.rgba(OnixTheme.mOutlineVariant.r, OnixTheme.mOutlineVariant.g, OnixTheme.mOutlineVariant.b, 0.5) : "transparent"
                                border.width: root.floating ? 1 : 0
                            }

                            Row {
                                id: zoneRow
                                anchors {
                                    left: zone === 0 ? parent.left : undefined
                                    leftMargin: (zone === 0 && !root.centered) ? 16 : root.zonePad
                                    right: zone === 2 ? parent.right : undefined
                                    rightMargin: (zone === 2 && !root.centered) ? 16 : root.zonePad
                                    horizontalCenter: zone === 1 ? parent.horizontalCenter : undefined
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 2

                                Repeater {
                                    model: names
                                    delegate: Rectangle {
                                        required property string modelData
                                        required property int index
                                        readonly property int count: names.length
                                        readonly property string edge: count === 1 ? "only" : (index === 0 ? "first" : (index === count - 1 ? "last" : ""))

                                        implicitWidth: widgetLoader.implicitWidth
                                        implicitHeight: widgetLoader.item ? widgetLoader.item.implicitHeight : 0
                                        color: root.modBg ? OnixTheme.mSurfaceContainer : "transparent"
                                        radius: root.modBg ? 5 : 15
                                        topLeftRadius: (root.modBg && (edge === "first" || edge === "only")) ? 20 : radius
                                        bottomLeftRadius: (root.modBg && (edge === "first" || edge === "only")) ? 20 : radius
                                        topRightRadius: (root.modBg && (edge === "last" || edge === "only")) ? 20 : radius
                                        bottomRightRadius: (root.modBg && (edge === "last" || edge === "only")) ? 20 : radius

                                        Loader {
                                            id: widgetLoader
                                            anchors.centerIn: parent
                                            height: parent.height
                                            sourceComponent: root.widgetFor(modelData)
                                            onLoaded: {
                                                if (item && item.hasOwnProperty("barId"))
                                                    item.barId = root.barId;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    id: vZones
                    visible: root.vertical
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: 3
                        delegate: Item {
                            required property int index
                            readonly property int zone: index
                            readonly property var names: root.zoneNames(zone)

                            height: zone === 1 ? parent.height - vZones.children[0].height - vZones.children[2].height : implicitHeight
                            width: parent.width
                            visible: names.length > 0
                            implicitHeight: zoneCol.implicitHeight + (zone === 0 && !root.centered ? 16 : 0) + (zone === 2 && !root.centered ? 16 : 0)

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: (zone === 0 && !root.centered) ? 16 : 0
                                anchors.bottomMargin: (zone === 2 && !root.centered) ? 16 : 0
                                visible: root.separation && root.barBg && names.length > 0
                                color: OnixTheme.bg
                                radius: root.floating ? OnixTheme.radiusFull : 0
                                border.color: root.floating ? Qt.rgba(OnixTheme.mOutlineVariant.r, OnixTheme.mOutlineVariant.g, OnixTheme.mOutlineVariant.b, 0.5) : "transparent"
                                border.width: root.floating ? 1 : 0
                            }

                            Column {
                                id: zoneCol
                                anchors {
                                    top: zone === 0 ? parent.top : undefined
                                    topMargin: (zone === 0 && !root.centered) ? 16 : root.zonePad
                                    bottom: zone === 2 ? parent.bottom : undefined
                                    bottomMargin: (zone === 2 && !root.centered) ? 16 : root.zonePad
                                    verticalCenter: zone === 1 ? parent.verticalCenter : undefined
                                    horizontalCenter: parent.horizontalCenter
                                }
                                spacing: 2

                                Repeater {
                                    model: names
                                    delegate: Rectangle {
                                        required property string modelData
                                        required property int index
                                        readonly property int count: names.length
                                        readonly property string edge: count === 1 ? "only" : (index === 0 ? "first" : (index === count - 1 ? "last" : ""))

                                        implicitHeight: widgetLoaderV.item ? widgetLoaderV.item.implicitHeight : 0
                                        implicitWidth: parent.width
                                        color: root.modBg ? OnixTheme.mSurfaceContainer : "transparent"
                                        radius: root.modBg ? 5 : 15

                                        Loader {
                                            id: widgetLoaderV
                                            anchors.centerIn: parent
                                            width: parent.width
                                            sourceComponent: root.widgetFor(modelData)
                                            onLoaded: {
                                                if (item && item.hasOwnProperty("barId"))
                                                    item.barId = root.barId;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // (widget components live at root scope; see below)
        }
    }

    Component {
        id: wLauncher
        OnixWLauncher {
        }
    }
    Component {
        id: wWindowInfo
        OnixWWindowInfo {
        }
    }
    Component {
        id: wMedia
        OnixWMedia {
        }
    }
    Component {
        id: wWorkspaces
        OnixWWorkspaces {
        }
    }
    Component {
        id: wTasks
        OnixWTasks {
        }
    }
    Component {
        id: wRecIndicator
        OnixWRecIndicator {
        }
    }
    Component {
        id: wSysTray
        OnixWSysTray {
        }
    }
    Component {
        id: wClock
        OnixWClock {
        }
    }

    function widgetFor(name): Component {
        switch (name) {
        case "launcher":
            return wLauncher;
        case "window_info":
            return wWindowInfo;
        case "media":
            return wMedia;
        case "workspaces":
            return wWorkspaces;
        case "tasks":
            return wTasks;
        case "recording_indicator":
            return wRecIndicator;
        case "systeminfotray":
            return wSysTray;
        case "clock":
            return wClock;
        default:
            return null;
        }
    }
}
