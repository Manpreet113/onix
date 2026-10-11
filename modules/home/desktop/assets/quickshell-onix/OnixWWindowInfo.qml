// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWWindowInfo: focused-window title + app id (ports upstream
// WindowInfo). Vertical bars collapse to the app icon; centered bars cap
// the width; denser bars hide the app id.
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property int barId: 0

    readonly property string barSec: root.barId === 0 ? "bar" : "bar2"
    readonly property bool vertical: OnixSettings.get(["interface", root.barSec, "vertical"], false)
    readonly property bool centered: OnixSettings.get(["interface", root.barSec, "centered"], false)
    readonly property int density: OnixSettings.get(["interface", root.barSec, "density"], 0)

    readonly property var win: OnixNiri.activeWindow
    readonly property string title: (win && win.title) ? win.title : "Empty Workspace"
    readonly property string appId: (win && win.app_id) ? win.app_id : "Desktop"

    implicitWidth: root.vertical ? 40 : (root.centered ? 150 : 220)
    implicitHeight: 40

    Row {
        visible: !root.vertical
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 15
        spacing: 8

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: Quickshell.iconPath(OnixApps.iconFor(root.appId, root.title), "")
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 32
            spacing: 0

            Text {
                width: parent.width
                text: root.title
                color: OnixTheme.mOnSurface
                font.pixelSize: OnixTheme.fontMed
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                visible: root.density === 0
                width: parent.width
                text: root.appId
                color: OnixTheme.mOnSurfaceVariant
                font.pixelSize: OnixTheme.fontSmall
                elide: Text.ElideRight
            }
        }
    }

    IconImage {
        visible: root.vertical
        anchors.centerIn: parent
        width: 16
        height: 16
        source: Quickshell.iconPath(OnixApps.iconFor(root.appId, root.title), "")
    }
}
