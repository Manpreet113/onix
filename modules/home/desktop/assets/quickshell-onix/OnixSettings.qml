// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// Onix shell runtime settings. Schema mirrors the upstream settings model
// (appearance / interface / services) so every ported view behaves 1:1, but
// persistence is a plain JSON file under ~/.local/share/onix-shell — Nix
// ships onix-settings.defaults.json as the seed and never manages the live
// file. The settings window (P5) mutates this live; nothing needs a rebuild.
//
// KEEP IN SYNC: `defaults` below must match onix-settings.defaults.json.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/share/onix-shell"
    readonly property string statePath: stateDir + "/onix-settings.json"

    property var settings: ({})
    // True once load() has run (file present or not). The loader's onLoaded
    // may never fire when the state file doesn't exist yet — onCompleted
    // below seeds defaults in that case. Either order converges.
    property bool hydrated: false

    // Full default tree (mirrors the upstream user-settings schema).
    readonly property var defaults: ({
        appearance: {
            wallcolors: {
                wallpaper_path: "",
                quickselect_path: "",
                color_scheme: "tonal_spot",
                dark_mode: true,
                auto_dark: {
                    enabled: false,
                    start_hour: 22,
                    start_min: 0,
                    end_hour: 6,
                    end_min: 0
                }
            }
        },
        interface: {
            modules: {
                location: {
                    launcher: 0,
                    window_info: 0,
                    media: 0,
                    workspaces: 1,
                    tasks: 1,
                    recording_indicator: 2,
                    systeminfotray: 2,
                    clock: 2
                },
                visibility: {
                    launcher: false,
                    window_info: true,
                    media: true,
                    workspaces: true,
                    tasks: false,
                    recording_indicator: true,
                    systeminfotray: true,
                    clock: true
                },
                bar_id: {
                    launcher: 0,
                    window_info: 0,
                    media: 0,
                    workspaces: 0,
                    tasks: 0,
                    recording_indicator: 0,
                    systeminfotray: 0,
                    clock: 0
                },
                options: {
                    show_date: true,
                    day_month_swapped: false,
                    military_time: false,
                    recording_indicator: "recording",
                    workspaces_style: "numbers",
                    fixed_workspaces_enabled: true,
                    fixed_workspaces_amount: 5
                }
            },
            bar: {
                side: "bottom",
                vertical: false,
                density: 0,
                floating: false,
                separation: false,
                centered: false,
                bar_background: true,
                module_backgrounds: true
            },
            bar2: {
                enabled: true,
                side: "top",
                vertical: false,
                density: 0,
                floating: false,
                separation: false,
                centered: false,
                bar_background: true,
                module_backgrounds: true
            },
            notifications: {
                anchor: ["top", "right"],
                compact_popup: false
            },
            launcher: {
                layout: "grid"
            },
            misc: {
                shell_corners: true,
                screen_corners: "not_fullscreen"
            }
        },
        services: {
            recorder: {
                start_notification: true,
                stop_notification: true,
                record_audio: true
            },
            osd: {
                anchor: ["bottom", "right"],
                vertical: false
            }
        }
    })

    // Recursive object merge (arrays replaced wholesale, like upstream).
    function merge(base, over) {
        var out = {};
        for (var k in base)
            out[k] = base[k];
        if (over === undefined || over === null)
            return out;
        for (var j in over) {
            var bv = base[j];
            var ov = over[j];
            if (ov !== null && typeof ov === "object" && !Array.isArray(ov)
                && bv !== null && typeof bv === "object" && !Array.isArray(bv))
                out[j] = merge(bv, ov);
            else
                out[j] = ov;
        }
        return out;
    }

    // Read helper: get(["interface","bar","side"]) with optional fallback.
    function get(path, fallback) {
        var cur = root.settings;
        for (var i = 0; i < path.length; i++) {
            if (cur === undefined || cur === null)
                return fallback;
            cur = cur[path[i]];
        }
        return cur === undefined ? fallback : cur;
    }

    // Write helper: set(["interface","bar","floating"], true) + persist.
    function set(path, value) {
        var next = merge(root.defaults, root.settings);
        var cur = next;
        for (var i = 0; i < path.length - 1; i++)
            cur = cur[path[i]];
        cur[path[path.length - 1]] = value;
        root.settings = next;
        root.save();
    }

    function load(): void {
        var parsed = null;
        try {
            var t = settingsLoader.text().trim();
            parsed = t.length > 0 ? JSON.parse(t) : null;
        } catch (e) {
            parsed = null;
        }
        root.settings = merge(root.defaults, parsed);
        root.hydrated = true;
    }

    function save(): void {
        settingsSaver.setText(JSON.stringify(root.settings, null, 2) + "\n");
    }

    property FileView settingsSaver: FileView {
        path: root.statePath
        printErrors: false
    }

    property FileView settingsLoader: FileView {
        path: root.statePath
        printErrors: false
        blockLoading: true
        onLoaded: root.load()
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.stateDir]);
        if (!root.hydrated)
            root.load();
    }
}
