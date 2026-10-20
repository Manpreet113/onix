import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.theme

// Apple Cover-Flow 3D Gallery Wallpaper Studio
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
    WlrLayershell.namespace: "onix-picker"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int sel: 0
    property real targetPosition: 0.0
    property real virtualPosition: targetPosition
    property string appliedPath: ""
    property bool open: false
    readonly property bool motionOK: Motion.motionEnabled
    property int count: WallpaperState.files.count

    Behavior on virtualPosition {
        id: posAnim
        NumberAnimation {
            duration: root.motionOK ? 280 : 0
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: normalizeTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (count > 0) {
                var norm = ((Math.round(targetPosition) % count) + count) % count;
                posAnim.enabled = false;
                targetPosition = norm;
                virtualPosition = norm;
                posAnim.enabled = true;
            }
        }
    }

    function cleanPath(p: string): string {
        if (!p) return "";
        return p.startsWith("file://") ? p.slice(7) : p;
    }

    function indexOf(path: string): int {
        var cp = cleanPath(path);
        for (var i = 0; i < count; i++)
            if (cleanPath(fileAt(i)) === cp) return i;
        return -1;
    }

    function fileAt(i: int): string {
        if (i < 0 || i >= count) return "";
        return WallpaperState.files.get(i, "filePath");
    }

    function distFor(index: int): real {
        if (count === 0) return 0;
        var diff = index - virtualPosition;
        diff = ((diff % count) + count) % count;
        if (diff > count / 2) diff -= count;
        return diff;
    }

    function thumbFor(path: string): string {
        if (!WallpaperState.isVideo(path) || path.length === 0)
            return path.length > 0 ? WallpaperState.fileUrl(path) : "";
        var base = path.split("/").pop().replace(/\.[^.]+$/, "");
        return "file://" + Quickshell.env("HOME") + "/.cache/onix-shell/thumbs/" + base + ".png";
    }

    function ensureVideoThumbs(): void {
        var cache = Quickshell.env("HOME") + "/.cache/onix-shell/thumbs";
        Quickshell.execDetached(["mkdir", "-p", cache]);
        for (var i = 0; i < count; i++) {
            var p = fileAt(i);
            if (!WallpaperState.isVideo(p)) continue;
            var base = p.split("/").pop().replace(/\.[^.]+$/, "");
            Quickshell.execDetached(["ffmpeg", "-n", "-loglevel", "error", "-i", p, "-vframes", "1", cache + "/" + base + ".png"]);
        }
    }

    function move(d: int): void {
        if (count === 0 || !open) return;
        targetPosition += d;
        sel = ((Math.round(targetPosition) % count) + count) % count;
        virtualPosition = targetPosition;
        WallpaperState.wipeDir = d >= 0 ? 1 : -1;
        WallpaperState.set(fileAt(sel), false);
        normalizeTimer.restart();
    }

    function goTo(t: int): void {
        if (count === 0 || !open) return;
        var diff = t - sel;
        while (diff > count / 2) diff -= count;
        while (diff < -count / 2) diff += count;
        move(diff);
    }

    function randomize(): void {
        if (count <= 1) return;
        var next = Math.floor(Math.random() * count);
        if (next === sel) next = (next + 1) % count;
        goTo(next);
    }

    function apply(): void {
        if (!open) {
            WallpaperState.pickerOpen = false;
            return;
        }
        WallpaperState.set(fileAt(sel), true);
        open = false;
        closeTimer.restart();
    }

    function cancel(): void {
        if (appliedPath.length > 0)
            WallpaperState.set(appliedPath, true);
        if (!open) {
            WallpaperState.pickerOpen = false;
            return;
        }
        open = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: root.motionOK ? Motion.snappy : 10
        repeat: false
        onTriggered: WallpaperState.pickerOpen = false
    }

    // Keyboard Shortcuts
    Shortcut { sequence: "Left"; enabled: root.open; onActivated: root.move(-1) }
    Shortcut { sequence: "Right"; enabled: root.open; onActivated: root.move(1) }
    Shortcut { sequence: "h"; enabled: root.open; onActivated: root.move(-1) }
    Shortcut { sequence: "l"; enabled: root.open; onActivated: root.move(1) }
    Shortcut { sequence: "Space"; enabled: root.open; onActivated: root.randomize() }
    Shortcut { sequence: "Return"; enabled: root.open; onActivated: root.apply() }
    Shortcut { sequence: "Enter"; enabled: root.open; onActivated: root.apply() }
    Shortcut { sequence: "Escape"; enabled: root.open; onActivated: root.cancel() }

    // 1. Ambient Scrim Backdrop (Click outside to Cancel, Wheel to Glide)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.open ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Motion.snappy }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
            onWheel: wheel => root.move(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    // 2. Cover-Flow 3D Stage
    Item {
        id: stage
        anchors.fill: parent
        opacity: root.open ? 1.0 : 0.0
        scale: root.open ? 1.0 : 0.94

        Behavior on opacity { NumberAnimation { duration: Motion.snappy } }
        Behavior on scale {
            NumberAnimation {
                duration: root.open ? Motion.spatialSlow : Motion.snappy
                easing.type: root.open ? Easing.OutBack : Easing.InQuad
            }
        }

        Repeater {
            model: root.count

            delegate: Item {
                id: cardRoot
                required property int index
                readonly property string cardPath: root.fileAt(index)
                readonly property real d: root.distFor(index)
                readonly property bool isCenter: Math.abs(d) < 0.4
                readonly property bool isNear: Math.abs(d) < 1.5

                // Only render items within 3D view frustum
                visible: Math.abs(d) < 2.4

                width: 580
                height: 360

                // Continuous Cover Flow position function
                x: {
                    var cx = stage.width / 2 - width / 2;
                    var clampedD = Math.max(-1.0, Math.min(1.0, d));
                    var extraD = d - clampedD;
                    return cx + clampedD * 460 + extraD * 220;
                }

                y: stage.height / 2 - height / 2 - 40

                z: Math.round(100 - Math.abs(d) * 35)

                scale: {
                    var a = Math.abs(d);
                    if (a <= 1.0) return 1.0 - a * 0.22;
                    return Math.max(0.60, 0.78 - (a - 1.0) * 0.12);
                }

                opacity: {
                    var a = Math.abs(d);
                    if (a <= 0.3) return 1.0;
                    if (a <= 1.0) return 1.0 - (a - 0.3) * 0.5;
                    if (a <= 2.2) return Math.max(0.0, 0.65 - (a - 1.0) * 0.54);
                    return 0.0;
                }

                transform: [
                    Translate { x: -cardRoot.width / 2; y: -cardRoot.height / 2 },
                    Matrix4x4 {
                        matrix: {
                            var clamped = Math.max(-1.0, Math.min(1.0, cardRoot.d));
                            var p = -clamped * 0.00075;
                            return Qt.matrix4x4(
                                1, 0, 0, 0,
                                0, 1, 0, 0,
                                0, 0, 1, 0,
                                p, 0, 0, 1
                            );
                        }
                    },
                    Translate { x: cardRoot.width / 2; y: cardRoot.height / 2 }
                ]

                // Deep Drop Shadow behind card
                Rectangle {
                    z: -2
                    anchors.fill: cardBox
                    anchors.margins: -10
                    radius: cardBox.radius + 10
                    color: "#000000"
                    opacity: Math.max(0.20, 0.85 - Math.abs(cardRoot.d) * 0.5)
                }

                // Soft Ambient Halo Glow (focused on center card)
                Rectangle {
                    z: -1
                    anchors.fill: cardBox
                    anchors.margins: -4
                    radius: cardBox.radius + 4
                    color: Theme.accent
                    opacity: Math.max(0.0, 0.35 - Math.abs(cardRoot.d) * 0.7)
                    Behavior on color { ColorAnimation { duration: Motion.effects } }
                }

                // Main Floating Art Card
                Item {
                    id: cardBox
                    anchors.fill: parent
                    property int radius: 20

                    // 1. MultiEffect Mask Source - Ensures ZERO corner bleeding
                    Item {
                        id: maskItem
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Rectangle {
                            anchors.fill: parent
                            radius: cardBox.radius
                            color: "white"
                        }
                    }

                    // 2. Raw Wallpaper Image
                    Image {
                        id: rawImg
                        anchors.fill: parent
                        source: root.thumbFor(cardRoot.cardPath)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 1160
                        sourceSize.height: 720
                        visible: false
                    }

                    // 3. MultiEffect: strictly clips rawImg to 20px rounded squircle
                    MultiEffect {
                        anchors.fill: parent
                        source: rawImg
                        maskEnabled: true
                        maskSource: maskItem
                    }

                    // 4. Subtle darkening overlay on side cards for visual hierarchy
                    Rectangle {
                        anchors.fill: parent
                        radius: cardBox.radius
                        color: "#000000"
                        opacity: Math.min(0.38, Math.abs(cardRoot.d) * 0.38)
                    }

                    // 5. Scrim gradient at the bottom of center card for readability
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 84
                        radius: cardBox.radius
                        opacity: Math.max(0.0, 1.0 - Math.abs(cardRoot.d) * 2.0)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                        }
                    }

                    // 6. Top Left Live Video Badge
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 14
                        height: 24
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.70)
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                        border.width: 1
                        visible: WallpaperState.isVideo(cardRoot.cardPath)
                        opacity: Math.max(0.0, 1.0 - Math.abs(cardRoot.d) * 2.0)
                        implicitWidth: vidBadgeRow.implicitWidth + 12

                        RowLayout {
                            id: vidBadgeRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                font.family: Theme.fontIcons
                                font.pixelSize: 14
                                color: Theme.accent
                                text: "play_arrow"
                            }

                            Text {
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: "#FFFFFF"
                                text: "LIVE VIDEO"
                            }
                        }
                    }

                    // 7. Top Right Checkmark Badge (if current active wallpaper)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 14
                        width: 26
                        height: 26
                        radius: 13
                        color: Theme.accent
                        visible: root.cleanPath(cardRoot.cardPath) === root.cleanPath(root.appliedPath)
                        opacity: Math.max(0.0, 1.0 - Math.abs(cardRoot.d) * 2.0)

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: Theme.textOnPrimary
                            text: "check"
                        }
                    }

                    // 8. Bottom Title and Filename
                    ColumnLayout {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16
                        spacing: 2
                        opacity: Math.max(0.0, 1.0 - Math.abs(cardRoot.d) * 2.0)

                        Text {
                            Layout.fillWidth: true
                            font.family: Theme.fontPrimary
                            font.pixelSize: 16
                            font.weight: Font.ExtraBold
                            color: "#FFFFFF"
                            text: WallpaperState.displayName(cardRoot.cardPath)
                            elide: Text.ElideRight
                        }

                        Text {
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accent
                            text: cardRoot.cardPath.split("/").pop()
                        }
                    }

                    // 9. Crisp Border drawn ON TOP of the image
                    Rectangle {
                        anchors.fill: parent
                        radius: cardBox.radius
                        color: "transparent"
                        border.width: cardRoot.isCenter ? 2 : 1
                        border.color: cardRoot.isCenter ? Theme.accent : Qt.rgba(1, 1, 1, 0.22)
                        Behavior on border.color { ColorAnimation { duration: Motion.effects } }
                    }

                    // 10. Mouse Interaction (Click to apply/navigate, Wheel to glide)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cardRoot.index === root.sel) {
                                root.apply();
                            } else {
                                root.goTo(cardRoot.index);
                            }
                        }
                        onWheel: wheel => root.move(wheel.angleDelta.y > 0 ? -1 : 1)
                    }
                }

                // Ground Reflection below card
                Item {
                    id: reflBox
                    anchors.top: cardBox.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: cardBox.horizontalCenter
                    width: cardBox.width
                    height: 65
                    clip: true
                    opacity: Math.max(0.0, 0.26 - Math.abs(cardRoot.d) * 0.15)
                    visible: opacity > 0.01

                    Item {
                        id: reflMask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Rectangle {
                            anchors.fill: parent
                            radius: cardBox.radius
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#55FFFFFF" }
                                GradientStop { position: 0.6; color: "#11FFFFFF" }
                                GradientStop { position: 1.0; color: "#00000000" }
                            }
                        }
                    }

                    Image {
                        id: rawReflImg
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: cardBox.width
                        height: cardBox.height
                        source: root.thumbFor(cardRoot.cardPath)
                        fillMode: Image.PreserveAspectCrop
                        transform: Scale { yScale: -1; origin.y: cardBox.height / 2 }
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: rawReflImg
                        maskEnabled: true
                        maskSource: reflMask
                    }
                }
            }
        }
    }

    // 3. Floating Crystal Control Island
    Rectangle {
        id: controlIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        width: Math.min(parent.width - 64, 720)
        height: 68
        radius: 34

        color: Theme.glassBg
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40)
        border.width: 1
        clip: true

        opacity: root.open ? 1.0 : 0.0
        scale: root.open ? 1.0 : 0.94
        Behavior on opacity { NumberAnimation { duration: Motion.snappy } }
        Behavior on scale {
            NumberAnimation {
                duration: root.open ? Motion.spatialSlow : Motion.snappy
                easing.type: root.open ? Easing.OutBack : Easing.InQuad
            }
        }

        // Ambient drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 6
            anchors.bottomMargin: -6
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            radius: parent.radius + 3
            color: Theme.glassShadow
            opacity: 0.80
        }

        // Top specular hairline highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            height: 1
            color: Theme.glassSpecular
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            // Onix Logo Emblem
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 12
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.32)
                border.width: 1

                OnixLogo {
                    anchors.centerIn: parent
                    size: 20
                    color: Theme.accent
                }
            }

            // Title & Format Info
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                RowLayout {
                    spacing: 8

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 15
                        font.weight: Font.ExtraBold
                        color: Theme.text
                        text: WallpaperState.displayName(root.fileAt(root.sel))
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }

                    Rectangle {
                        Layout.preferredHeight: 18
                        Layout.preferredWidth: typeText.implicitWidth + 10
                        radius: 4
                        color: WallpaperState.isVideo(root.fileAt(root.sel)) ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                        border.color: Theme.cardBorder
                        border.width: 1

                        Text {
                            id: typeText
                            anchors.centerIn: parent
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: WallpaperState.isVideo(root.fileAt(root.sel)) ? Theme.accent : Theme.dim
                            text: WallpaperState.isVideo(root.fileAt(root.sel)) ? "LIVE VIDEO" : "IMAGE"
                        }
                    }
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Theme.dim
                    text: `${root.sel + 1} of ${root.count} • ← → or H/L to glide`
                }
            }

            // Live Skein Color Palette Swatches (Tonal preview)
            RowLayout {
                spacing: 5

                Repeater {
                    model: [
                        { color: Theme.accent },
                        { color: Theme.primary },
                        { color: Theme.surfaceVariant },
                        { color: Theme.dim },
                        { color: Theme.success }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: 12
                        height: 12
                        radius: 6
                        color: modelData.color
                        border.color: Qt.rgba(1, 1, 1, 0.25)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Motion.effects } }
                    }
                }
            }

            // Shuffle Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: shuffleBtn.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: shuffleBtn.containsMouse ? Theme.accent : Theme.text
                    text: "shuffle"
                }

                MouseArea {
                    id: shuffleBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.randomize()
                }
            }

            // Open Folder Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: folderBtn.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: folderBtn.containsMouse ? Theme.accent : Theme.text
                    text: "folder_open"
                }

                MouseArea {
                    id: folderBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["xdg-open", WallpaperState.dir])
                }
            }

            // Cancel Button
            Rectangle {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 34
                radius: 10
                color: cancelBtn.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.text
                    text: "Cancel"
                }

                MouseArea {
                    id: cancelBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancel()
                }
            }

            // Set Wallpaper Hero Button
            Rectangle {
                Layout.preferredWidth: 126
                Layout.preferredHeight: 34
                radius: 10
                color: applyBtn.containsMouse ? Qt.rgba(Theme.accent.r * 1.1, Theme.accent.g * 1.1, Theme.accent.b * 1.1, 1.0) : Theme.accent

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        color: Theme.textOnPrimary
                        text: "check"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.textOnPrimary
                        text: "Set Wallpaper"
                    }
                }

                MouseArea {
                    id: applyBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.apply()
                }
            }
        }
    }

    Component.onCompleted: {
        appliedPath = WallpaperState.current;
        var idx = indexOf(appliedPath);
        sel = Math.max(0, idx >= 0 ? idx : 0);
        targetPosition = sel;
        posAnim.enabled = false;
        virtualPosition = sel;
        posAnim.enabled = true;
        ensureVideoThumbs();
        open = true;
    }
}
