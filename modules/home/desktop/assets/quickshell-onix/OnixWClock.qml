// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWClock: time + date pill (ports upstream Clock). 1s ticker; military
// time, date visibility, and day/month order come from module options.
// Vertical bars stack HH / MM / • / date / month; horizontal density-0
// stacks time over date, denser bars run one row.
import QtQuick

Item {
    id: root

    property int barId: 0

    readonly property string barSec: root.barId === 0 ? "bar" : "bar2"
    readonly property bool vertical: OnixSettings.get(["interface", root.barSec, "vertical"], false)
    readonly property int density: OnixSettings.get(["interface", root.barSec, "density"], 0)
    readonly property bool showDate: OnixSettings.get(["interface", "modules", "options", "show_date"], true)
    readonly property bool military: OnixSettings.get(["interface", "modules", "options", "military_time"], false)
    readonly property bool swapped: OnixSettings.get(["interface", "modules", "options", "day_month_swapped"], false)

    property var now: new Date()

    implicitWidth: root.vertical ? 44 : (rowLay.visible ? rowLay.implicitWidth + 20 : colLay.implicitWidth + 20)
    implicitHeight: root.vertical ? vLay.implicitHeight + 20 : (rowLay.visible ? 40 : 40)

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    function timeStr(): string {
        if (root.vertical)
            return "";
        return root.military ? Qt.formatDateTime(root.now, "HH:mm") : Qt.formatDateTime(root.now, "h:mm AP");
    }

    function dateStr(): string {
        return root.swapped ? Qt.formatDateTime(root.now, "ddd MMM d") : Qt.formatDateTime(root.now, "ddd d MMM");
    }

    // vertical stack: HH / MM / • / day-or-month / month-or-day
    Column {
        id: vLay
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.military ? Qt.formatDateTime(root.now, "HH") : Qt.formatDateTime(root.now, "h")
            color: OnixTheme.mOnSurface
            font.pixelSize: OnixTheme.fontMed
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "mm")
            color: OnixTheme.mOnSurface
            font.pixelSize: OnixTheme.fontMed
            font.bold: true
        }
        Text {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: "•"
            color: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontSmall
        }
        Text {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.swapped ? Qt.formatDateTime(root.now, "M") : Qt.formatDateTime(root.now, "d")
            color: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontSmall
        }
        Text {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.swapped ? Qt.formatDateTime(root.now, "d") : Qt.formatDateTime(root.now, "M")
            color: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontSmall
        }
    }

    // horizontal, density 0: stacked time over date
    Column {
        id: colLay
        visible: !root.vertical && root.density === 0
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeStr()
            color: OnixTheme.mOnSurface
            font.pixelSize: OnixTheme.fontMed
            font.bold: true
        }
        Text {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateStr()
            color: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontSmall
        }
    }

    // horizontal, density > 0: single row
    Row {
        id: rowLay
        visible: !root.vertical && root.density > 0
        anchors.centerIn: parent
        spacing: 10
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeStr()
            color: OnixTheme.mOnSurface
            font.pixelSize: OnixTheme.fontMed
            font.bold: true
        }
        Text {
            visible: root.showDate
            anchors.verticalCenter: parent.verticalCenter
            text: "•"
            color: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontSmall
        }
        Text {
            visible: root.showDate
            anchors.verticalCenter: parent.verticalCenter
            text: root.dateStr()
            color: OnixTheme.mOnSurfaceVariant
            font.pixelSize: OnixTheme.fontSmall
        }
    }
}
