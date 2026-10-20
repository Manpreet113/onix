import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.theme

// Ambxst / Caelestia Inspired Interactive Calendar & Big Analog Clock Pop-up
Rectangle {
    id: root
    width: 580
    implicitHeight: mainCol.implicitHeight + 28
    height: implicitHeight

    property bool embedded: false

    // Calendar state
    property var today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth() // 0-11
    property int selectedDay: today.getDate()

    color: embedded ? "transparent" : Theme.glassBg
    border.color: embedded ? "transparent" : Theme.glassBorder
    border.width: embedded ? 0 : 1
    radius: embedded ? 0 : 20
    clip: true

    // Specular highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: !root.embedded
    }

    // Drop shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        radius: parent.radius + 2
        color: Theme.glassShadow
        opacity: 0.6
        visible: !root.embedded
    }

    SystemClock {
        id: liveClock
        precision: SystemClock.Seconds
    }

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    function prevMonth(): void {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else {
            viewMonth--;
        }
        rebuildDays();
    }

    function nextMonth(): void {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else {
            viewMonth++;
        }
        rebuildDays();
    }

    function jumpToToday(): void {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
        selectedDay = today.getDate();
        rebuildDays();
    }

    ListModel {
        id: daysModel
    }

    function rebuildDays(): void {
        daysModel.clear();
        const firstDay = new Date(viewYear, viewMonth, 1);
        let startDay = firstDay.getDay() - 1;
        if (startDay < 0) startDay = 6;

        const daysInPrev = new Date(viewYear, viewMonth, 0).getDate();
        const daysInCur = new Date(viewYear, viewMonth + 1, 0).getDate();

        // Previous month padding
        for (let i = startDay - 1; i >= 0; i--) {
            daysModel.append({
                dayNumber: daysInPrev - i,
                isCurMonth: false,
                isToday: false
            });
        }

        // Current month days
        const isCurrentView = (viewYear === today.getFullYear() && viewMonth === today.getMonth());
        for (let d = 1; d <= daysInCur; d++) {
            daysModel.append({
                dayNumber: d,
                isCurMonth: true,
                isToday: isCurrentView && (d === today.getDate())
            });
        }

        // Next month padding to fill 42 cells (6 rows)
        const rem = 42 - daysModel.count;
        for (let n = 1; n <= rem; n++) {
            daysModel.append({
                dayNumber: n,
                isCurMonth: false,
                isToday: false
            });
        }
    }

    Component.onCompleted: rebuildDays()

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 12

        // Top Header Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 10
                color: Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: Theme.accent
                    text: "calendar_month"
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.text
                    text: "Calendar & Schedule"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 10
                    color: Theme.dim
                    text: Qt.formatDateTime(liveClock.date, "dddd, MMMM d, yyyy")
                }
            }

            // Today button chip
            Rectangle {
                Layout.preferredWidth: todayText.implicitWidth + 14
                Layout.preferredHeight: 24
                radius: 6
                color: todayMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: todayMouse.containsMouse ? Theme.accent : Theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Motion.snappy } }
                Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

                Text {
                    id: todayText
                    anchors.centerIn: parent
                    font.family: Theme.fontPrimary
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Theme.accent
                    text: "Today"
                }

                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.jumpToToday()
                }
            }
        }

        // Horizontal Specular Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.cardBorder
        }

        // Dual Pane Side-by-Side: Calendar on Left, Big Analog Clock on Right
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // LEFT PANE: Full Interactive Month Calendar
            ColumnLayout {
                Layout.preferredWidth: 290
                spacing: 10

                // Month Navigation Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.text
                        text: root.monthNames[root.viewMonth] + " " + root.viewYear
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 7
                        color: prevMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                        border.color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.cardBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Motion.snappy } }

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: Theme.text
                            text: "chevron_left"
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.prevMonth()
                        }
                    }

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 7
                        color: nextMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                        border.color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.cardBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Motion.snappy } }

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: Theme.text
                            text: "chevron_right"
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextMonth()
                        }
                    }
                }

                // Days of the Week Headers
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                        delegate: Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: Theme.dim
                                text: modelData
                            }
                        }
                    }
                }

                // Calendar Days Grid (7 columns x 6 rows)
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: daysModel

                        delegate: Rectangle {
                            required property var model
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            radius: 8

                            color: model.isToday ? Theme.accent : (model.dayNumber === root.selectedDay && model.isCurMonth ? Theme.chipHover : "transparent")
                            border.color: (model.dayNumber === root.selectedDay && model.isCurMonth && !model.isToday) ? Theme.accent : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                font.weight: model.isToday ? Font.ExtraBold : (model.isCurMonth ? Font.DemiBold : Font.Normal)
                                color: model.isToday ? Theme.textOnPrimary : (model.isCurMonth ? Theme.text : Theme.dim)
                                opacity: model.isCurMonth ? 1.0 : 0.4
                                text: model.dayNumber
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.isCurMonth) root.selectedDay = model.dayNumber;
                                }
                            }
                        }
                    }
                }

                // Quick DND Toggle Tile
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Sys.dnd ? Theme.chipHover : Theme.cardBg
                    border.color: Sys.dnd ? Theme.accent : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 15
                            color: Sys.dnd ? Theme.accent : Theme.dim
                            text: Sys.dnd ? "notifications_off" : "notifications"
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.text
                            text: Sys.dnd ? "DND Active" : "Do Not Disturb"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Sys.toggleDnd()
                    }
                }
            }

            // Vertical Specular Divider Line
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 310
                Layout.alignment: Qt.AlignVCenter
                color: Theme.glassSpecular
            }

            // RIGHT PANE: Big Analog Clock (As Big As Calendar) & Live Time
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                // Prominent Luxury Analog Clock Dial (Matching Calendar Size)
                AnalogClock {
                    size: 195
                    date: liveClock.date
                    showNumerals: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // Digital Time Readout
                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 26
                    font.weight: Font.ExtraBold
                    color: Theme.text
                    text: Qt.formatDateTime(liveClock.date, "hh:mm:ss")
                    Layout.alignment: Qt.AlignHCenter
                }

                // Subtext / Timezone status badge
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.signalLed
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.dim
                        text: "Local Time (UTC+5:30)"
                    }
                }
            }
        }
    }
}
