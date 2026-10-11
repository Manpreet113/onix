// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// Onix shell entry point (Niri session). Singletons (OnixTheme, OnixSettings,
// OnixNiri) self-register; views instantiate below as they land per phase.
// The P0 smoke panel below proves theme + settings + Niri-guard load and
// render — it is removed when the OnixBar lands in P2.
import QtQuick
import Quickshell

Scope {
    id: root

    // Touch singletons so load failures surface immediately in the log.
    property var theme: OnixTheme
    property var prefs: OnixSettings
    property var niri: OnixNiri

    PanelWindow {
        id: smoke
        anchors {
            left: true
            bottom: true
        }
        margins {
            left: 16
            bottom: 16
        }
        implicitWidth: 340
        implicitHeight: col.implicitHeight + 24

        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: OnixTheme.mSurfaceContainerLow
            radius: OnixTheme.radiusMed
            border.color: OnixTheme.mOutlineVariant
            border.width: 1
        }

        Column {
            id: col
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 8

            Text {
                text: "ONIX · P0 scaffold"
                color: OnixTheme.mOnSurface
                font.family: OnixTheme.fontFamily
                font.pixelSize: OnixTheme.fontTitle
                font.bold: true
            }

            Row {
                spacing: 6
                Repeater {
                    model: [
                        { c: OnixTheme.mPrimary, n: "prim" },
                        { c: OnixTheme.mSecondary, n: "sec" },
                        { c: OnixTheme.mSurfaceContainerHigh, n: "cont" },
                        { c: OnixTheme.mError, n: "err" },
                        { c: OnixTheme.mTertiary, n: "ok" },
                        { c: OnixTheme.mOutline, n: "line" }
                    ]
                    delegate: Column {
                        spacing: 2
                        required property var modelData
                        Rectangle {
                            width: 30
                            height: 30
                            radius: OnixTheme.radiusSmall
                            color: modelData.c
                            border.color: OnixTheme.mOutlineVariant
                            border.width: 1
                        }
                        Text {
                            text: modelData.n
                            color: OnixTheme.mOnSurfaceVariant
                            font.family: OnixTheme.fontFamily
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            Text {
                text: "niri: " + (OnixNiri.available ? OnixNiri.socketPath : "unavailable (expected off-Niri)")
                color: OnixTheme.mOnSurfaceVariant
                font.family: OnixTheme.fontFamily
                font.pixelSize: OnixTheme.fontSmall
                elide: Text.ElideRight
                width: col.width
            }
            Text {
                text: "theme: " + (Object.keys(OnixTheme.data).length > 0 ? "skein live" : "Nord fallback")
                color: OnixTheme.mOnSurfaceVariant
                font.family: OnixTheme.fontFamily
                font.pixelSize: OnixTheme.fontSmall
            }
            Text {
                text: "settings sections: " + Object.keys(OnixSettings.settings).join(", ")
                color: OnixTheme.mOnSurfaceVariant
                font.family: OnixTheme.fontFamily
                font.pixelSize: OnixTheme.fontSmall
                wrapMode: Text.Wrap
                width: col.width
            }
        }
    }
}
