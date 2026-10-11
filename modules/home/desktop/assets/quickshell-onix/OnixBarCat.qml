// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixBarCat: bar position / density / modifiers / backgrounds editor
// (ports upstream BarCategory; barId 1 variant covers Bar2Category — the
// explanatory note only renders for the second bar).
import QtQuick

Column {
    id: root

    property int barId: 0

    readonly property string sec: root.barId === 0 ? "bar" : "bar2"
    function opt(name, fallback) {
        return OnixSettings.get(["interface", root.sec, name], fallback);
    }
    function setOpt(name, value): void {
        OnixSettings.set(["interface", root.sec, name], value);
    }
    function setSide(side): void {
        root.setOpt("side", side);
        root.setOpt("vertical", side === "left" || side === "right");
    }

    spacing: 0
    width: 800

    OnixCatLabel {
        icon: root.barId === 0 ? "toolbar" : "bottom_navigation"
        title: root.barId === 0 ? "Bar" : "Second Bar"
    }

    Text {
        visible: root.barId === 1
        width: parent.width
        text: "The second bar will be automatically enabled if any modules are located in it.\nIt will automatically be disabled if there are no modules located in it."
        color: OnixTheme.mOnSurfaceVariant
        font.pixelSize: OnixTheme.fontSmall
        wrapMode: Text.WordWrap
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Position"
        description: "Pick a side for the bar to be located."
        control: Component {
            OnixSegmented {
                model: [
                    { label: "Top", icon: "align_vertical_top", value: "top" },
                    { label: "Bottom", icon: "align_vertical_bottom", value: "bottom" },
                    { label: "Left", icon: "align_horizontal_left", value: "left" },
                    { label: "Right", icon: "align_horizontal_right", value: "right" }
                ]
                current: root.opt("side", root.barId === 0 ? "bottom" : "top")
                onPicked: value => root.setSide(value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Density"
        description: "Pick between 4 different density options."
        control: Component {
            OnixSegmented {
                model: [
                    { label: "Cozy", icon: "density_large", value: 0 },
                    { label: "Comfortable", icon: "density_medium", value: 1 },
                    { label: "Compact", icon: "density_small", value: 2 },
                    { label: "Condensed", icon: "list", value: 3 }
                ]
                current: root.opt("density", 0)
                onPicked: value => root.setOpt("density", value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Extra Modifiers"
        description: "Add extra modifiers to the bar (You can select multiple)."
        control: Component {
            OnixSegmented {
                multi: true
                model: [
                    { label: "Floating", icon: "page_header", value: "floating" },
                    { label: "Separated", icon: "more_horiz", value: "separation" },
                    { label: "Centered", icon: "code", value: "centered" }
                ]
                current: {
                    var on = [];
                    if (root.opt("floating", false))
                        on.push("floating");
                    if (root.opt("separation", false))
                        on.push("separation");
                    if (root.opt("centered", false))
                        on.push("centered");
                    return on;
                }
                onPicked: value => root.setOpt(value, !root.opt(value, false))
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Backgrounds"
        description: "Add or remove the backgrounds of the Bar/Modules."
        control: Component {
            OnixSegmented {
                multi: true
                model: [
                    { label: "Bar", icon: "toolbar", value: "bar_background" },
                    { label: "Modules", icon: "more_horiz", value: "module_backgrounds" }
                ]
                current: {
                    var on = [];
                    if (root.opt("bar_background", true))
                        on.push("bar_background");
                    if (root.opt("module_backgrounds", true))
                        on.push("module_backgrounds");
                    return on;
                }
                onPicked: value => root.setOpt(value, !root.opt(value, true))
            }
        }
    }
}
