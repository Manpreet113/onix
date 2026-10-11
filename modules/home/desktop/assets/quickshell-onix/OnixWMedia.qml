// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWMedia: now-playing pill (ports upstream Media). Shows every MPRIS
// player; only the last carries title/artist labels (hidden entirely on
// dense or vertical bars, tooltip-style). Click toggles play/pause;
// hovering a playing pill reveals the pause overlay.
import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets

Item {
    id: root

    property int barId: 0

    readonly property string barSec: root.barId === 0 ? "bar" : "bar2"
    readonly property bool vertical: OnixSettings.get(["interface", root.barSec, "vertical"], false)
    readonly property int density: OnixSettings.get(["interface", root.barSec, "density"], 0)
    readonly property bool centered: OnixSettings.get(["interface", root.barSec, "centered"], false)

    readonly property var players: Mpris.players.values
    visible: root.players.length > 0

    implicitWidth: root.vertical ? 40 : (root.centered ? 150 : cols.implicitWidth + 10)
    implicitHeight: root.vertical ? cols.implicitHeight + 10 : 40

    Column {
        id: cols
        anchors.centerIn: parent
        spacing: root.vertical ? 8 : 4

        Repeater {
            model: root.players
            delegate: Item {
                required property var modelData
                required property int index

                readonly property bool showLabels: index === root.players.length - 1 && !root.vertical && root.density === 0
                readonly property int artPx: root.density > 0 ? 16 : 24

                implicitWidth: row.implicitWidth + 10
                implicitHeight: 32

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 5

                    Item {
                        width: artPx
                        height: artPx
                        anchors.verticalCenter: parent.verticalCenter

                        IconImage {
                            anchors.fill: parent
                            source: modelData.trackArtUrl || ""
                            visible: (modelData.trackArtUrl || "") !== ""
                        }
                        Text {
                            anchors.fill: parent
                            visible: (modelData.trackArtUrl || "") === ""
                            text: "music_note"
                            color: OnixTheme.mOnSurfaceVariant
                            font.family: OnixTheme.iconFont
                            font.pixelSize: artPx
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            visible: overlayMouse.containsMouse || !modelData.isPlaying
                            anchors.fill: parent
                            radius: 20
                            color: "#80000000"
                            opacity: overlayMouse.containsMouse ? 1 : 0.8
                            Text {
                                anchors.centerIn: parent
                                text: modelData.isPlaying ? "pause" : "play_arrow"
                                color: "white"
                                font.family: OnixTheme.iconFont
                                font.pixelSize: artPx
                            }
                        }

                        MouseArea {
                            id: overlayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.canTogglePlaying)
                                    modelData.isPlaying = !modelData.isPlaying;
                            }
                        }

                        RotationAnimation on rotation {
                            running: modelData.isPlaying && (modelData.trackArtUrl || "") !== ""
                            loops: Animation.Infinite
                            duration: 10000
                            from: 0
                            to: 360
                        }
                    }

                    Column {
                        visible: showLabels
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        Text {
                            text: modelData.trackTitle || "Unknown"
                            color: OnixTheme.mOnSurface
                            font.pixelSize: OnixTheme.fontMed
                            font.bold: true
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 160)
                        }
                        Text {
                            text: modelData.trackArtist || ""
                            color: OnixTheme.mOnSurfaceVariant
                            font.pixelSize: OnixTheme.fontSmall
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 160)
                        }
                    }
                }
            }
        }
    }
}
