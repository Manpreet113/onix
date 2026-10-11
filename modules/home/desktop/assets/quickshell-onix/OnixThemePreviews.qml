// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixThemePreviews: light / dark theme cards (ports the theme selector
// rows). Selection writes dark_mode through OnixWallpaper.
import QtQuick

Row {
    id: root
    spacing: 10

    readonly property bool dark: OnixSettings.get(["appearance", "wallcolors", "dark_mode"], true)

    Repeater {
        model: [
            { label: "Light", dark: false, icon: "light_mode" },
            { label: "Dark", dark: true, icon: "dark_mode" }
        ]
        delegate: Rectangle {
            required property var modelData
            readonly property bool isCurrent: modelData.dark === root.dark

            implicitWidth: (root.width - 10) / 2
            implicitHeight: 100
            radius: 16
            color: modelData.dark ? "#2e3440" : "#eceff4"
            border.color: isCurrent ? OnixTheme.mPrimary : OnixTheme.mOutlineVariant
            border.width: isCurrent ? 2 : 1

            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.icon
                    color: modelData.dark ? "#eceff4" : "#2e3440"
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 22
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: modelData.dark ? "#eceff4" : "#2e3440"
                    font.pixelSize: OnixTheme.fontLarge
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: OnixWallpaper.setDarkMode(modelData.dark)
            }
        }
    }
}
