import QtQuick
import QtQuick.Layouts
import qs.powermenu
import qs.spotlight
import qs.theme

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

    spacing: 4

    Repeater {
        model: SpotlightState.powerActions()

        delegate: Rectangle {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: root.armed === modelData.name
                ? Theme.powerHover
                : (index === root.sel ? Theme.chipHover : Theme.chipBg)
            border.color: root.armed === modelData.name
                ? Theme.error
                : (index === root.sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.glassBorder)
            border.width: 1
            radius: 12

            Behavior on color { ColorAnimation { duration: Motion.effects } }
            Behavior on border.color { ColorAnimation { duration: Motion.effects } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    font.family: Theme.fontIcons
                    font.pixelSize: 20
                    color: root.armed === modelData.name ? Theme.error : (modelData.confirm ? Theme.error : Theme.accent)
                    text: modelData.symbol || "power_settings_new"
                }

                Text {
                    Layout.fillWidth: true
                    font.family: Theme.fontPrimary
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: root.armed === modelData.name ? Theme.error : Theme.text
                    text: root.armed === modelData.name ? (modelData.name + " (Click again to confirm)") : modelData.name
                    elide: Text.ElideRight
                }
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
