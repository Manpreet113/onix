import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Searchable keybind cheatsheet, driven by ~/.config/quickshell/keybinds.json
// (generated from binds.nix — single source of truth, no lua parsing).
// Toggle via `quickshell --config shell ipc call keybinds toggle`.
PanelWindow {
    id: root

    visible: false
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property string query: ""

    property var doc: ({groups: [], submaps: []})

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

    function open(): void {
        query = "";
        searchBox.text = "";
        visible = true;
        card.scale = 0.94;
        card.opacity = 0;
        card.scale = 1.0;
        card.opacity = 1.0;
        searchBox.forceActiveFocus();
    }

    function close(): void {
        visible = false;
    }

    function runAction(run: string): void {
        var m = run.match(/exec_cmd\("(.+)"\)/);
        if (m)
            Quickshell.execDetached(["sh", "-c", m[1]]);
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void {
            root.visible ? root.close() : root.open();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.visible ? 0.55 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.7, 760)
        implicitHeight: 600
        color: "#2e3440"
        radius: 14
        border.color: "#4c566a"
        border.width: 1
        clip: true

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutBack
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            TextInput {
                id: searchBox
                width: parent.width
                color: "#eceff4"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                selectByMouse: true
                onTextChanged: root.query = text.toLowerCase()
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -8
                    color: "#3b4252"
                    radius: 8
                    z: -1
                }
                Text {
                    anchors.fill: parent
                    text: "search keybinds…"
                    color: "#6c7a96"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
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
                height: parent.height - searchBox.implicitHeight - hint.implicitHeight - 44
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
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Repeater {
                        model: modelData.binds
                        delegate: Rectangle {
                            required property var modelData
                            property string runCmd: modelData.run || ""
                            width: list.width
                            implicitHeight: 30
                            color: "#3b4252"
                            radius: 6

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 12

                                Text {
                                    text: modelData.keys || ""
                                    color: "#81a1c1"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.minimumWidth: 220
                                }
                                Text {
                                    text: modelData.desc || ""
                                    color: "#eceff4"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
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
                color: "#6c7a96"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
        }
    }
}
