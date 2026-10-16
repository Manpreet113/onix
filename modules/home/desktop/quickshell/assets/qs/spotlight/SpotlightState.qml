pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Single source of truth for spotlight: query, ranked results, actions.
// Providers each return scored items; refresh() merges and caps at five.
Singleton {
    id: root

    property bool open: false
    property string query: ""
    property int sel: 0
    property var results: []

    onQueryChanged: refresh()

    function fuzzy(q: string, t: string): real {
        if (q.length === 0 || t.length === 0)
            return -1;
        var s = 0, run = 0, first = -1, qi = 0;
        for (var ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                if (first < 0)
                    first = ti;
                run++;
                s += 10 + run * 5 + ((ti === 0 || t[ti - 1] === " " || t[ti - 1] === "-" || t[ti - 1] === "_") ? 15 : 0);
                qi++;
            } else {
                run = 0;
            }
        }
        if (qi < q.length)
            return -1;
        return s - first;
    }

    function scoreTargets(q: string, targets: var): real {
        var best = -1;
        for (var i = 0; i < targets.length; i++) {
            var s = fuzzy(q, targets[i].toLowerCase());
            if (s > best)
                best = s;
        }
        return best;
    }

    function appItems(q: string): var {
        var out = [];
        var apps = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i];
            var s = scoreTargets(q, [e.name].concat(e.keywords));
            if (s < 0)
                continue;
            out.push({
                kind: "app",
                title: e.name,
                sub: e.genericName || e.comment || "",
                icon: e.icon ? Quickshell.iconPath(e.icon) : "",
                score: s,
                ref: e
            });
        }
        return out;
    }

    function calcItem(q: string): var {
        if (!/^[0-9+\-*/(). %\s]+$/.test(q) || !/[0-9]/.test(q))
            return [];
        try {
            var v = Function("return (" + q + ")")();
            if (typeof v !== "number" || !isFinite(v))
                return [];
            var t = String(Math.round(v * 1000000) / 1000000);
            return [{
                    kind: "calc",
                    title: "= " + t,
                    sub: "Calculate — Enter copies",
                    icon: Quickshell.iconPath("accessories-calculator", true),
                    score: 1e9,
                    ref: t
                }];
        } catch (e) {
            return [];
        }
    }

    function powerDefs(): var {
        return [
            { name: "Lock", keys: "lock screen sleep", exec: ["hyprlock"], icon: "system-lock-screen", glyph: "󰌾" },
            { name: "Log out", keys: "log out exit quit", lua: "hl.dsp.exit()", icon: "system-log-out", glyph: "󰗽" },
            { name: "Suspend", keys: "suspend sleep", exec: ["systemctl", "suspend"], icon: "system-suspend", glyph: "󰤄" },
            { name: "Reboot", keys: "reboot restart", exec: ["systemctl", "reboot"], icon: "system-reboot", glyph: "󰜉", confirm: true },
            { name: "Shut down", keys: "shut down power off halt", exec: ["systemctl", "poweroff"], icon: "system-shutdown", glyph: "⏻", confirm: true }
        ];
    }

    function powerActions(): var {
        var defs = powerDefs();
        for (var i = 0; i < defs.length; i++)
            defs[i].icon = Quickshell.iconPath(defs[i].icon, true);
        return defs;
    }

    function powerItems(q: string): var {
        var defs = powerDefs();
        var out = [];
        for (var i = 0; i < defs.length; i++) {
            var s = scoreTargets(q, [defs[i].name.toLowerCase()].concat(defs[i].keys.split(" ")));
            if (s < 0)
                continue;
            out.push({
                kind: "power",
                title: defs[i].name,
                sub: "System",
                icon: Quickshell.iconPath(defs[i].icon, true),
                score: s + 100,
                ref: defs[i].exec,
                lua: defs[i].lua || ""
            });
        }
        return out;
    }

    function windowItems(q: string): var {
        var out = [];
        var tops = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (var i = 0; i < tops.length; i++) {
            var t = tops[i];
            var cls = (t.lastIpcObject && t.lastIpcObject.class) || "";
            var s = scoreTargets(q, [t.title.toLowerCase(), cls.toLowerCase()]);
            if (s < 0)
                continue;
            var a = t.address || "";
            if (a.length > 0 && !a.startsWith("0x"))
                a = "0x" + a;
            out.push({
                kind: "window",
                title: t.title || cls,
                sub: cls || "Window",
                icon: Quickshell.iconPath(cls, true),
                score: s + 50,
                ref: a
            });
        }
        return out;
    }

    function refresh(): void {
        var q = query.trim().toLowerCase();
        if (q.length === 0) {
            results = [];
            sel = 0;
            return;
        }
        var out = calcItem(q).concat(appItems(q), windowItems(q), powerItems(q));
        out.sort((a, b) => b.score - a.score);
        results = out.slice(0, 5);
        sel = 0;
    }

    function move(d: int): void {
        if (results.length === 0 || !open)
            return;
        sel = (((sel + d) % results.length) + results.length) % results.length;
    }

    function runItem(item: var): void {
        if (!item)
            return;
        if (item.kind === "app")
            item.ref.execute();
        else if (item.kind === "calc")
            Quickshell.clipboardText = item.ref;
        else if (item.kind === "power") {
            if (item.lua)
                Hyprland.dispatch(item.lua);
            else
                Quickshell.execDetached(item.ref);
        } else if (item.kind === "window" && item.ref.length > 0) {
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + item.ref + "\" })");
        }
    }

    function runSel(): void {
        if (sel >= 0 && sel < results.length)
            runItem(results[sel]);
    }
}
