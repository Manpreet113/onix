// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixTabQuick: condensed overview tab (ports upstream QuickTab) —
// wallpaper + theme previews + scheme grid beside it, then the bar editor
// and misc corners.
import QtQuick

Column {
    id: root
    spacing: 8
    width: 800

    OnixCatLabel {
        icon: "palette"
        title: "Appearance"
    }

    Row {
        width: parent.width
        spacing: 10

        OnixWallCat {
            title: ""
            width: 540
        }

        Column {
            width: 250
            spacing: 10

            OnixThemePreviews {
                width: parent.width
            }

            OnixSchemeRow {
                cols: 3
                width: parent.width
            }
        }
    }

    OnixBarCat {
        barId: 0
    }

    OnixMiscCat {
    }
}
