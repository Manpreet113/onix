pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Single source of truth for Spotlight Command Palette: query, modes, ranked results, actions.
Singleton {
    id: root

    property bool open: false
    property string query: ""
    property string mode: "all" // "all" | "clipboard" | "notifications" | "windows" | "apps"
    property int sel: 0
    property var results: []

    onQueryChanged: refresh()
    onModeChanged: refresh()

    Connections {
        target: Clip
        function onHistoryChanged() {
            if (root.open && (root.mode === "clipboard" || root.mode === "all"))
                root.refresh();
        }
    }

    Connections {
        target: Notif
        function onHistoryChanged() {
            if (root.open && (root.mode === "notifications" || root.mode === "all"))
                root.refresh();
        }
    }

    function openWithMode(m: string): void {
        mode = m;
        query = "";
        sel = 0;
        open = true;
        refresh();
    }

    function setMode(m: string): void {
        mode = m;
        sel = 0;
        refresh();
    }

    function fuzzy(q: string, t: string): real {
        if (!q || !t || q.length === 0 || t.length === 0)
            return -1;
        var s = 0, run = 0, first = -1, qi = 0;
        for (var ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                if (first < 0)
                    first = ti;
                run++;
                s += 12 + run * 6 + ((ti === 0 || t[ti - 1] === " " || t[ti - 1] === "-" || t[ti - 1] === "_") ? 18 : 0);
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
        if (!targets || !Array.isArray(targets))
            return -1;
        var best = -1;
        for (var i = 0; i < targets.length; i++) {
            var item = targets[i];
            if (!item || typeof item !== "string")
                continue;
            var s = fuzzy(q, item.toLowerCase());
            if (s > best)
                best = s;
        }
        return best;
    }

    // 1. Math calculation engine
    function calcItem(q: string): var {
        var clean = q.trim();
        if (!/^[0-9+\-*/(). ,%^\s]+$/.test(clean) && !clean.toLowerCase().startsWith("sqrt") && !clean.toLowerCase().startsWith("sin") && !clean.toLowerCase().startsWith("cos"))
            return [];
        if (!/[0-9]/.test(clean))
            return [];

        try {
            var expr = clean.replace(/\^/g, "**")
                            .replace(/pi/gi, "Math.PI")
                            .replace(/sqrt\(/gi, "Math.sqrt(")
                            .replace(/sin\(/gi, "Math.sin(")
                            .replace(/cos\(/gi, "Math.cos(");
            var v = Function("return (" + expr + ")")();
            if (typeof v !== "number" || !isFinite(v) || isNaN(v))
                return [];
            var t = String(Math.round(v * 1000000) / 1000000);
            return [{
                kind: "calc",
                category: "CALCULATOR",
                title: t,
                sub: clean + " = " + t + " (Press Enter to copy)",
                icon: "calculate",
                score: 1e9,
                ref: t
            }];
        } catch (e) {
            return [];
        }
    }

    // 2. Applications launcher
    function appItems(q: string): var {
        var out = [];
        var apps = DesktopEntries.applications?.values ?? [];
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i];
            if (!e || !e.name)
                continue;

            var targets = [e.name];
            if (e.genericName) targets.push(e.genericName);
            if (e.comment) targets.push(e.comment);
            if (e.categories && Array.isArray(e.categories)) {
                for (var c = 0; c < e.categories.length; c++) targets.push(e.categories[c]);
            }
            if (e.keywords && Array.isArray(e.keywords)) {
                for (var k = 0; k < e.keywords.length; k++) targets.push(e.keywords[k]);
            }

            var s = q.length > 0 ? scoreTargets(q, targets) : 10;
            if (q.length > 0 && s < 0)
                continue;

            out.push({
                kind: "app",
                category: "APPLICATION",
                title: e.name,
                sub: e.genericName || e.comment || "Application",
                icon: e.icon || "application-x-executable",
                score: s + (root.mode === "apps" ? 100 : 50),
                ref: e
            });
        }
        return out;
    }

    // 3. Running Hyprland Windows switcher
    function windowItems(q: string): var {
        var out = [];
        var tops = Hyprland.toplevels?.values ?? [];
        for (var i = 0; i < tops.length; i++) {
            var t = tops[i];
            if (!t)
                continue;
            var title = t.title || "";
            var cls = (t.lastIpcObject && t.lastIpcObject.class) || "";
            var s = q.length > 0 ? scoreTargets(q, [title, cls]) : 20;
            if (q.length > 0 && s < 0)
                continue;
            var a = t.address || "";
            if (a.length > 0 && !a.startsWith("0x"))
                a = "0x" + a;

            out.push({
                kind: "window",
                category: "ACTIVE WINDOW",
                title: title.length > 0 ? title : cls,
                sub: `Switch to Window • ${cls || "Hyprland"}`,
                icon: cls.toLowerCase() || "window",
                score: s + (root.mode === "windows" ? 100 : 40),
                ref: a
            });
        }
        return out;
    }

    // 4. Power & System actions
    function powerDefs(): var {
        return [
            { name: "Lock Screen", keys: "lock screen sleep hyprlock quickshell", exec: ["quickshell", "ipc", "-c", "onix", "call", "lock", "lock"], icon: "lock", action: "Lock" },
            { name: "Suspend / Sleep", keys: "suspend sleep standby", exec: ["systemctl", "suspend"], icon: "bedtime", action: "Suspend" },
            { name: "Reload Quickshell", keys: "reload refresh restart quickshell qs", exec: ["pkill", "-USR1", "quickshell"], icon: "restart_alt", action: "Reload" },
            { name: "Log Out", keys: "log out exit quit session", lua: "hl.dsp.exit()", icon: "logout", action: "Exit" },
            { name: "Restart Computer", keys: "reboot restart boot system", exec: ["systemctl", "reboot"], icon: "refresh", action: "Reboot" },
            { name: "Power Off", keys: "power off shutdown turn off halt", exec: ["systemctl", "poweroff"], icon: "power_settings_new", action: "Shutdown" }
        ];
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
                category: "SYSTEM ACTION",
                title: defs[i].name,
                sub: "System Command • " + defs[i].action,
                icon: defs[i].icon,
                isMaterialIcon: true,
                score: s + 30,
                ref: defs[i].exec,
                lua: defs[i].lua || ""
            });
        }
        return out;
    }

    // 5. Command Runner ("> command" or "$ command")
    function commandItem(q: string): var {
        var trimmed = q.trim();
        if (trimmed.startsWith(">") || trimmed.startsWith("$")) {
            var cmd = trimmed.slice(1).trim();
            if (cmd.length > 0) {
                return [{
                    kind: "command",
                    category: "COMMAND RUNNER",
                    title: cmd,
                    sub: "Run in terminal (Ghostty) • Press Enter",
                    icon: "terminal",
                    isMaterialIcon: true,
                    score: 999999,
                    ref: cmd
                }];
            }
        }
        return [];
    }

    // 6. Clipboard History Items
    function clipItems(q: string): var {
        var out = [];
        var clips = Clip.history || [];
        for (var i = 0; i < clips.length; i++) {
            var it = clips[i];
            if (!it)
                continue;
            var isImg = it.type === "image";
            var s = 50;
            if (q.length > 0) {
                if (isImg) {
                    s = scoreTargets(q, ["image", "png", "jpg", "screenshot", "clip", it.preview || ""]);
                } else {
                    s = fuzzy(q, (it.text || "").toLowerCase());
                }
                if (s < 0)
                    continue;
            } else {
                s = 100 - i;
            }

            out.push({
                kind: "clip",
                category: isImg ? "CLIPBOARD IMAGE" : "CLIPBOARD TEXT",
                title: isImg ? (it.preview || "Image") : it.preview,
                sub: isImg ? `${it.mime || "image/png"} • ${it.timeStr}` : `${it.charCount} chars • ${it.lineCount} line${it.lineCount > 1 ? "s" : ""} • ${it.timeStr}`,
                icon: isImg ? "image" : "content_copy",
                isMaterialIcon: true,
                isImageClip: isImg,
                imagePath: isImg ? it.filePath : "",
                score: s + (root.mode === "clipboard" ? 100 : 25),
                ref: it,
                id: it.id,
                rawItem: it
            });
            if (root.mode === "all" && out.length >= 2)
                break;
        }
        return out;
    }

    // 7. Notification History Items
    function notifItems(q: string): var {
        var out = [];
        var notifs = Notif.history || [];
        for (var i = 0; i < notifs.length; i++) {
            var it = notifs[i];
            if (!it)
                continue;
            var s = 40;
            if (q.length > 0) {
                s = scoreTargets(q, [(it.appName || "").toLowerCase(), (it.summary || "").toLowerCase(), (it.body || "").toLowerCase()]);
                if (s < 0)
                    continue;
            } else {
                s = 90 - i;
            }

            out.push({
                kind: "notif",
                category: (it.appName || "NOTIFICATION").toUpperCase(),
                title: it.summary || it.appName || "Notification",
                sub: (it.body ? (it.body + " • ") : "") + it.timeStr,
                icon: it.appIcon || "notifications",
                isMaterialIcon: !it.appIcon,
                score: s + (root.mode === "notifications" ? 100 : 20),
                ref: it,
                id: it.id,
                rawItem: it
            });
            if (root.mode === "all" && out.length >= 2)
                break;
        }
        return out;
    }

    // 8. Default / Empty State Suggestions
    function defaultItems(): var {
        var out = [];

        // In specific modes, empty query shows all items in that category
        if (root.mode === "clipboard") {
            return clipItems("");
        }
        if (root.mode === "notifications") {
            return notifItems("");
        }
        if (root.mode === "windows") {
            return windowItems("");
        }
        if (root.mode === "apps") {
            var appsList = appItems("");
            appsList.sort((a, b) => a.title.localeCompare(b.title));
            return appsList;
        }

        // Mode == "all": Curated top suggestions
        var apps = DesktopEntries.applications?.values ?? [];
        var priority = ["Ghostty", "Firefox", "Zen Browser", "Visual Studio Code", "VSCodium", "Nautilus", "Files", "Spotify", "BitChord"];
        for (var p = 0; p < priority.length; p++) {
            for (var a = 0; a < apps.length; a++) {
                var app = apps[a];
                if (app && app.name && app.name.toLowerCase().includes(priority[p].toLowerCase())) {
                    out.push({
                        kind: "app",
                        category: "SUGGESTED APP",
                        title: app.name,
                        sub: app.genericName || app.comment || "Application",
                        icon: app.icon || "application-x-executable",
                        score: 100 - p,
                        ref: app
                    });
                    break;
                }
            }
            if (out.length >= 3) break;
        }

        // Include latest clipboard entry if available
        var latestClip = clipItems("");
        if (latestClip.length > 0) {
            out.push(latestClip[0]);
        }

        // Include latest notification entry if available
        var latestNotif = notifItems("");
        if (latestNotif.length > 0) {
            out.push(latestNotif[0]);
        }

        // Add key system actions
        var defs = powerDefs();
        out.push({
            kind: "power",
            category: "SYSTEM ACTION",
            title: defs[0].name,
            sub: "Quick Action • " + defs[0].action,
            icon: defs[0].icon,
            isMaterialIcon: true,
            score: 50,
            ref: defs[0].exec,
            lua: defs[0].lua || ""
        });
        out.push({
            kind: "power",
            category: "SYSTEM ACTION",
            title: defs[1].name,
            sub: "Quick Action • " + defs[1].action,
            icon: defs[1].icon,
            isMaterialIcon: true,
            score: 49,
            ref: defs[1].exec,
            lua: defs[1].lua || ""
        });

        return out;
    }

    function refresh(): void {
        var q = query.trim().toLowerCase();

        if (root.mode === "clipboard") {
            var cOut = clipItems(q);
            cOut.sort((a, b) => b.score - a.score);
            results = cOut.slice(0, 10);
            sel = 0;
            return;
        }

        if (root.mode === "notifications") {
            var nOut = notifItems(q);
            nOut.sort((a, b) => b.score - a.score);
            results = nOut.slice(0, 10);
            sel = 0;
            return;
        }

        if (root.mode === "windows") {
            var wOut = windowItems(q);
            wOut.sort((a, b) => b.score - a.score);
            results = wOut.slice(0, 10);
            sel = 0;
            return;
        }

        if (root.mode === "apps") {
            var aOut = appItems(q);
            aOut.sort((a, b) => b.score - a.score);
            results = aOut.slice(0, 10);
            sel = 0;
            return;
        }

        // Prefix triggers
        if (q.startsWith("clip:") || q.startsWith("c ")) {
            var cq = q.replace(/^(clip:|c\s+)/i, "").trim();
            var resC = clipItems(cq);
            resC.sort((a, b) => b.score - a.score);
            results = resC.slice(0, 8);
            sel = 0;
            return;
        }

        if (q.startsWith("notif:") || q.startsWith("n ")) {
            var nq = q.replace(/^(notif:|n\s+)/i, "").trim();
            var resN = notifItems(nq);
            resN.sort((a, b) => b.score - a.score);
            results = resN.slice(0, 8);
            sel = 0;
            return;
        }

        if (q.length === 0) {
            results = defaultItems();
            sel = 0;
            return;
        }

        var out = calcItem(q).concat(commandItem(q), appItems(q), windowItems(q), powerItems(q), clipItems(q), notifItems(q));
        out.sort((a, b) => b.score - a.score);
        results = out.slice(0, 8);
        sel = 0;
    }

    function move(d: int): void {
        if (!results || results.length === 0 || !open)
            return;
        sel = (((sel + d) % results.length) + results.length) % results.length;
    }

    function runItem(item: var): void {
        if (!item)
            return;
        if (item.kind === "clip") {
            Clip.copy(item.ref);
            open = false;
        } else if (item.kind === "notif") {
            if (item.ref && item.ref.notificationRef && item.ref.notificationRef.actions && item.ref.notificationRef.actions.length > 0) {
                try {
                    item.ref.notificationRef.actions[0].invoke();
                } catch (e) {}
            }
            Notif.dismissHistory(item.id);
            open = false;
        } else if (item.kind === "app") {
            item.ref.execute();
            open = false;
        } else if (item.kind === "calc") {
            Clip.copy(String(item.ref));
            open = false;
        } else if (item.kind === "power") {
            if (item.lua) {
                Hyprland.dispatch(item.lua);
            } else if (item.ref && item.ref.length > 0) {
                Quickshell.execDetached(item.ref);
            }
            open = false;
        } else if (item.kind === "window" && item.ref && item.ref.length > 0) {
            const usingLua = Hyprland.usingLua;
            Hyprland.dispatch(usingLua ? `hl.dsp.focus({ window = "address:${item.ref}" })` : `focuswindow address:${item.ref}`);
            open = false;
        } else if (item.kind === "command") {
            Quickshell.execDetached(["ghostty", "-e", "bash", "-c", item.ref + "; exec bash"]);
            open = false;
        }
    }

    function deleteSel(): void {
        if (sel < 0 || sel >= results.length)
            return;
        var item = results[sel];
        if (item.kind === "clip") {
            Clip.remove(item.id);
            refresh();
        } else if (item.kind === "notif") {
            Notif.dismissHistory(item.id);
            refresh();
        }
    }

    function runSel(): void {
        if (sel >= 0 && sel < results.length)
            runItem(results[sel]);
    }
}
