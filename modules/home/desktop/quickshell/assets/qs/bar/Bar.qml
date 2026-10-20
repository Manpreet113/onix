import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.launcher
import qs.popups
import qs.theme

// Caelestia / Material 3 Architecture: Three Independent Morphing Islands
PanelWindow {
    id: root
    property var modelData: null
    screen: modelData ?? Quickshell.screens[0]

    anchors {
        top: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 48
    margins {
        top: 8
        left: 16
        right: 16
    }
    implicitHeight: screen?.height ?? 1200
    color: "transparent"

    // Global backdrop click-outside dismisser
    MouseArea {
        id: dismissArea
        anchors.fill: parent
        z: 0
        visible: PopupState.isOpen
        acceptedButtons: Qt.LeftButton
        onClicked: PopupState.close()
    }

    mask: Region {
        item: PopupState.isOpen ? dismissArea : null
        Region {
            item: leftIsland
            Region {
                item: centerIsland
                Region {
                    item: mediaIsland.visible ? mediaIsland : null
                    Region {
                        item: rightIsland
                    }
                }
            }
        }
    }

    // Global Dismiss Shortcuts
    Shortcut {
        sequence: "Escape"
        enabled: PopupState.isOpen
        onActivated: PopupState.close()
    }

    // Power Hotkeys when Power menu is active
    Shortcut {
        sequence: "l"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["quickshell", "ipc", "-c", "onix", "call", "lock", "lock"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "u"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["systemctl", "suspend"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "e"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["hyprctl", "dispatch", "exit"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "r"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["systemctl", "reboot"]); PopupState.close(); }
    }
    Shortcut {
        sequence: "s"
        enabled: PopupState.activePopup === "power"
        onActivated: { Quickshell.execDetached(["systemctl", "poweroff"]); PopupState.close(); }
    }

    WlrLayershell.namespace: "onix-bar"
    WlrLayershell.keyboardFocus: PopupState.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // 1. LEFT FLOATING ISLAND: Living Dynamic App Drawer & Workspaces Island
    Rectangle {
        id: leftIsland
        anchors.top: parent.top
        anchors.left: parent.left
        z: 1

        readonly property bool isExpanded: PopupState.activePopup === "apps"

        readonly property int targetWidth: isExpanded ? 440 : (leftRow.implicitWidth + 20)
        readonly property int targetHeight: isExpanded ? Math.min(580, (root.screen?.height ?? 1080) - 80) : 40

        width: targetWidth
        height: targetHeight

        color: Theme.glassBg
        border.color: isExpanded ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40) : Theme.glassBorder
        border.width: 1
        radius: isExpanded ? 24 : 20
        clip: true

        Behavior on width {
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

        // Ambient drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            anchors.bottomMargin: -3
            radius: parent.radius + 2
            color: Theme.glassShadow
            opacity: leftIsland.isExpanded ? 0.75 : 0.50
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

        // Header Bar (height: 40)
        Item {
            id: leftHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40

            // Collapsed Mode: Logo + Workspaces + WindowTitle
            RowLayout {
                id: leftRow
                anchors.centerIn: parent
                height: 40
                spacing: 8
                visible: opacity > 0.01
                opacity: leftIsland.isExpanded ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }

                // App Drawer Launcher chip
                Rectangle {
                    id: launcherBtn
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    Layout.alignment: Qt.AlignVCenter
                    radius: 15
                    color: launcherMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                    border.color: launcherMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.cardBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Motion.snappy } }
                    Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

                    OnixLogo {
                        id: onixBrandLogo
                        anchors.centerIn: parent
                        size: 19
                        color: launcherMouse.containsMouse ? Qt.rgba(Theme.accent.r * 1.2, Theme.accent.g * 1.2, Theme.accent.b * 1.2, 1.0) : Theme.accent
                        shadow: false
                        scale: launcherMouse.containsMouse ? 1.08 : 1.0
                        Behavior on scale { NumberAnimation { duration: Motion.snappy } }
                    }

                    MouseArea {
                        id: launcherMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PopupState.toggle("apps")
                    }
                }

                Workspaces {
                    Layout.alignment: Qt.AlignVCenter
                }

                // Specular Divider
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    color: Theme.glassSpecular
                    visible: true
                }

                WindowTitle {
                    id: winTitle
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Expanded Mode Header: Logo badge + "Onix Applications" + close pill
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                visible: opacity > 0.01
                opacity: leftIsland.isExpanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
                    color: Theme.accent
                    border.color: Qt.rgba(1, 1, 1, 0.30)
                    border.width: 1

                    OnixLogo {
                        anchors.centerIn: parent
                        size: 18
                        color: Theme.textOnPrimary
                        shadow: false
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PopupState.close()
                    }
                }

                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 15
                    font.weight: Font.ExtraBold
                    color: Theme.text
                    text: "Onix Applications"
                }

                Rectangle {
                    radius: 6
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1
                    implicitWidth: appCountText.implicitWidth + 12
                    implicitHeight: 22

                    Text {
                        id: appCountText
                        anchors.centerIn: parent
                        font.family: Theme.fontPrimary
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.accent
                        text: `${appDrawerView.filteredApps.length} apps`
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Close Pill
                GlassChip {
                    implicitWidth: 28
                    implicitHeight: 28
                    squircleRadius: 13
                    bg: Qt.rgba(1, 1, 1, 0.08)
                    hoverBg: Qt.rgba(1, 1, 1, 0.20)
                    fg: Theme.text

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                        color: Theme.text
                        text: "close"
                    }

                    onClicked: PopupState.close()
                }
            }
        }

        // Specular Divider below header
        Rectangle {
            anchors.top: leftHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            height: 1
            color: Theme.glassSpecular
            visible: leftIsland.isExpanded
            opacity: leftIsland.isExpanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        }

        // Expanded Body Viewport
        Item {
            id: leftBody
            anchors.top: leftHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            visible: leftIsland.height > 60

            AppDrawer {
                id: appDrawerView
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: leftIsland.isExpanded ? 1 : 0
                transform: Translate {
                    y: leftIsland.isExpanded ? 0 : 8
                    Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }
                onCloseRequested: PopupState.close()
            }
        }
    }

    // 2. CENTER FLOATING ISLAND: Living Dynamic Island Core
    CenterIsland {
        id: centerIsland
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // 2.5 DEDICATED MEDIA ISLAND: Only appears when media is playing
    MediaIsland {
        id: mediaIsland
        anchors.top: parent.top
        anchors.left: centerIsland.right
        anchors.leftMargin: 10
    }

    // 3. RIGHT FLOATING ISLAND: Living Dynamic Status & Control Island
    Rectangle {
        id: rightIsland
        anchors.top: parent.top
        anchors.right: parent.right
        z: 1

        readonly property bool isExpanded: PopupState.activePopup === "audio" ||
                                           PopupState.activePopup === "wifi" ||
                                           PopupState.activePopup === "bluetooth" ||
                                           PopupState.activePopup === "network" ||
                                           PopupState.activePopup === "battery" ||
                                           PopupState.activePopup === "power"

        readonly property int targetWidth: isExpanded ? 360 : (rightRow.implicitWidth + 20)
        readonly property int targetHeight: {
            if (!isExpanded) return 40;
            if (PopupState.activePopup === "audio") return Math.min(500, audioView.implicitHeight + 46);
            if (PopupState.activePopup === "wifi" || PopupState.activePopup === "network") return Math.min(540, wifiView.implicitHeight + 46);
            if (PopupState.activePopup === "bluetooth") return Math.min(520, btView.implicitHeight + 46);
            if (PopupState.activePopup === "battery") return Math.min(480, battView.implicitHeight + 46);
            if (PopupState.activePopup === "power") return Math.min(420, powerView.implicitHeight + 46);
            return 340;
        }

        width: targetWidth
        height: targetHeight

        color: Theme.glassBg
        border.color: isExpanded ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40) : Theme.glassBorder
        border.width: 1
        radius: isExpanded ? 24 : 20
        clip: true

        Behavior on width {
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

        // Ambient drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            anchors.bottomMargin: -3
            radius: parent.radius + 2
            color: Theme.glassShadow
            opacity: rightIsland.isExpanded ? 0.75 : 0.50
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

        // Header Bar (chips remain interactive at the top!)
        Item {
            id: rightHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40

            RowLayout {
                id: rightRow
                anchors.centerIn: parent
                height: 40
                spacing: 6

                Cluster {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Close Pill (visible when expanded)
            GlassChip {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: opacity > 0.01
                opacity: rightIsland.isExpanded ? 1 : 0
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
        }

        // Specular Divider below header
        Rectangle {
            anchors.top: rightHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            height: 1
            color: Theme.glassSpecular
            visible: rightIsland.isExpanded
            opacity: rightIsland.isExpanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        }

        // Expanded Body Viewport (Flickable for dynamic lists)
        Flickable {
            id: rightBody
            anchors.top: rightHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            visible: rightIsland.height > 50
            contentWidth: width
            contentHeight: {
                if (PopupState.activePopup === "audio") return audioView.implicitHeight;
                if (PopupState.activePopup === "wifi" || PopupState.activePopup === "network") return wifiView.implicitHeight;
                if (PopupState.activePopup === "bluetooth") return btView.implicitHeight;
                if (PopupState.activePopup === "battery") return battView.implicitHeight;
                if (PopupState.activePopup === "power") return powerView.implicitHeight;
                return height;
            }
            boundsBehavior: Flickable.StopAtBounds

            AudioPopup {
                id: audioView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                embedded: true
                visible: opacity > 0.01
                opacity: PopupState.activePopup === "audio" ? 1 : 0
                transform: Translate {
                    y: PopupState.activePopup === "audio" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }
            }

            WifiPopup {
                id: wifiView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                embedded: true
                visible: opacity > 0.01
                opacity: (PopupState.activePopup === "wifi" || PopupState.activePopup === "network") ? 1 : 0
                transform: Translate {
                    y: (PopupState.activePopup === "wifi" || PopupState.activePopup === "network") ? 0 : 8
                    Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }
            }

            BluetoothPopup {
                id: btView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                embedded: true
                visible: opacity > 0.01
                opacity: PopupState.activePopup === "bluetooth" ? 1 : 0
                transform: Translate {
                    y: PopupState.activePopup === "bluetooth" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }
            }

            BatteryPopup {
                id: battView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                embedded: true
                visible: opacity > 0.01
                opacity: PopupState.activePopup === "battery" ? 1 : 0
                transform: Translate {
                    y: PopupState.activePopup === "battery" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }
            }

            PowerPopup {
                id: powerView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                embedded: true
                visible: opacity > 0.01
                opacity: PopupState.activePopup === "power" ? 1 : 0
                transform: Translate {
                    y: PopupState.activePopup === "power" ? 0 : 8
                    Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: Motion.effects } }
                onActionExecuted: PopupState.close()
            }
        }
    }
}
