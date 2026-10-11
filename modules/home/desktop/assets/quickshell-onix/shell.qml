// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// Onix shell entry point (Niri session). Singletons (OnixTheme, OnixSettings,
// OnixNiri) self-register; views instantiate below as they land per phase.
// The smoke panel below showcases the P1 primitives (M3Button types, M3Slider,
// M3NavRail) plus theme/settings/Niri status — it is removed when the OnixBar
// lands in P2.
import QtQuick
import Quickshell

Scope {
    id: root

    // Touch singletons so load failures surface immediately in the log.
    property var theme: OnixTheme
    property var prefs: OnixSettings
    property var niri: OnixNiri

    OnixOsd {
    }

    OnixNotifs {
    }

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
        implicitWidth: 420
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
                text: "ONIX · P1 primitives"
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

            Row {
                spacing: 6
                M3Button {
                    btnType: "filled"
                    size: "s"
                    icon: "check"
                    label: "Filled"
                }
                M3Button {
                    btnType: "tonal"
                    size: "s"
                    label: "Tonal"
                }
                M3Button {
                    btnType: "outlined"
                    size: "s"
                    label: "Lined"
                }
                M3Button {
                    btnType: "text"
                    size: "s"
                    icon: "close"
                }
            }

            M3Slider {
                icon: "volume_up"
                from: 0
                to: 100
                value: 60
                width: parent.width
            }

            Row {
                spacing: 6
                M3NavRail {
                    property int demo: 0
                    items: [
                        { icon: "home", label: "Home" },
                        { icon: "settings", label: "Set" }
                    ]
                    current: demo
                    onSelected: index => demo = index
                }
                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "niri: " + (OnixNiri.available ? OnixNiri.socketPath : "unavailable (expected off-Niri)")
                        color: OnixTheme.mOnSurfaceVariant
                        font.family: OnixTheme.fontFamily
                        font.pixelSize: OnixTheme.fontSmall
                        elide: Text.ElideRight
                        width: 280
                    }
                    Text {
                        text: "theme: " + (Object.keys(OnixTheme.data).length > 0 ? "skein live" : "Nord fallback")
                        color: OnixTheme.mOnSurfaceVariant
                        font.family: OnixTheme.fontFamily
                        font.pixelSize: OnixTheme.fontSmall
                    }
                    Text {
                        text: "settings: " + Object.keys(OnixSettings.settings).join(", ")
                        color: OnixTheme.mOnSurfaceVariant
                        font.family: OnixTheme.fontFamily
                        font.pixelSize: OnixTheme.fontSmall
                        wrapMode: Text.Wrap
                        width: 280
                    }
                }
            }
        }
    }
}
