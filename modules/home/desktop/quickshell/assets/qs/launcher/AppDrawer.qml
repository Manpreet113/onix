import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.popups
import qs.theme

// Ambxst / Caelestia Integrated App Drawer Component (Morphing Island View)
Item {
    id: root

    signal closeRequested()

    property string query: ""
    property string activeCategory: "All"
    property int sel: 0

    // Master apps list from desktop entries
    readonly property var allApps: {
        const apps = DesktopEntries.applications?.values ?? [];
        return apps.slice().sort((a, b) => (a.name || "").localeCompare(b.name || ""));
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
            root.closeRequested();
        }
    }

    function move(d: int): void {
        if (filteredApps.length === 0) return;
        sel = (((sel + d) % filteredApps.length) + filteredApps.length) % filteredApps.length;
        appListView.positionViewAtIndex(sel, ListView.Center);
    }

    Timer {
        id: focusTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (searchInput) searchInput.forceActiveFocus();
        }
    }

    function reset(): void {
        query = "";
        activeCategory = "All";
        sel = 0;
        if (searchInput) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
            focusTimer.restart();
        }
    }

    onVisibleChanged: {
        if (visible) {
            reset();
        }
    }

    // Keyboard navigation shortcuts
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.move(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.move(1) }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.launchIndex(root.sel) }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // 1. Search Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 12
            color: Theme.cardBg
            border.color: searchInput.activeFocus ? Theme.accent : Theme.cardBorder
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: Motion.effects } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: searchInput.activeFocus ? Theme.accent : Theme.dim
                    text: "search"
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
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
                        verticalAlignment: Text.AlignVCenter
                        font.family: Theme.fontPrimary
                        font.pixelSize: 13
                        font.weight: Font.Normal
                        color: Theme.dim
                        text: "Search apps or commands..."
                        visible: !searchInput.text
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

        // 2. Category Filter Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: ["All", "Development", "Internet", "Media", "System"]

                delegate: Rectangle {
                    id: catPill
                    required property var modelData
                    readonly property bool isSelected: root.activeCategory === modelData

                    Layout.preferredHeight: 26
                    implicitWidth: catLabel.implicitWidth + 14
                    radius: 8

                    color: isSelected ? Theme.accent : (catMouse.containsMouse ? Theme.chipHover : Qt.rgba(1, 1, 1, 0.04))
                    border.color: isSelected ? Theme.accent : (catMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.cardBorder)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Motion.effects } }
                    Behavior on border.color { ColorAnimation { duration: Motion.effects } }

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
                        id: catMouse
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

        // 3. Apps ListView
        ListView {
            id: appListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.filteredApps
            currentIndex: root.sel
            footer: Item {
                width: appListView.width
                height: 8
            }

            delegate: Rectangle {
                id: appDelegate
                required property var modelData
                required property int index

                readonly property bool isSelected: root.sel === index
                readonly property bool isHovered: appMouseArea.containsMouse

                width: appListView.width
                height: 52
                radius: 12

                color: isSelected ? Theme.chipHover : (isHovered ? Qt.rgba(1, 1, 1, 0.06) : Theme.cardBg)
                border.color: isSelected ? Theme.accent : Theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Motion.effects } }
                Behavior on border.color { ColorAnimation { duration: Motion.effects } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // App Icon Container
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Theme.chipBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        IconImage {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                            visible: source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 20
                            color: Theme.accent
                            text: "apps"
                            visible: !parent.children[0].visible
                        }
                    }

                    // App Title & Comment
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: isSelected ? Theme.accent : Theme.text
                            text: modelData.name || "Unknown Application"
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

                    // Launch Arrow Indicator
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 7
                        color: isSelected ? Theme.accent : Qt.rgba(1, 1, 1, 0.05)
                        visible: isSelected || isHovered

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: isSelected ? Theme.textOnPrimary : Theme.accent
                            text: "arrow_forward"
                        }
                    }
                }

                MouseArea {
                    id: appMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.sel = index
                    onClicked: root.launchIndex(index)
                }
            }

            // Empty state placeholder
            Item {
                anchors.centerIn: parent
                width: 200
                height: 100
                visible: root.filteredApps.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        font.family: Theme.fontIcons
                        font.pixelSize: 32
                        color: Theme.dim
                        text: "search_off"
                    }

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        font.family: Theme.fontPrimary
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.dim
                        text: "No applications found"
                    }
                }
            }
        }
    }
}
