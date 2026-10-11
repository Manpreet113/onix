// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixCorners: rounded screen corners (ports upstream Corners, screen
// branch). Four small overlay windows per screen paint the corner pixels
// black outside the curve — the standard rounded-display effect. Size
// follows the bar density when floating, like upstream; layer is overlay
// for "always", top otherwise. "not_fullscreen" hides them while any Niri
// window reports fullscreen (best effort: unverified field, falls back to
// always showing).
//
// Shell corners (rounding the bar's own screen-edge junctions) need no
// overlay here: OnixBar rounds its outer corners directly when the bar
// hugs uncentered and shell_corners is set.
import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    readonly property string mode: OnixSettings.get(["interface", "misc", "screen_corners"], "not_fullscreen")
    readonly property int density: OnixSettings.get(["interface", "bar", "density"], 0)
    readonly property bool floating: OnixSettings.get(["interface", "bar", "floating"], false)
    readonly property bool centered: OnixSettings.get(["interface", "bar", "centered"], false)
    readonly property int size: (root.floating && !root.centered) ? [25, 22, 20, 17][Math.min(3, Math.max(0, root.density))] : 25

    readonly property bool anyFullscreen: {
        var wins = OnixNiri.windows;
        for (var i = 0; i < wins.length; i++) {
            if (wins[i].is_fullscreen === true)
                return true;
        }
        return false;
    }

    readonly property bool shown: root.mode !== "disabled" && !(root.mode === "not_fullscreen" && root.anyFullscreen)

    Variants {
        model: Quickshell.screens
        delegate: Item {
            required property var modelData
            property var screenData: modelData

            Repeater {
                model: [
                    { top: true, left: true },
                    { top: true, left: false },
                    { top: false, left: true },
                    { top: false, left: false }
                ]
                delegate: PanelWindow {
                    required property var modelData
                    screen: screenData

                    visible: root.shown
                    focusable: false
                    anchors {
                        top: modelData.top
                        bottom: !modelData.top
                        left: modelData.left
                        right: !modelData.left
                    }
                    implicitWidth: root.size
                    implicitHeight: root.size
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: root.mode === "always" ? WlrLayer.Overlay : WlrLayer.Top
                    color: "transparent"

                    Canvas {
                        id: cornerCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            var s = root.size;
                            ctx.clearRect(0, 0, s, s);
                            ctx.fillStyle = "black";
                            ctx.fillRect(0, 0, s, s);
                            ctx.globalCompositeOperation = "destination-out";
                            ctx.beginPath();
                            var cx = modelData.left ? s : 0;
                            var cy = modelData.top ? s : 0;
                            ctx.arc(cx, cy, s, 0, Math.PI * 2);
                            ctx.fill();
                        }
                        Component.onCompleted: cornerCanvas.requestPaint()
                    }

                    Connections {
                        target: root
                        function onSizeChanged() {
                            cornerCanvas.requestPaint();
                        }
                    }
                }
            }
        }
    }
}
