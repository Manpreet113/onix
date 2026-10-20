import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.popups
import qs.services
import qs.theme

// Caelestia Living Dynamic Island Core
Rectangle {
    id: root

    readonly property string currentMode: {
        if (Notif.hasToast) return "notification";
        if (Osd.active) return "osd";
        return "clock";
    }

    color: islandHover.containsMouse ? Qt.rgba(Theme.glassBg.r * 1.15, Theme.glassBg.g * 1.15, Theme.glassBg.b * 1.15, 0.90) : Theme.glassBg
    border.color: currentMode === "notification" ? Theme.accent : (root.isExpanded ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40) : (islandHover.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.glassBorder))
    border.width: 1
    clip: true

    // Ambient drop shadow for spatial elevation
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        anchors.bottomMargin: -3
        radius: parent.radius + 2
        color: Theme.glassShadow
        opacity: root.isExpanded ? 0.75 : 0.50
        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
    }

    // Top specular highlight line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Theme.glassSpecular
    }

    readonly property bool isExpanded: PopupState.activePopup === "calendar"

    readonly property int targetWidth: {
        if (PopupState.activePopup === "calendar") return 580;
        switch (currentMode) {
            case "notification":
                return notifRow.implicitWidth + 28;
            case "osd":
                return osdRow.implicitWidth + 28;
            default:
                return clockRow.implicitWidth + 28;
        }
    }

    readonly property int targetHeight: {
        if (!isExpanded) return 40;
        if (PopupState.activePopup === "calendar") return Math.min(500, calView.implicitHeight + 46);
        return 40;
    }

    width: targetWidth
    implicitWidth: targetWidth
    height: targetHeight
    radius: isExpanded ? 24 : 20

    Behavior on width {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
        }
    }
    Behavior on implicitWidth {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
        }
    }
    Behavior on height {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
        }
    }
    Behavior on radius { NumberAnimation { duration: Motion.effects } }
    Behavior on color { ColorAnimation { duration: Motion.effects } }
    Behavior on border.color { ColorAnimation { duration: Motion.effects } }

    MouseArea {
        id: islandHover
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        enabled: !root.isExpanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.currentMode === "clock")
                PopupState.toggle("calendar");
        }
    }

    Item {
        id: topHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40

        // Close chip when expanded
        GlassChip {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: opacity > 0.01
            opacity: root.isExpanded ? 1 : 0
            implicitWidth: 28
            implicitHeight: 28
            squircleRadius: 13
            bg: Qt.rgba(1, 1, 1, 0.08)
            hoverBg: Qt.rgba(1, 1, 1, 0.20)
            fg: Theme.text

            Behavior on opacity { NumberAnimation { duration: Motion.effects } }

            Text {
                Layout.alignment: Qt.AlignCenter
                font.family: Theme.fontIcons
                font.pixelSize: 15
                color: Theme.text
                text: "close"
            }

            onClicked: PopupState.close()
        }

    // 1. CLOCK MODE (Caelestia Sculpted Clock + Date Chip)
    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8
        opacity: root.currentMode === "clock" ? 1 : 0
        visible: opacity > 0.02
        scale: root.currentMode === "clock" ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        Behavior on scale { NumberAnimation { duration: Motion.effects } }

        SystemClock {
            id: clock
            precision: SystemClock.Seconds
        }

        // Calendar Icon
        Text {
            font.family: Theme.fontIcons
            font.pixelSize: 15
            color: Theme.accent
            text: "schedule"
        }

        // Digital Time
        Text {
            font.family: Theme.fontPrimary
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.text
            text: Qt.formatDateTime(clock.date, "hh:mm")
        }

        // Subtle Seconds
        Text {
            font.family: Theme.fontPrimary
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Theme.text
            opacity: 0.55
            text: Qt.formatDateTime(clock.date, ":ss")
        }

        // Specular Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 12
            color: Theme.glassSpecular
        }

        // Date Pill
        Rectangle {
            Layout.preferredHeight: 22
            Layout.preferredWidth: dateText.implicitWidth + 12
            radius: 11
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1

            Text {
                id: dateText
                anchors.centerIn: parent
                font.family: Theme.fontPrimary
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.accent
                text: Qt.formatDateTime(clock.date, "ddd d MMM").toUpperCase()
            }
        }
    }

    // 2. OSD MODE (Liquid Glass Slider + Percentage)
    RowLayout {
        id: osdRow
        anchors.centerIn: parent
        spacing: 10
        opacity: root.currentMode === "osd" ? 1 : 0
        visible: opacity > 0.02
        scale: root.currentMode === "osd" ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        Behavior on scale { NumberAnimation { duration: Motion.effects } }

        Text {
            font.family: Theme.fontIcons
            font.pixelSize: 17
            color: Osd.muted ? Theme.error : Theme.accent
            text: {
                if (Osd.label === "Brightness")
                    return Osd.value > 0.5 ? "brightness_high" : "brightness_low";
                if (Osd.muted)
                    return "volume_off";
                return Osd.value > 0.5 ? "volume_up" : "volume_down";
            }
        }

        Rectangle {
            Layout.preferredWidth: 90
            Layout.preferredHeight: 6
            radius: 3
            color: Theme.surfaceVariant

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 3
                width: Math.max(0, Math.min(parent.width, parent.width * Osd.value))
                color: Osd.muted ? Theme.error : Theme.accent

                Behavior on width {
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }
            }
        }

        Text {
            font.family: Theme.fontPrimary
            font.pixelSize: 11
            font.weight: Font.Medium
            color: Theme.text
            text: Osd.muted ? "Muted" : Math.round(Osd.value * 100) + "%"
        }
    }

    // 4. NOTIFICATION BANNER
    RowLayout {
        id: notifRow
        anchors.centerIn: parent
        spacing: 8
        opacity: root.currentMode === "notification" ? 1 : 0
        visible: opacity > 0.02
        scale: root.currentMode === "notification" ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        Behavior on scale { NumberAnimation { duration: Motion.effects } }

        Item {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            IconImage {
                anchors.fill: parent
                source: Notif.appIcon !== "" ? Quickshell.iconPath(Notif.appIcon, true) : ""
                visible: source !== ""
            }

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontIcons
                font.pixelSize: 17
                color: Theme.accent
                text: "notifications"
                visible: !parent.children[0].visible
            }
        }

        ColumnLayout {
            spacing: 1
            Layout.maximumWidth: 220

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.text
                text: Notif.summary || Notif.appName
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 10
                font.weight: Font.Normal
                color: Theme.dim
                text: Notif.body
                elide: Text.ElideRight
                visible: Notif.body.length > 0
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.preferredHeight: 22
            Layout.preferredWidth: 22
            radius: 11
            color: dismissMouse.containsMouse ? Theme.chipHover : Theme.chipBg
            border.color: Theme.cardBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontIcons
                font.pixelSize: 14
                color: Theme.dim
                text: "close"
            }

            MouseArea {
                id: dismissMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notif.dismiss()
            }
        }
    }
}

    // Specular Divider
    Rectangle {
        anchors.top: topHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: root.isExpanded
        opacity: root.isExpanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
    }

    // Expanded Body Viewport (Flickable for smooth scrolling)
    Flickable {
        id: centerBody
        anchors.top: topHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        visible: root.height > 50
        contentWidth: width
        contentHeight: calView.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        CalendarPopup {
            id: calView
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            embedded: true
            visible: opacity > 0.01
            opacity: PopupState.activePopup === "calendar" ? 1 : 0
            transform: Translate {
                y: PopupState.activePopup === "calendar" ? 0 : 8
                Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        }
    }
}
