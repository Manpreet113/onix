// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixMiscCat: shell/screen corner controls (ports upstream MiscCategory).
// Corner windows themselves land in P6; these settings already drive them.
import QtQuick

Column {
    id: root
    spacing: 0
    width: 800

    OnixCatLabel {
        icon: "more_horiz"
        title: "Miscellaneous"
    }

    OnixSetRow {
        title: "Rounded Shell Corners"
        description: "Add a curve outside the shell that warps around the screen."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["interface", "misc", "shell_corners"], true)
                onToggled: value => OnixSettings.set(["interface", "misc", "shell_corners"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Rounded Screen Corners"
        description: "Round the corners of the screen."
        control: Component {
            OnixSegmented {
                model: [
                    { label: "Disabled", icon: "close", value: "disabled" },
                    { label: "When not fullscreen", icon: "fullscreen_exit", value: "not_fullscreen" },
                    { label: "Always", icon: "check", value: "always" }
                ]
                current: OnixSettings.get(["interface", "misc", "screen_corners"], "not_fullscreen")
                onPicked: value => OnixSettings.set(["interface", "misc", "screen_corners"], value)
            }
        }
    }
}
