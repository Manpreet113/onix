// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixSchemeRow: color-scheme selector (ports the palette selector rows).
// Eight Material scheme names for schema parity; swatches are tonal blocks
// from the live theme (matugen's per-scheme previews don't exist here —
// the stored name maps to the closest skein scheme in OnixWallpaper).
// `columns` switches the grid shape (quick tab 3, appearance tab row).
import QtQuick

Grid {
    id: root

    property int cols: 3

    readonly property var schemes: ["content", "expressive", "fidelity", "fruit-salad", "monochrome", "neutral", "rainbow", "tonal-spot"]
    readonly property string current: OnixSettings.get(["appearance", "wallcolors", "color_scheme"], "tonal-spot")

    columns: root.cols
    columnSpacing: 5
    rowSpacing: 5

    Repeater {
        model: root.schemes
        delegate: Rectangle {
            required property string modelData
            readonly property bool isCurrent: modelData === root.current

            implicitWidth: 64
            implicitHeight: 64
            radius: 16
            color: "transparent"
            border.color: isCurrent ? OnixTheme.mPrimary : OnixTheme.mOutlineVariant
            border.width: isCurrent ? 2 : 1

            Column {
                anchors.centerIn: parent
                spacing: 0
                Rectangle {
                    width: 50
                    height: 25
                    topLeftRadius: 10
                    topRightRadius: 10
                    color: OnixTheme.mPrimary
                }
                Row {
                    spacing: 0
                    Rectangle {
                        width: 25
                        height: 25
                        bottomLeftRadius: 10
                        color: OnixTheme.mSecondaryContainer
                    }
                    Rectangle {
                        width: 25
                        height: 25
                        bottomRightRadius: 10
                        color: OnixTheme.mTertiaryContainer
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: OnixWallpaper.setColors(modelData)
            }
        }
    }
}
