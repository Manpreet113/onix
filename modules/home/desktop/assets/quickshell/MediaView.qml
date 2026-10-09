import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Media panel for the Overlay host: now-playing cards for every MPRIS
// player with play/pause toggle and next/previous. Host shortcuts:
// Space toggles, N/P step tracks when this view is shown.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    function players(): var {
        return Mpris.players.values;
    }

    function current(): var {
        var vals = Mpris.players.values;
        for (var i = 0; i < vals.length; i++)
            if (vals[i].isPlaying)
                return vals[i];
        return vals.length > 0 ? vals[0] : null;
    }

    function toggle(p: var): void {
        var t = p || root.current();
        if (t && t.canTogglePlaying)
            t.isPlaying = !t.isPlaying;
    }

    function step(next: bool): void {
        // playerctl follows the active player, same as the media keys
        Quickshell.execDetached(["playerctl", next ? "next" : "previous"]);
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Text {
            text: "Now playing"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            font.bold: true
        }

        Text {
            visible: root.players().length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "nothing playing"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMed
        }

        ListView {
            width: parent.width
            height: parent.height - 110
            clip: true
            spacing: 8
            model: root.players()

            delegate: Rectangle {
                required property var modelData
                width: parent.width
                implicitHeight: 84
                color: modelData.isPlaying ? Theme.bg : Theme.surface
                radius: Theme.radiusMed
                border.color: modelData.isPlaying ? Theme.blue : Theme.border
                border.width: modelData.isPlaying ? 1 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // play / pause
                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: 22
                        color: modelData.isPlaying ? Theme.blue : Theme.surface
                        border.color: Theme.border
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: modelData.isPlaying ? "⏸" : "▶"
                            color: modelData.isPlaying ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggle(modelData)
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: modelData.trackTitle || "Unknown Title"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMed
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: [modelData.trackArtist, modelData.identity].filter(function (s) {
                                return s && s.length > 0;
                            }).join(" · ")
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: "⏮"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            onClicked: root.step(false)
                        }
                    }
                    Text {
                        text: "⏭"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            onClicked: root.step(true)
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "space play/pause · n next · p previous · esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
