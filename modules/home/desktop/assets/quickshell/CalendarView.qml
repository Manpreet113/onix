import QtQuick
import QtQuick.Layouts
import Quickshell

// Calendar panel for the Overlay host: month grid (Monday-first),
// today highlight, month navigation. Host shortcuts: Left/Right
// switch months when this view is shown, T jumps to today.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    property string selected: ""

    property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    function isToday(y: int, m: int, d: int): bool {
        var n = new Date();
        return y === n.getFullYear() && m === n.getMonth() && d === n.getDate();
    }

    function cells(): var {
        var out = [];
        var first = new Date(root.year, root.month, 1);
        var lead = (first.getDay() + 6) % 7;
        var days = new Date(root.year, root.month + 1, 0).getDate();
        for (var i = 0; i < lead; i++)
            out.push(0);
        for (var d = 1; d <= days; d++)
            out.push(d);
        while (out.length % 7 !== 0)
            out.push(0);
        return out;
    }

    function prevMonth(): void {
        if (root.month === 0) {
            root.month = 11;
            root.year--;
        } else {
            root.month--;
        }
    }

    function nextMonth(): void {
        if (root.month === 11) {
            root.month = 0;
            root.year++;
        } else {
            root.month++;
        }
    }

    function goToday(): void {
        var n = new Date();
        root.year = n.getFullYear();
        root.month = n.getMonth();
    }

    function onShown(): void {
        root.goToday();
        root.selected = "";
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Text {
            text: "Calendar"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            font.bold: true
        }

        // big today header
        Column {
            width: parent.width
            spacing: 0

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(new Date(), "dddd")
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                font.bold: true
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(new Date(), "d MMMM yyyy")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(new Date(), "HH:mm")
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
            }
        }

        // month nav
        RowLayout {
            width: parent.width
            spacing: 8

            Rectangle {
                implicitWidth: 34
                implicitHeight: 28
                radius: Theme.radiusSmall
                color: navPrev.containsMouse ? Theme.primary : Theme.surface
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fadeFast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: navPrev.containsMouse ? Theme.bg : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMed
                    font.bold: true
                }
                MouseArea {
                    id: navPrev
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.prevMonth()
                }
            }
            Text {
                text: root.monthNames[root.month] + " " + root.year
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                implicitWidth: 66
                implicitHeight: 28
                radius: Theme.radiusSmall
                color: navToday.containsMouse ? Theme.primary : Theme.surface
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fadeFast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "today"
                    color: navToday.containsMouse ? Theme.bg : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
                MouseArea {
                    id: navToday
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.goToday()
                }
            }
            Rectangle {
                implicitWidth: 34
                implicitHeight: 28
                radius: Theme.radiusSmall
                color: navNext.containsMouse ? Theme.primary : Theme.surface
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fadeFast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "→"
                    color: navNext.containsMouse ? Theme.bg : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMed
                    font.bold: true
                }
                MouseArea {
                    id: navNext
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.nextMonth()
                }
            }
        }

        // weekday header
        Row {
            width: parent.width
            spacing: 4
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    required property string modelData
                    width: (parent.width - 24) / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
            }
        }

        // day grid
        Grid {
            width: parent.width
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: root.cells()
                delegate: Rectangle {
                    required property int modelData
                    required property int index
                    width: (parent.width - 24) / 7
                    height: 34
                    radius: Theme.radiusSmall
                    color: {
                        if (modelData === 0)
                            return "transparent";
                        if (root.isToday(root.year, root.month, modelData))
                            return Theme.primary;
                        if (root.selected === root.year + "-" + root.month + "-" + modelData)
                            return Theme.surface;
                        return dayMouse.containsMouse ? Theme.surface : "transparent";
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.fadeFast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: modelData !== 0
                        text: modelData
                        color: {
                            if (root.isToday(root.year, root.month, modelData))
                                return Theme.bg;
                            return Theme.text;
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMed
                        font.bold: root.isToday(root.year, root.month, modelData)
                    }
                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        enabled: modelData !== 0
                        hoverEnabled: true
                        onClicked: root.selected = root.year + "-" + root.month + "-" + modelData
                        onDoubleClicked: root.requestClose()
                    }
                }
            }
        }

        Item {
            width: 1
            height: 1
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← → month · t today · esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
