import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// App launcher content for the Overlay host.
// Apps come live from .desktop files via DesktopEntries — nothing is
// hardcoded. Type to filter, up/down to move, enter to launch. If the
// query matches nothing, enter runs it as a shell command.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property string query: ""
    property int selected: 0
    property var freq: ({})

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/share/onix-shell"

    function focusView(): void {
        searchInput.forceActiveFocus();
    }

    function onShown(): void {
        searchInput.text = "";
        root.query = "";
        root.selected = 0;
    }

    function haystack(e: var): string {
        var parts = [e.name, e.genericName, e.comment, e.execString, e.id];
        if (e.keywords)
            parts = parts.concat(e.keywords);
        if (e.categories)
            parts = parts.concat(e.categories);
        return parts.join(" ").toLowerCase();
    }

    function filtered(): var {
        var vals = DesktopEntries.applications.values;
        var q = root.query.trim().toLowerCase();
        var out = [];
        for (var i = 0; i < vals.length; i++) {
            var e = vals[i];
            if (q.length === 0 || haystack(e).indexOf(q) >= 0)
                out.push(e);
        }
        out.sort(function (a, b) {
            var fa = root.freq[a.id] || 0;
            var fb = root.freq[b.id] || 0;
            if (fa !== fb)
                return fb - fa;
            return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1;
        });
        return out;
    }

    function moveSelection(d: int): void {
        var n = filtered().length;
        if (n === 0)
            return;
        root.selected = Math.min(n - 1, Math.max(0, root.selected + d));
        list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    function launchEntry(e: var): void {
        var f = root.freq;
        f[e.id] = (f[e.id] || 0) + 1;
        root.freq = f;
        statsSaver.setText(JSON.stringify(f));
        if (e.runInTerminal)
            Quickshell.execDetached({
                command: ["ghostty", "-e"].concat(e.command),
                workingDirectory: e.workingDirectory
            });
        else
            e.execute();
        root.requestClose();
    }

    function launchSelected(): void {
        var m = filtered();
        if (root.selected >= 0 && root.selected < m.length) {
            launchEntry(m[root.selected]);
        } else if (root.query.trim().length > 0) {
            Quickshell.execDetached(["sh", "-c", root.query.trim()]);
            root.requestClose();
        }
    }

    onQueryChanged: {
        root.selected = 0;
    }

    // usage counts: most-launched floats to the top
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
                console.log("launcher: failed to parse stats", e);
            }
        }
    }
    FileView {
        id: statsSaver
        path: root.stateDir + "/launcher-stats.json"
        printErrors: false
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.stateDir]);
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Item {
            id: searchBox
            width: parent.width
            implicitHeight: 44

            Rectangle {
                anchors.fill: parent
                color: Theme.surface
                radius: Theme.radiusMed
                border.color: Theme.primary
                border.width: 1
            }

            Text {
                id: promptGlyph
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "❯"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
            }

            TextInput {
                id: searchInput
                anchors.left: promptGlyph.right
                anchors.right: escHint.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                selectByMouse: true
                onTextChanged: root.query = text
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onReturnPressed: root.launchSelected()
                Keys.onEnterPressed: root.launchSelected()
                Text {
                    anchors.fill: parent
                    text: "type to launch…"
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLarge
                    visible: searchInput.text.length === 0
                }
            }

            Rectangle {
                id: escHint
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 34
                implicitHeight: 24
                radius: Theme.radiusSmall
                color: Theme.bg
                border.color: Theme.border
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "esc"
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - searchBox.implicitHeight - hint.implicitHeight - 24
            clip: true
            spacing: 6
            model: root.filtered()
            currentIndex: root.selected

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: list.width
                implicitHeight: 56
                color: index === root.selected ? Theme.bg : Theme.surface
                radius: Theme.radiusSmall
                border.color: index === root.selected ? Theme.primary : Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 9
                        color: index === root.selected ? Theme.primary : Theme.bg
                        border.color: Theme.border
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 22
                            source: "image://icon/" + (modelData.icon || "application-x-executable")
                            asynchronous: true
                        }
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            width: parent.width
                            text: modelData.name || modelData.id
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMed
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: modelData.genericName || modelData.comment || ""
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selected = index
                    onClicked: {
                        root.selected = index;
                        root.launchSelected();
                    }
                }
            }
        }

        Text {
            id: hint
            anchors.horizontalCenter: parent.horizontalCenter
            text: list.count === 0 && root.query.trim().length > 0 ? "no match — enter runs it as a command · esc close" : "type to filter · ↑↓ move · enter launch · esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
