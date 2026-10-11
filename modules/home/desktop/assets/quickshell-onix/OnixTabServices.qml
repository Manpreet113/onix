// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixTabServices: notifications, recording, and OSD service settings
// (ports upstream ServicesTab).
import QtQuick
import Quickshell

Column {
    id: root
    spacing: 8
    width: 800

    OnixCatLabel {
        icon: "notifications"
        title: "Notifications"
    }

    OnixSetRow {
        title: "Do Not Disturb"
        description: "When enabled, will stop popups for new notifications."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["interface", "notifications", "dnd"], false)
                onToggled: value => OnixSettings.set(["interface", "notifications", "dnd"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Popup Timeout"
        description: "How long (in seconds) should a notification popup stay on screen."
        control: Component {
            OnixSpin {
                min: 1
                max: 60
                value: OnixSettings.get(["interface", "notifications", "popup_timeout"], 5)
                onChanged: value => OnixSettings.set(["interface", "notifications", "popup_timeout"], Math.round(value))
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Max Popups"
        description: "How many popup notifications can be shown at once."
        control: Component {
            OnixSpin {
                min: 1
                max: 20
                value: OnixSettings.get(["interface", "notifications", "max_popups"], 5)
                onChanged: value => OnixSettings.set(["interface", "notifications", "max_popups"], Math.round(value))
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Popup Location"
        description: "Pick a location for your notification popups."
        control: Component {
            OnixSegmented {
                model: [
                    { label: "", icon: "north_west", value: ["top", "left"] },
                    { label: "Top", icon: "north", value: ["top"] },
                    { label: "", icon: "north_east", value: ["top", "right"] },
                    { label: "", icon: "south_west", value: ["bottom", "left"] },
                    { label: "Bottom", icon: "south", value: ["bottom"] },
                    { label: "", icon: "south_east", value: ["bottom", "right"] }
                ]
                current: OnixSettings.get(["interface", "notifications", "anchor"], ["top", "right"])
                onPicked: value => OnixSettings.set(["interface", "notifications", "anchor"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Compact Pop-up"
        description: "Show a more compact pop-up for incoming notifications."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["interface", "notifications", "compact_popup"], false)
                onToggled: value => OnixSettings.set(["interface", "notifications", "compact_popup"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Send a Test Notification"
        control: Component {
            M3Button {
                btnType: "tonal"
                size: "xs"
                icon: "notifications_unread"
                label: "Test Notification"
                onClicked: Quickshell.execDetached(["notify-send", "Test Notification", "This is a test notification!", "-a", "Onix Settings"])
            }
        }
    }

    OnixCatLabel {
        icon: "screen_record"
        title: "Recording"
    }

    OnixSetRow {
        title: "Notifications"
        description: "When should the recorder send a notification."
        control: Component {
            OnixSegmented {
                multi: true
                model: [
                    { label: "Started", icon: "play_arrow", value: "start_notification" },
                    { label: "Stopped", icon: "stop", value: "stop_notification" }
                ]
                current: {
                    var on = [];
                    if (OnixSettings.get(["services", "recorder", "start_notification"], true))
                        on.push("start_notification");
                    if (OnixSettings.get(["services", "recorder", "stop_notification"], true))
                        on.push("stop_notification");
                    return on;
                }
                onPicked: value => OnixSettings.set(["services", "recorder", value], !OnixSettings.get(["services", "recorder", value], true))
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Record Audio"
        description: "Record the systems audio when recording."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["services", "recorder", "record_audio"], true)
                onToggled: value => OnixSettings.set(["services", "recorder", "record_audio"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Recording Indicator"
        description: "When to show the recording indicator in the bar."
        control: Component {
            OnixSegmented {
                model: [
                    { label: "Always", icon: "visibility", value: "always" },
                    { label: "When Recording", icon: "screen_record", value: "recording" }
                ]
                current: OnixSettings.get(["interface", "modules", "options", "recording_indicator"], "recording")
                onPicked: value => OnixSettings.set(["interface", "modules", "options", "recording_indicator"], value)
            }
        }
    }

    OnixCatLabel {
        icon: "toast"
        title: "OSD"
    }

    OnixSetRow {
        title: "Popup Location"
        description: "Pick a location for your OSD popups."
        control: Component {
            OnixSegmented {
                model: [
                    { label: "", icon: "north_west", value: ["top", "left"] },
                    { label: "Top", icon: "north", value: ["top"] },
                    { label: "", icon: "north_east", value: ["top", "right"] },
                    { label: "", icon: "west", value: ["left"] },
                    { label: "", icon: "east", value: ["right"] },
                    { label: "", icon: "south_west", value: ["bottom", "left"] },
                    { label: "Bottom", icon: "south", value: ["bottom"] },
                    { label: "", icon: "south_east", value: ["bottom", "right"] }
                ]
                current: OnixSettings.get(["services", "osd", "anchor"], ["bottom", "right"])
                onPicked: value => OnixSettings.set(["services", "osd", "anchor"], value)
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Vertical"
        description: "Use a vertical OSD. Only takes effect when located in corners."
        control: Component {
            OnixSwitch {
                checked: OnixSettings.get(["services", "osd", "vertical"], false)
                onToggled: value => OnixSettings.set(["services", "osd", "vertical"], value)
            }
        }
    }
}
