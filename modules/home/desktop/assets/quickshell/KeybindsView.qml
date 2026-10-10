import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Keybind cheatsheet content for the Overlay host.
// Driven by ~/.config/quickshell/keybinds.json (generated from binds.nix).
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property string query: ""
    property var doc: ({groups: [], submaps: []})

    function focusView(): void {
        searchBox.forceActiveFocus();
    }

    function runAction(run: string): void {
        var m = run.match(/exec_cmd\("(.+)"\)/);
        if (m)
            Quickshell.execDetached(["sh", "-c", m[1]]);
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/keybinds.json"
        watchChanges: true
        onFileChanged: reload()
        blockLoading: true
        onLoaded: {
            try {
                root.doc = JSON.parse(text());
            } catch (e) {
                console.log("keybinds: failed to parse", e);
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 12

        TextInput {
            id: searchBox
            width: parent.width
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            selectByMouse: true
            onTextChanged: root.query = text.toLowerCase()
            Rectangle {
                anchors.fill: parent
                anchors.margins: -8
                color: Theme.surface
                radius: Theme.radiusMed
                z: -1
            }
            Text {
                anchors.fill: parent
                text: "search keybinds…"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                visible: searchBox.text.length === 0
            }
            Keys.onReturnPressed: {
                if (list.count > 0)
                    root.runAction(list.itemAtIndex(0).runCmd);
            }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - searchBox.implicitHeight - hint.implicitHeight - 24
            clip: true
            spacing: 10
            model: {
                var out = [];
                var groups = doc.groups || [];
                var subs = doc.submaps || [];
                for (var s = 0; s < subs.length; s++)
                    groups = groups.concat([{name: "Submap: " + subs[s].name + " (" + subs[s].keys + ")", binds: subs[s].binds}]);
                for (var g = 0; g < groups.length; g++) {
                    var matches = [];
                    var binds = groups[g].binds || [];
                    for (var b = 0; b < binds.length; b++) {
                        var item = binds[b];
                        if (root.query.length === 0
                            || (item.desc && item.desc.toLowerCase().indexOf(root.query) >= 0)
                            || (item.keys && item.keys.toLowerCase().indexOf(root.query) >= 0))
                            matches.push(item);
                    }
                    if (matches.length > 0)
                        out.push({ name: groups[g].name, binds: matches });
                }
                return out;
            }

            delegate: Column {
                required property var modelData
                width: list.width
                spacing: 4

                Text {
                    text: modelData.name
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMed
                    font.bold: true
                }

                Repeater {
                    model: modelData.binds
                    delegate: Rectangle {
                        required property var modelData
                        property string runCmd: modelData.run || ""
                        width: list.width
                        implicitHeight: 30
                        color: Theme.surface
                        radius: Theme.radiusSmall

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Text {
                                text: modelData.keys || ""
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMed
                                font.bold: true
                                Layout.minimumWidth: 220
                            }
                            Text {
                                text: modelData.desc || ""
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMed
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.runAction(runCmd)
                        }
                    }
                }
            }
        }

        Text {
            id: hint
            anchors.horizontalCenter: parent.horizontalCenter
            text: "type to filter · enter runs first match · esc close · click runs"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
