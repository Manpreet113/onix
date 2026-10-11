// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixLauncher: app launcher overlay (ports upstream Launcher). Grid / list
// layouts, pinned strip, live search with featured hit, usage-ranked
// results, right-click pin/action menu. Terminal apps spawn via ghostty.
// Toggle with `ipc call onixLauncher toggle` (Niri binds in P6) or the bar
// button; Esc or backdrop click closes.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    visible: OnixUi.launcherOpen
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(OnixTheme.mScrim.r, OnixTheme.mScrim.g, OnixTheme.mScrim.b, 0.6)

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/share/onix-shell"
    readonly property string layout: OnixSettings.get(["interface", "launcher", "layout"], "grid")

    property string query: ""
    property int selected: 0
    property var freq: ({})
    property bool shown: false

    onVisibleChanged: {
        if (visible) {
            root.query = "";
            root.selected = 0;
            searchField.text = "";
            root.shown = false;
            showTimer.restart();
            searchField.forceActiveFocus();
        }
    }

    Timer {
        id: showTimer
        interval: 30
        repeat: false
        onTriggered: root.shown = true
    }

    function close(): void {
        root.shown = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 160
        repeat: false
        onTriggered: OnixUi.launcherOpen = false
    }

    function haystack(e): string {
        var parts = [e.name, e.genericName, e.comment, e.execString, e.id];
        if (e.keywords)
            parts = parts.concat(e.keywords);
        if (e.categories)
            parts = parts.concat(e.categories);
        return parts.join(" ").toLowerCase();
    }

    function allEntries(): var {
        return DesktopEntries.applications.values;
    }

    function matches(): var {
        var q = root.query.trim().toLowerCase();
        var vals = root.allEntries();
        var out = [];
        for (var i = 0; i < vals.length; i++) {
            if (q.length === 0 || root.haystack(vals[i]).indexOf(q) >= 0)
                out.push(vals[i]);
        }
        out.sort(function (a, b) {
            var fa = root.freq[a.id] || 0;
            var fb = root.freq[b.id] || 0;
            if (fa !== fb)
                return fb - fa;
            var an = (a.name || "").toLowerCase();
            var bn = (b.name || "").toLowerCase();
            return an < bn ? -1 : (an > bn ? 1 : 0);
        });
        return out;
    }

    function pinnedEntries(): var {
        var out = [];
        var pins = OnixApps.pinned;
        for (var i = 0; i < pins.length; i++) {
            var e = OnixApps.findEntry(pins[i]);
            if (e)
                out.push(e);
        }
        return out;
    }

    function launchEntry(e): void {
        var f = root.freq;
        f[e.id] = (f[e.id] || 0) + 1;
        root.freq = f;
        statsSaver.setText(JSON.stringify(f));
        OnixApps.launchEntry(e);
        root.close();
    }

    function launchSelected(): void {
        var m = root.matches();
        if (m.length > 0) {
            var idx = Math.min(root.selected, m.length - 1);
            // first hit is featured, rest follow
            root.launchEntry(m[idx]);
        } else if (root.query.trim().length > 0) {
            Quickshell.execDetached(["sh", "-c", root.query.trim()]);
            root.close();
        }
    }

    function moveSelection(d): void {
        var n = root.matches().length;
        if (n === 0)
            return;
        root.selected = Math.min(n - 1, Math.max(0, root.selected + d));
    }

    function appMenu(anchor, entry): void {
        var items = [
            { label: entry.name || "", enabled: false },
            { separator: true },
            {
                label: OnixApps.isPinned(entry.id) ? "Unpin App" : "Pin App",
                fire: function () {
                    if (OnixApps.isPinned(entry.id))
                        OnixApps.unpin(entry.id);
                    else
                        OnixApps.pin(entry.id);
                }
            }
        ];
        var acts = entry.actions || [];
        if (acts.length > 0)
            items.push({ separator: true });
        for (var i = 0; i < acts.length; i++) {
            (function (a) {
                items.push({
                    label: a.name || "",
                    fire: function () {
                        try {
                            a.launch();
                        } catch (e) {
                            if (a.execute)
                                a.execute();
                        }
                        root.close();
                    }
                });
            })(acts[i]);
        }
        OnixMenu.open(anchor, items);
    }

    FileView {
        id: statsLoader
        path: root.stateDir + "/launcher-stats.json"
        printErrors: false
        blockLoading: true
        onLoaded: {
            try {
                var v = JSON.parse(statsLoader.text());
                if (v && typeof v === "object")
                    root.freq = v;
            } catch (e) {
            }
        }
    }
    FileView {
        id: statsSaver
        path: root.stateDir + "/launcher-stats.json"
        printErrors: false
    }

    IpcHandler {
        target: "onixLauncher"
        function toggle(): void {
            OnixUi.toggleLauncher();
        }
        function open(): void {
            OnixUi.launcherOpen = true;
        }
        function close(): void {
            root.close();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 600
        implicitHeight: Math.min(680, contentCol.implicitHeight + 24)
        color: OnixTheme.mSurfaceContainerLow
        radius: 28
        border.color: OnixTheme.mOutlineVariant
        border.width: 1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97
        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: contentCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 8

            // search bar
            Rectangle {
                width: parent.width
                implicitHeight: 52
                color: OnixTheme.mSurfaceContainerHigh
                radius: OnixTheme.radiusFull

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        color: OnixTheme.mOnSurfaceVariant
                        font.family: OnixTheme.iconFont
                        font.pixelSize: 22
                    }

                    TextField {
                        id: searchField
                        width: parent.width - 16 - 22 - 8 - clearBtn.width - layoutBtn.width - 16
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: "Search"
                        color: OnixTheme.mOnSurface
                        placeholderTextColor: OnixTheme.mOnSurfaceVariant
                        font.pixelSize: OnixTheme.fontLarge
                        background: null
                        onTextChanged: {
                            root.query = text;
                            root.selected = 0;
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.launchSelected();
                                event.accepted = true;
                            }
                        }
                    }

                    M3Button {
                        id: clearBtn
                        visible: root.query.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        btnType: "text"
                        size: "xs"
                        icon: "close"
                        onClicked: {
                            searchField.text = "";
                            searchField.forceActiveFocus();
                        }
                    }
                    M3Button {
                        id: layoutBtn
                        anchors.verticalCenter: parent.verticalCenter
                        btnType: "text"
                        size: "xs"
                        icon: root.layout === "grid" ? "view_list" : "grid_view"
                        onClicked: OnixSettings.set(["interface", "launcher", "layout"], root.layout === "grid" ? "list" : "grid")
                    }
                }
            }

            // pinned strip (idle state)
            Column {
                visible: root.query.trim().length === 0
                width: parent.width
                spacing: 8

                Grid {
                    visible: root.pinnedEntries().length > 0
                    width: parent.width
                    columns: 8
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: root.pinnedEntries()
                        delegate: Rectangle {
                            required property var modelData
                            implicitWidth: 64
                            implicitHeight: 64
                            color: pinHover.containsMouse ? OnixTheme.mSurfaceContainerHighest : "transparent"
                            radius: 16

                            IconImage {
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                source: Quickshell.iconPath(modelData.icon || "application-x-executable", "")
                            }
                            MouseArea {
                                id: pinHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton)
                                        root.appMenu(parent, modelData);
                                    else
                                        root.launchEntry(modelData);
                                }
                            }
                        }
                    }
                }

                Column {
                    visible: root.pinnedEntries().length === 0
                    width: parent.width
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "push_pin"
                        color: OnixTheme.mOnSurfaceVariant
                        font.family: OnixTheme.iconFont
                        font.pixelSize: 28
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Right click on an item to pin it."
                        color: OnixTheme.mOnSurfaceVariant
                        font.pixelSize: OnixTheme.fontSmall
                    }
                }
            }

            // results (searching)
            Flickable {
                visible: root.query.trim().length > 0
                width: parent.width
                height: Math.min(480, resultsFlow.implicitHeight)
                contentHeight: resultsFlow.implicitHeight
                clip: true

                Flow {
                    id: resultsFlow
                    width: parent.width
                    spacing: root.layout === "grid" ? 0 : 5

                    Repeater {
                        model: root.matches()
                        delegate: Item {
                            required property var modelData
                            required property int index
                            readonly property bool featured: index === 0

                            implicitWidth: root.layout === "grid" && !featured ? (resultsFlow.width / 5) : resultsFlow.width
                            implicitHeight: root.layout === "grid" ? (featured ? 50 : 100) : 50

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: root.layout === "grid" && !featured ? 0 : 2
                                color: root.selected === index ? OnixTheme.mSecondaryContainer : (cellHover.containsMouse ? OnixTheme.mSurfaceContainerHighest : "transparent")
                                radius: 16

                                Row {
                                    visible: featured || root.layout === "list"
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10
                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 32
                                        height: 32
                                        source: Quickshell.iconPath(modelData.icon || "application-x-executable", "")
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 56
                                        spacing: 0
                                        Text {
                                            width: parent.width
                                            text: modelData.name || ""
                                            color: root.selected === index ? OnixTheme.mOnSecondaryContainer : OnixTheme.mOnSurface
                                            font.pixelSize: OnixTheme.fontMed
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            visible: (modelData.comment || modelData.genericName || "") !== ""
                                            width: parent.width
                                            text: modelData.comment || modelData.genericName || ""
                                            color: OnixTheme.mOnSurfaceVariant
                                            font.pixelSize: OnixTheme.fontSmall
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Column {
                                    visible: root.layout === "grid" && !featured
                                    anchors.centerIn: parent
                                    spacing: 5
                                    width: parent.width - 8
                                    IconImage {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 32
                                        height: 32
                                        source: Quickshell.iconPath(modelData.icon || "application-x-executable", "")
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.name || ""
                                        color: root.selected === index ? OnixTheme.mOnSecondaryContainer : OnixTheme.mOnSurface
                                        font.pixelSize: OnixTheme.fontSmall
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: cellHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton)
                                            root.appMenu(parent, modelData);
                                        else
                                            root.launchEntry(modelData);
                                    }
                                    onPositionChanged: root.selected = index
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
