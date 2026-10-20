import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import qs.components
import qs.theme
import qs.services

// Luxury Raycast / macOS-style Floating Command Palette
PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "onix-spotlight"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool open: false
    readonly property bool motionOK: Motion.motionEnabled
    property real pop: open ? 1 : 0

    Behavior on pop {
        NumberAnimation {
            duration: root.open ? Motion.spatial : Motion.snappy
            easing.type: root.open ? Easing.OutBack : Easing.InQuad
        }
    }

    function run(i: int): void {
        if (!open)
            return;
        SpotlightState.runItem(SpotlightState.results[i]);
        root.closePanel();
    }

    function closePanel(): void {
        if (!open) {
            SpotlightState.open = false;
            return;
        }
        open = false;
        closeTimer.restart();
    }

    onOpenChanged: {
        if (open) {
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        repeat: false
        onTriggered: {
            field.forceActiveFocus();
        }
    }

    Timer {
        id: closeTimer
        interval: root.motionOK ? Motion.snappy : 10
        repeat: false
        onTriggered: SpotlightState.open = false
    }

    // Keyboard Shortcuts
    Shortcut { sequence: "Up"; enabled: root.open; onActivated: SpotlightState.move(-1) }
    Shortcut { sequence: "Down"; enabled: root.open; onActivated: SpotlightState.move(1) }
    Shortcut {
        sequence: "Tab"
        enabled: root.open
        onActivated: {
            if (field.text.length === 0) {
                var modes = ["all", "clipboard", "notifications", "windows", "apps"];
                var idx = modes.indexOf(SpotlightState.mode);
                var next = modes[(idx + 1) % modes.length];
                SpotlightState.setMode(next);
            } else {
                SpotlightState.move(1);
            }
        }
    }
    Shortcut {
        sequence: "Backtab"
        enabled: root.open
        onActivated: {
            if (field.text.length === 0) {
                var modes = ["all", "clipboard", "notifications", "windows", "apps"];
                var idx = modes.indexOf(SpotlightState.mode);
                var prev = modes[(idx - 1 + modes.length) % modes.length];
                SpotlightState.setMode(prev);
            } else {
                SpotlightState.move(-1);
            }
        }
    }
    Shortcut { sequence: "Delete"; enabled: root.open; onActivated: SpotlightState.deleteSel() }
    Shortcut { sequence: "Ctrl+D"; enabled: root.open; onActivated: SpotlightState.deleteSel() }
    Shortcut { sequence: "Return"; enabled: root.open; onActivated: root.run(SpotlightState.sel) }
    Shortcut { sequence: "Enter"; enabled: root.open; onActivated: root.run(SpotlightState.sel) }
    Shortcut { sequence: "Escape"; enabled: root.open; onActivated: root.closePanel() }

    // Click outside backdrop to dismiss
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.closePanel()
        onWheel: wheel => SpotlightState.move(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    // Central Frosted Glass Command Palette Card
    Rectangle {
        id: card
        width: 660
        height: contentCol.implicitHeight
        x: (parent.width - width) / 2
        y: parent.height * 0.18

        color: Theme.glassBg
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40)
        border.width: 1
        radius: 22
        clip: true

        opacity: root.pop
        scale: 0.95 + 0.05 * root.pop

        Behavior on height {
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
            }
        }

        // Multi-tier ambient drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 6
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            anchors.bottomMargin: -6
            radius: parent.radius + 3
            color: Theme.glassShadow
            opacity: 0.75
        }

        // Top specular highlight line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            height: 1
            color: Theme.glassSpecular
        }

        ColumnLayout {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            // 1. Search Header Row
            Item {
                id: headerRow
                Layout.fillWidth: true
                Layout.preferredHeight: 58

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 16
                    spacing: 14

                    // Search Icon with accent glow
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 10
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: Theme.accent
                            text: field.text.startsWith(">") || field.text.startsWith("$") ? "terminal" :
                                  (SpotlightState.mode === "clipboard" ? "content_copy" :
                                  (SpotlightState.mode === "notifications" ? "notifications" :
                                  (SpotlightState.mode === "windows" ? "web_asset" :
                                  (SpotlightState.mode === "apps" ? "apps" : "search"))))
                        }
                    }

                    // Main Search Input
                    TextInput {
                        id: field
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontPrimary
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.text
                        cursorVisible: true
                        onTextChanged: SpotlightState.query = text

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            font.family: Theme.fontPrimary
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Theme.dim
                            text: SpotlightState.mode === "clipboard" ? "Search clipboard history... (Press Enter to paste, Del to remove)" :
                                  (SpotlightState.mode === "notifications" ? "Search notifications... (Press Enter to open, Del to dismiss)" :
                                  (SpotlightState.mode === "windows" ? "Search running windows..." :
                                  (SpotlightState.mode === "apps" ? "Search installed applications..." :
                                  "Search apps, calculate, switch windows, commands...")))
                            visible: !field.text && !field.inputMethodComposing
                        }
                    }

                    // Clear button (visible when query present)
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 13
                        color: clearMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                        border.color: Theme.cardBorder
                        border.width: 1
                        visible: field.text.length > 0

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                            color: Theme.dim
                            text: "close"
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                field.text = "";
                                field.forceActiveFocus();
                            }
                        }
                    }

                    // Keybind badge
                    Rectangle {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: escBadge.implicitWidth + 14
                        radius: 6
                        color: Theme.chipBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        Text {
                            id: escBadge
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.dim
                            text: "ESC"
                        }
                    }
                }
            }

            // 2. Mode Filter Tabs Bar
            Item {
                id: modeBar
                Layout.fillWidth: true
                Layout.preferredHeight: 36

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "all", label: "All", icon: "stars", count: 0 },
                            { id: "clipboard", label: "Clipboard", icon: "content_copy", count: Clip.count },
                            { id: "notifications", label: "Notifications", icon: "notifications", count: Notif.count },
                            { id: "windows", label: "Windows", icon: "web_asset", count: 0 },
                            { id: "apps", label: "Apps", icon: "apps", count: 0 }
                        ]

                        delegate: Rectangle {
                            id: chipDelegate
                            required property var modelData
                            readonly property bool isActive: SpotlightState.mode === modelData.id
                            readonly property bool isHovered: chipMouse.containsMouse

                            Layout.preferredHeight: 26
                            Layout.preferredWidth: chipRow.implicitWidth + 16
                            radius: 13

                            color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20) :
                                   (isHovered ? Theme.chipHover : Theme.chipBg)
                            border.color: isActive ? Theme.accent : Theme.cardBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Motion.snappy } }
                            Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

                            RowLayout {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 12
                                    color: chipDelegate.isActive ? Theme.accent : Theme.dim
                                    text: modelData.icon
                                }

                                Text {
                                    font.family: Theme.fontPrimary
                                    font.pixelSize: 11
                                    font.weight: chipDelegate.isActive ? Font.Bold : Font.DemiBold
                                    color: chipDelegate.isActive ? Theme.text : Theme.dim
                                    text: modelData.label
                                }

                                Rectangle {
                                    visible: modelData.count > 0
                                    Layout.preferredHeight: 15
                                    Layout.preferredWidth: countText.implicitWidth + 8
                                    radius: 7.5
                                    color: chipDelegate.isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35) : Qt.rgba(1, 1, 1, 0.08)

                                    Text {
                                        id: countText
                                        anchors.centerIn: parent
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: chipDelegate.isActive ? Theme.accent : Theme.dim
                                        text: String(modelData.count)
                                    }
                                }
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SpotlightState.setMode(modelData.id);
                                    field.forceActiveFocus();
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Clear All button for clipboard or notifications
                    Rectangle {
                        visible: (SpotlightState.mode === "clipboard" && Clip.count > 0) || (SpotlightState.mode === "notifications" && Notif.count > 0)
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: clearAllRow.implicitWidth + 12
                        radius: 6
                        color: clearAllMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.22) : "transparent"
                        border.color: clearAllMouse.containsMouse ? Theme.red : Theme.cardBorder
                        border.width: 1

                        RowLayout {
                            id: clearAllRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                font.family: Theme.fontIcons
                                font.pixelSize: 11
                                color: clearAllMouse.containsMouse ? Theme.red : Theme.dim
                                text: "delete_sweep"
                            }
                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: clearAllMouse.containsMouse ? Theme.red : Theme.dim
                                text: "Clear"
                            }
                        }

                        MouseArea {
                            id: clearAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (SpotlightState.mode === "clipboard") Clip.clear();
                                else if (SpotlightState.mode === "notifications") Notif.clearHistory();
                                SpotlightState.refresh();
                            }
                        }
                    }
                }
            }

            // Hairline specular glass divider
            Rectangle {
                id: divider
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.cardBorder
            }

            // 3. Results Container
            Item {
                id: resultsContainer
                Layout.fillWidth: true
                Layout.preferredHeight: SpotlightState.results.length === 0 ? 120 : (resultsList.implicitHeight + 16)
                clip: true

                // Empty State
                Item {
                    anchors.fill: parent
                    visible: SpotlightState.results.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: 21
                            color: Qt.rgba(1, 1, 1, 0.04)
                            border.color: Theme.cardBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontIcons
                                font.pixelSize: 20
                                color: Theme.dim
                                text: SpotlightState.mode === "clipboard" ? "content_paste_off" :
                                      (SpotlightState.mode === "notifications" ? "notifications_off" : "search_off")
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: Theme.fontPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.dim
                            text: SpotlightState.mode === "clipboard" ? "Clipboard history is empty" :
                                  (SpotlightState.mode === "notifications" ? "No recent notifications" : "No results found")
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            color: Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.7)
                            text: SpotlightState.mode === "clipboard" ? "Copy text from any app to see it here" :
                                  (SpotlightState.mode === "notifications" ? "All caught up!" : "Try another search term")
                        }
                    }
                }

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    model: SpotlightState.results
                    currentIndex: SpotlightState.sel
                    implicitHeight: Math.min(390, count * 54)
                    boundsBehavior: Flickable.StopAtBounds
                    visible: SpotlightState.results.length > 0

                    delegate: Rectangle {
                        id: resultItem
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === SpotlightState.sel
                        readonly property bool isHovered: itemMouse.containsMouse

                        width: resultsList.width
                        height: 50
                        radius: 12

                        color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) :
                               (isHovered ? Theme.chipHover : "transparent")
                        border.color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45) : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Motion.snappy } }
                        Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Leading Icon / Image Thumbnail
                            Rectangle {
                                Layout.preferredWidth: modelData.isImageClip ? 48 : 32
                                Layout.preferredHeight: 32
                                radius: 7
                                color: resultItem.isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.chipBg
                                border.color: modelData.isImageClip ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40) : Theme.cardBorder
                                border.width: 1
                                clip: true

                                // Thumbnail Image for clipboard images
                                Image {
                                    anchors.fill: parent
                                    source: (modelData.isImageClip && modelData.imagePath) ? ("file://" + modelData.imagePath) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 80
                                    sourceSize.height: 64
                                    asynchronous: true
                                    cache: true
                                    visible: modelData.isImageClip === true
                                }

                                // Material Icon (for system actions / calc / text clipboard / generic notifs)
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 17
                                    color: resultItem.isSelected ? Theme.accent : Theme.text
                                    text: modelData.icon || "star"
                                    visible: !modelData.isImageClip && (modelData.isMaterialIcon === true || modelData.kind === "calc" || modelData.kind === "clip")
                                }

                                // Freedesktop App / Window Icon
                                IconImage {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    source: (modelData.isMaterialIcon === true || modelData.kind === "calc" || modelData.kind === "clip" || modelData.isImageClip) ? "" :
                                            (modelData.icon ? (Quickshell.iconPath(modelData.icon, true) || Quickshell.iconPath("application-x-executable", true)) : "")
                                    visible: !modelData.isImageClip && !(modelData.isMaterialIcon === true || modelData.kind === "calc" || modelData.kind === "clip")
                                }
                            }

                            // Middle Info: Title & Subtitle
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    font.family: (modelData.kind === "clip" && !modelData.isImageClip) ? Theme.fontMono : Theme.fontPrimary
                                    font.pixelSize: 13
                                    font.weight: resultItem.isSelected ? Font.Bold : Font.DemiBold
                                    color: resultItem.isSelected ? Theme.accent : Theme.text
                                    text: modelData.title
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    font.family: Theme.fontPrimary
                                    font.pixelSize: 11
                                    font.weight: Font.Normal
                                    color: Theme.dim
                                    text: modelData.sub || ""
                                    elide: Text.ElideRight
                                    visible: modelData.sub && modelData.sub.length > 0
                                }
                            }

                            // Category Badge Pill
                            Rectangle {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: catBadge.implicitWidth + 12
                                radius: 5
                                color: Qt.rgba(1, 1, 1, 0.06)
                                border.color: Theme.cardBorder
                                border.width: 1
                                visible: modelData.category && modelData.category.length > 0

                                Text {
                                    id: catBadge
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: resultItem.isSelected ? Theme.accent : Theme.dim
                                    text: modelData.category || ""
                                }
                            }

                            // Dismiss / Delete pill (hint on hover or selection for dismissable items)
                            Rectangle {
                                visible: (modelData.kind === "clip" || modelData.kind === "notif") && (resultItem.isSelected || resultItem.isHovered)
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: delRow.implicitWidth + 10
                                radius: 5
                                color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                                border.color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.35)
                                border.width: 1

                                RowLayout {
                                    id: delRow
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Text {
                                        font.family: Theme.fontIcons
                                        font.pixelSize: 10
                                        color: Theme.red
                                        text: "delete"
                                    }

                                    Text {
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: Theme.red
                                        text: "DEL"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.kind === "clip") Clip.remove(modelData.id);
                                        else if (modelData.kind === "notif") Notif.dismissHistory(modelData.id);
                                        SpotlightState.refresh();
                                    }
                                }
                            }

                            // Action indicator pill (visible on selected item)
                            Rectangle {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: actionRow.implicitWidth + 14
                                radius: 7
                                color: resultItem.isSelected ? Theme.accent : "transparent"
                                visible: resultItem.isSelected

                                RowLayout {
                                    id: actionRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        font.family: Theme.fontIcons
                                        font.pixelSize: 13
                                        color: Theme.textOnPrimary
                                        text: "keyboard_return"
                                    }

                                    Text {
                                        font.family: Theme.fontPrimary
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Theme.textOnPrimary
                                        text: modelData.kind === "calc" ? "Copy" :
                                              (modelData.kind === "clip" ? "Paste" :
                                              (modelData.kind === "notif" ? "Open" :
                                              (modelData.kind === "window" ? "Focus" : "Open")))
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: SpotlightState.sel = index
                            onClicked: root.run(index)
                        }
                    }
                }
            }

            // Hairline divider before footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.cardBorder
            }

            // 4. Footer Bar with Hotkey Hints & Brand Badge
            Item {
                id: footerRow
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    // Brand signature
                    RowLayout {
                        spacing: 7

                        OnixLogo {
                            size: 14
                            color: Theme.dim
                            shadow: false
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.dim
                            text: SpotlightState.results.length > 0 ? `${SpotlightState.results.length} results • ${SpotlightState.mode.toUpperCase()}` : `Spotlight • ${SpotlightState.mode.toUpperCase()}`
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Navigation hotkey pills
                    RowLayout {
                        spacing: 10

                        // Navigate pill
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                width: 26
                                height: 18
                                radius: 4
                                color: Theme.chipBg
                                border.color: Theme.cardBorder
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.dim
                                    text: "↑↓"
                                }
                            }
                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                color: Theme.dim
                                text: "Navigate"
                            }
                        }

                        // Tab Switch pill
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                width: 30
                                height: 18
                                radius: 4
                                color: Theme.chipBg
                                border.color: Theme.cardBorder
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.dim
                                    text: "TAB"
                                }
                            }
                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                color: Theme.dim
                                text: "Mode"
                            }
                        }

                        // Delete pill (visible when in clip or notif mode)
                        RowLayout {
                            visible: SpotlightState.mode === "clipboard" || SpotlightState.mode === "notifications"
                            spacing: 4
                            Rectangle {
                                width: 28
                                height: 18
                                radius: 4
                                color: Theme.chipBg
                                border.color: Theme.cardBorder
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.dim
                                    text: "DEL"
                                }
                            }
                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                color: Theme.dim
                                text: "Remove"
                            }
                        }

                        // Select pill
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                width: 22
                                height: 18
                                radius: 4
                                color: Theme.chipBg
                                border.color: Theme.cardBorder
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 11
                                    color: Theme.dim
                                    text: "keyboard_return"
                                }
                            }
                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                color: Theme.dim
                                text: "Select"
                            }
                        }

                        // Close pill
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                width: 26
                                height: 18
                                radius: 4
                                color: Theme.chipBg
                                border.color: Theme.cardBorder
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.dim
                                    text: "ESC"
                                }
                            }
                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                color: Theme.dim
                                text: "Close"
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        SpotlightState.query = "";
        SpotlightState.sel = 0;
        SpotlightState.refresh();
        root.open = true;
    }
}
