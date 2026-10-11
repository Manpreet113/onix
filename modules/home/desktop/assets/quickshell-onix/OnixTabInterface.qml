// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixTabInterface: bar editors, per-module routing, extra options, misc
// (ports upstream InterfaceTab).
import QtQuick

Column {
    id: root
    spacing: 8
    width: 800

    readonly property var modules: [
        { name: "Launcher", widget: "launcher", description: "Button to open the Launcher." },
        { name: "Window Info", widget: "window_info", description: "Shows information about the active window." },
        { name: "Media", widget: "media", description: "Shows the currently playing media with controls." },
        { name: "Workspaces", widget: "workspaces", description: "Shows a list of workspaces." },
        { name: "Tasks", widget: "tasks", description: "Shows pinned and currently running applications." },
        { name: "Recording Indicator", widget: "recording_indicator", description: "Shows the current recording status." },
        { name: "System Tray", widget: "systeminfotray", description: "Shows system tray icons." },
        { name: "Clock", widget: "clock", description: "Shows the current time and date." }
    ]

    OnixBarCat {
        barId: 0
    }

    OnixBarCat {
        barId: 1
    }

    OnixCatLabel {
        icon: "dashboard_2"
        title: "Bar Modules"
    }

    Repeater {
        model: root.modules
        delegate: Column {
            required property var modelData
            width: 800
            spacing: 0

            OnixSetRow {
                title: modelData.name + " Widget"
                description: modelData.description
                control: Component {
                    Row {
                        spacing: 8
                        OnixSegmented {
                            model: [
                                { label: "", icon: "timer_1", value: 0 },
                                { label: "", icon: "timer_2", value: 1 }
                            ]
                            current: OnixSettings.get(["interface", "modules", "bar_id", modelData.widget], 0)
                            onPicked: value => OnixSettings.set(["interface", "modules", "bar_id", modelData.widget], value)
                        }
                        OnixSegmented {
                            model: [
                                { label: "Start", value: 0 },
                                { label: "Center", value: 1 },
                                { label: "End", value: 2 }
                            ]
                            current: OnixSettings.get(["interface", "modules", "location", modelData.widget], 1)
                            onPicked: value => OnixSettings.set(["interface", "modules", "location", modelData.widget], value)
                        }
                        OnixSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: OnixSettings.get(["interface", "modules", "visibility", modelData.widget], true)
                            onToggled: value => OnixSettings.set(["interface", "modules", "visibility", modelData.widget], value)
                        }
                    }
                }
            }

            OnixSep {
                visible: index < root.modules.length - 1
            }
        }
    }

    OnixCatLabel {
        icon: "settings"
        title: "Extra Module Options"
    }

    OnixSetRow {
        title: "Workspace Indicator Style"
        description: "Pick between 3 different Workspace Indicator styles."
        control: Component {
            OnixSegmented {
                model: [
                    { label: "Icons", icon: "photo", value: "windows" },
                    { label: "Numbers", icon: "counter_1", value: "numbers" },
                    { label: "Dots", icon: "more_horiz", value: "dots" }
                ]
                current: OnixSettings.get(["interface", "modules", "options", "workspaces_style"], "numbers")
                onPicked: value => OnixSettings.set(["interface", "modules", "options", "workspaces_style"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Fixed Workspaces"
        description: "Show a specific amount of workspaces"
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["interface", "modules", "options", "fixed_workspaces_enabled"], true)
                onToggled: value => OnixSettings.set(["interface", "modules", "options", "fixed_workspaces_enabled"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Fixed Workspaces Amount"
        description: "How many workspaces to show."
        control: Component {
            OnixSpin {
                min: 1
                max: 20
                value: OnixSettings.get(["interface", "modules", "options", "fixed_workspaces_amount"], 5)
                onChanged: value => OnixSettings.set(["interface", "modules", "options", "fixed_workspaces_amount"], Math.round(value))
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Use 24 hour time"
        description: "Toggle between 12-hour (AM/PM) and 24-hour time formats."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["interface", "modules", "options", "military_time"], false)
                onToggled: value => OnixSettings.set(["interface", "modules", "options", "military_time"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Show the date"
        description: "Toggle the visibility of the date in the bar."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["interface", "modules", "options", "show_date"], true)
                onToggled: value => OnixSettings.set(["interface", "modules", "options", "show_date"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Swap the day and month"
        description: "Use the American date format."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["interface", "modules", "options", "day_month_swapped"], false)
                onToggled: value => OnixSettings.set(["interface", "modules", "options", "day_month_swapped"], value)
            }
        }
    }

    OnixMiscCat {
    }
}
