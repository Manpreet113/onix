import QtQuick
import QtQuick.Layouts
import qs.powermenu
import qs.spotlight

// Power deeds list for the growing bar island. Up/Down glide,
// Enter runs (reboot/shutdown ask twice), Esc handled by the bar.
ColumnLayout {
    id: root

    property int sel: 0
    property string armed: ""
    readonly property int count: SpotlightState.powerActions().length

    function reset(): void {
        sel = 0;
        armed = "";
    }

    function trigger(i: int): void {
        var acts = SpotlightState.powerActions();
        if (i < 0 || i >= acts.length)
            return;
        var a = acts[i];
        if (a.confirm && armed !== a.name) {
            armed = a.name;
            return;
        }
        SpotlightState.runItem({ kind: "power", ref: a.exec, lua: a.lua || "" });
        PowerState.open = false;
    }

    spacing: 2

    Repeater {
        model: SpotlightState.powerActions()

        delegate: Rectangle {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: root.armed === modelData.name ? "#40B69690" : (index === root.sel ? "#40777777" : "transparent")
            border.color: root.armed === modelData.name ? "#B69690" : "transparent"
            border.width: root.armed === modelData.name ? 1 : 0
            radius: 12

            Text {
                x: 12
                y: (parent.height - height) / 2
                width: parent.width - 24
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: root.armed === modelData.name ? "#B69690" : "#F2F2F2"
                text: (modelData.glyph || "") + "   " + modelData.name
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    root.sel = index;
                    root.armed = "";
                }
                onClicked: root.trigger(index)
            }
        }
    }
}
