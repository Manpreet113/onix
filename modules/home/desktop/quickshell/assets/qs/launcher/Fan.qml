import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import qs.components
import qs.theme

// Ambxst / Caelestia Inspired Floating Luxury App Drawer
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
    WlrLayershell.namespace: "onix-launcher"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool open: false
    property string query: ""
    property string activeCategory: "All"
    property int sel: 0
    readonly property bool motionOK: Motion.motionEnabled

    // Master apps list from desktop entries
    readonly property var allApps: {
        const apps = DesktopEntries.applications?.values ?? [];
        return apps.slice().sort((a, b) => a.name.localeCompare(b.name));
    }

    // Filtered apps by query and category
    readonly property var filteredApps: {
        const q = query.trim().toLowerCase();
        const cat = activeCategory.toLowerCase();

        return allApps.filter(entry => {
            // Category check
            if (cat !== "all") {
                const cats = (entry.categories ?? []).map(c => c.toLowerCase());
                let matchCat = false;
                if (cat === "development" && (cats.includes("development") || cats.includes("programming"))) matchCat = true;
                else if (cat === "internet" && (cats.includes("network") || cats.includes("webbrowser") || cats.includes("chat"))) matchCat = true;
                else if (cat === "media" && (cats.includes("audiovideo") || cats.includes("audio") || cats.includes("video") || cats.includes("graphics"))) matchCat = true;
                else if (cat === "system" && (cats.includes("system") || cats.includes("settings"))) matchCat = true;
                else if (cat === "utilities" && (cats.includes("utility") || cats.includes("accessories"))) matchCat = true;
                if (!matchCat) return false;
            }

            // Search query check
            if (!q) return true;
            const nameMatch = entry.name && entry.name.toLowerCase().includes(q);
            const genMatch = entry.genericName && entry.genericName.toLowerCase().includes(q);
            const commentMatch = entry.comment && entry.comment.toLowerCase().includes(q);
            return nameMatch || genMatch || commentMatch;
        });
    }

    function launchIndex(i: int): void {
        if (i < 0 || i >= filteredApps.length) return;
        const app = filteredApps[i];
        if (app) {
            app.execute();
            close();
        }
    }

    function move(d: int): void {
        if (filteredApps.length === 0 || !open) return;
        sel = (((sel + d) % filteredApps.length) + filteredApps.length) % filteredApps.length;
        appListView.positionViewAtIndex(sel, ListView.Center);
    }

    function close(): void {
        if (!open) LauncherState.open = false;
        open = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: root.motionOK ? Motion.settle : 50
        repeat: false
        onTriggered: LauncherState.open = false
    }

    Shortcut { sequence: "Up"; enabled: root.open; onActivated: root.move(-1) }
    Shortcut { sequence: "Down"; enabled: root.open; onActivated: root.move(1) }
    Shortcut { sequence: "Return"; enabled: root.open; onActivated: root.launchIndex(root.sel) }
    Shortcut { sequence: "Escape"; enabled: root.open; onActivated: root.close() }

    // Click outside backdrop to dismiss
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.close()
    }

    // Sliding Glass Drawer Chassis
    Rectangle {
        id: drawerChassis
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        width: 440
        x: root.open ? (parent.width - width - 12) : parent.width

        color: Theme.glassBg
        border.color: Theme.glassBorder
        border.width: 1
        radius: 20
        clip: true

        Behavior on x {
            SpringAnimation {
                spring: Motion.springStiffness
                damping: Motion.springDamping
            }
        }

        // Ambient drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.leftMargin: -16
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            radius: parent.radius + 2
            color: Theme.glassShadow
            opacity: 0.65
        }

        // Top specular line
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // 1. Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 10
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    OnixLogo {
                        anchors.centerIn: parent
                        size: 22
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 16
                        font.weight: Font.ExtraBold
                        color: Theme.text
                        text: "Onix Applications"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        color: Theme.dim
                        text: `${root.filteredApps.length} of ${root.allApps.length} apps available`
                    }
                }

                // Close button chip
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcons
                        font.pixelSize: 18
                        color: Theme.dim
                        text: "close"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // 2. Interactive Search Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: Theme.cardBg
                border.color: searchInput.activeFocus ? Theme.accent : Theme.cardBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 20
                        color: searchInput.activeFocus ? Theme.accent : Theme.dim
                        text: "search"
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontPrimary
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.textOnPrimary
                        text: root.query
                        onTextChanged: {
                            root.query = text;
                            root.sel = 0;
                        }

                        Text {
                            anchors.fill: parent
                            font.family: Theme.fontPrimary
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.dim
                            text: "Search applications or commands..."
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }

                    // Clear button
                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 18
                        color: Theme.dim
                        text: "cancel"
                        visible: searchInput.text.length > 0

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // 3. Category Filter Chips
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["All", "Development", "Internet", "Media", "System"]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: root.activeCategory === modelData

                        Layout.preferredHeight: 28
                        implicitWidth: catLabel.implicitWidth + 16
                        radius: 8

                        color: isSelected ? Theme.accent : Theme.chipBg
                        border.color: isSelected ? Theme.accent : Theme.cardBorder
                        border.width: 1

                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            font.weight: isSelected ? Font.Bold : Font.DemiBold
                            color: isSelected ? Theme.textOnPrimary : Theme.subtext
                            text: modelData
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeCategory = modelData;
                                root.sel = 0;
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.cardBorder
            }

            // 4. Apps ListView
            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: root.filteredApps

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.sel === index
                    width: appListView.width
                    height: 56
                    radius: 12

                    color: isSelected ? Theme.chipHover : (appMouseArea.containsMouse ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45) : Theme.cardBg)
                    border.color: isSelected ? Theme.accent : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // App Icon Container
                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 10
                            color: Theme.chipBg
                            border.color: Theme.cardBorder
                            border.width: 1

                            IconImage {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: modelData.icon !== "" ? Quickshell.iconPath(modelData.icon, true) : ""
                                visible: source !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontIcons
                                font.pixelSize: 22
                                color: Theme.accent
                                text: "apps"
                                visible: !parent.children[0].visible
                            }
                        }

                        // App Title & Comment
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: isSelected ? Theme.text : Theme.text
                                text: modelData.name
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                font.weight: Font.Normal
                                color: Theme.dim
                                text: modelData.comment || modelData.genericName || "Application"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Arrow launch indicator
                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 8
                            color: isSelected ? Theme.accent : "transparent"
                            visible: isSelected || appMouseArea.containsMouse

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontIcons
                                font.pixelSize: 18
                                color: isSelected ? Theme.textOnPrimary : Theme.accent
                                text: "north_east"
                            }
                        }
                    }

                    MouseArea {
                        id: appMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchIndex(index)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        open = true;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }
}
