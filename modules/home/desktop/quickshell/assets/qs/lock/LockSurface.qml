import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.theme
import qs.components
import qs.services
import qs.wallpaper

Item {
    id: root

    required property var context

    // Wallpaper source & type detection
    readonly property string wallSource: {
        if (WallpaperState.current.length > 0)
            return WallpaperState.fileUrl(WallpaperState.current);
        if (WallpaperState.files && WallpaperState.files.count > 0)
            return WallpaperState.fileUrl(WallpaperState.files.get(0, "filePath"));
        return "";
    }
    readonly property bool isVideoWall: WallpaperState.isVideo(wallSource)

    // Smooth entrance / exit anim progress (0 = hidden/retracted, 1 = fully visible)
    property real animProgress: 0.0
    property real shakeOffset: 0.0

    // Time & Date state
    property string clockHours: Qt.formatDateTime(new Date(), "HH")
    property string clockMins: Qt.formatDateTime(new Date(), "mm")
    property string clockSecs: Qt.formatDateTime(new Date(), ":ss")
    property string fullDate: Qt.formatDateTime(new Date(), "dddd, MMMM d")

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.clockHours = Qt.formatDateTime(now, "HH");
            root.clockMins = Qt.formatDateTime(now, "mm");
            root.clockSecs = Qt.formatDateTime(now, ":ss");
            root.fullDate = Qt.formatDateTime(now, "dddd, MMMM d");
        }
    }

    // Backdrop Wallpaper with cinematic tint
    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Image {
        id: bgWallpaper
        anchors.fill: parent
        visible: !root.isVideoWall && root.wallSource.length > 0
        source: visible ? root.wallSource : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        scale: 1.04 - 0.04 * root.animProgress
        opacity: 0.85
    }

    Loader {
        anchors.fill: parent
        active: root.isVideoWall
        sourceComponent: Component {
            Video {
                anchors.fill: parent
                source: root.wallSource
                fillMode: VideoOutput.PreserveAspectCrop
                muted: true
                loops: MediaPlayer.Infinite
                autoPlay: true
                scale: 1.04 - 0.04 * root.animProgress
                opacity: 0.85
                onSourceChanged: play()
                Component.onCompleted: play()
            }
        }
    }

    // Frosted glass dark overlay & soft vignette
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.03, 0.03, 0.04, 0.62)
    }

    // Center ambient radial glow in Skein accent color
    Rectangle {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        width: 700
        height: 500
        radius: 250
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.07)
        scale: root.animProgress
    }

    // Click anywhere on screen to refocus the password field
    MouseArea {
        anchors.fill: parent
        onClicked: passInput.forceActiveFocus()
    }

    // ==========================================
    // 1. TOP STATUS BAR
    // ==========================================
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 70
        opacity: root.animProgress

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 40

            // Left: Onix Logo & Brand pill
            Rectangle {
                Layout.preferredHeight: 34
                Layout.preferredWidth: brandRow.implicitWidth + 24
                radius: 17
                color: Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                RowLayout {
                    id: brandRow
                    anchors.centerIn: parent
                    spacing: 8

                    OnixLogo {
                        size: 16
                        color: Theme.accent
                    }

                    Text {
                        font.family: Theme.fontDisplay
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.text
                        text: "ONIX OS"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Center: Lock Status Pill
            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: lockStatusRow.implicitWidth + 22
                radius: 16
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                border.width: 1

                RowLayout {
                    id: lockStatusRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 13
                        color: Theme.accent
                        text: root.context.unlockSuccessAnim ? "lock_open" : "lock"
                    }

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accent
                        text: root.context.unlockSuccessAnim ? "UNLOCKED" : "LOCKED"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right: Battery & System Gauge
            Rectangle {
                visible: (UPower.displayDevice && UPower.displayDevice.isPresent) === true
                Layout.preferredHeight: 34
                Layout.preferredWidth: battRow.implicitWidth + 20
                radius: 17
                color: Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                RowLayout {
                    id: battRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        color: (UPower.displayDevice && UPower.displayDevice.percentage < 0.20 && UPower.onBattery) ? Theme.error : Theme.text
                        text: UPower.onBattery ? "battery_std" : "battery_charging_full"
                    }

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.text
                        text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. HERO CENTERPIECE (Clock, User, Auth Capsule)
    // ==========================================
    ColumnLayout {
        id: centerCol
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30
        width: 480
        spacing: 0

        // Floating Entrance motion
        opacity: root.animProgress
        transform: Translate {
            y: 35 * (1.0 - root.animProgress)
        }

            // Big Luxury Architectural Clock
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 110
                    font.weight: Font.Bold
                    color: Theme.text
                    text: root.clockHours
                    renderType: Text.NativeRendering
                }

                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 96
                    font.weight: Font.DemiBold
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.70)
                    text: ":"
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 110
                    font.weight: Font.Bold
                    color: Theme.text
                    text: root.clockMins
                    renderType: Text.NativeRendering
                }

                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 42
                    font.weight: Font.DemiBold
                    color: Theme.accent
                    text: root.clockSecs
                    Layout.alignment: Qt.AlignBaseline
                    Layout.leftMargin: 4
                }
            }

            // Glass Date Chip
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 32
                Layout.preferredWidth: dateChipRow.implicitWidth + 24
                radius: 16
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: Theme.cardBorder
                border.width: 1

                RowLayout {
                    id: dateChipRow
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 13
                        color: Theme.dim
                        text: "calendar_today"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.subtext
                        text: root.fullDate
                    }
                }
            }

            // Spacing
            Item { Layout.preferredHeight: 38 }

            // User Avatar Pill
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20)
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        color: Theme.accent
                        text: "person"
                    }
                }

                Text {
                    font.family: Theme.fontDisplay
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Theme.text
                    text: Quickshell.env("USER") || "manpreet"
                }
            }

            // Spacing
            Item { Layout.preferredHeight: 16 }

            // Luxury Frosted Glass Password Field
            Rectangle {
                id: passPill
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 340
                Layout.preferredHeight: 52
                radius: 26
                transform: Translate { x: root.shakeOffset }

                color: root.context.showFailure ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.20) :
                       (root.context.unlockSuccessAnim ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28) : Theme.glassBg)

                border.color: root.context.showFailure ? Theme.error :
                              (root.context.unlockSuccessAnim ? Theme.accent :
                              (passInput.activeFocus ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)))
                border.width: passInput.activeFocus || root.context.showFailure ? 2 : 1

                Behavior on color { ColorAnimation { duration: Motion.snappy } }
                Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

                // Multi-tier ambient drop shadow / glow
                Rectangle {
                    z: -1
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 4
                    color: root.context.showFailure ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.28) :
                           (passInput.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.glassShadow)
                    opacity: 0.85
                }

                // Specular highlight line
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height: 1
                    color: Theme.glassSpecular
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 10
                    spacing: 12

                    // Leading Key / Lock Icon
                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 18
                        color: root.context.showFailure ? Theme.error : (passInput.activeFocus ? Theme.accent : Theme.dim)
                        text: root.context.unlockSuccessAnim ? "lock_open" : "vpn_key"
                    }

                    // Main Password Input
                    TextInput {
                        id: passInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontPrimary
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: Theme.text
                        echoMode: TextInput.Password
                        cursorVisible: true
                        focus: true
                        enabled: !root.context.unlockInProgress
                        onTextChanged: root.context.currentText = text
                        onAccepted: root.context.tryUnlock()

                        // Placeholder
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            font.family: Theme.fontPrimary
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Theme.dim
                            text: "Enter Password"
                            visible: !passInput.text
                        }
                    }

                    // Unlock Button (Pill Action)
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: root.context.unlockInProgress ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) :
                               (enterBtnMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20))
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: enterBtnMouse.containsMouse ? Theme.textOnPrimary : Theme.accent
                            text: root.context.unlockInProgress ? "sync" : "arrow_forward"
                        }

                        MouseArea {
                            id: enterBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.context.tryUnlock()
                        }
                    }
                }
            }

            // Status / Error hint label
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 28
                Layout.preferredWidth: 340

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontPrimary
                    font.pixelSize: 12
                    font.weight: root.context.showFailure ? Font.Bold : Font.Normal
                    color: root.context.showFailure ? Theme.error : Theme.dim
                    text: root.context.showFailure ? "Incorrect password • Please try again" :
                          (root.context.unlockInProgress ? "Verifying authentication…" : "Press Return to unlock")
                }
            }
        }

    // ==========================================
    // 3. BOTTOM FLOATING ISLANDS
    // ==========================================
    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 140
        opacity: root.animProgress

        // Centered Studio-Grade Frosted Media Dock (Caelestia Luxury Edition)
        Rectangle {
            id: mediaDock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            width: 530
            height: 98
            radius: 24

            visible: opacity > 0.01
            opacity: Media.hasTrack ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Motion.snappy } }

            color: Qt.rgba(Theme.glassBg.r, Theme.glassBg.g, Theme.glassBg.b, 0.85)
            border.color: Theme.glassBorder
            border.width: 1

            // Multi-Tier Ambient Drop Shadow & Diffused Glow
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.margins: -4
                radius: parent.radius + 4
                color: Theme.glassShadow
                opacity: 0.88
            }

            // Top Refractive Specular Highlight Rim
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
                anchors.leftMargin: 14
                anchors.rightMargin: 18
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 16

                // 1. Hero Squircle Artwork with Ambient Accent Aura Glow
                Item {
                    Layout.preferredWidth: 74
                    Layout.preferredHeight: 74

                    // Pulsing ambient aura glow behind the album art
                    Rectangle {
                        anchors.centerIn: parent
                        width: 78
                        height: 78
                        radius: 20
                        color: Theme.accent
                        opacity: Media.isPlaying ? 0.40 : 0.15
                        Behavior on opacity { NumberAnimation { duration: 600 } }

                        SequentialAnimation on scale {
                            running: Media.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.06; duration: 2200; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.00; duration: 2200; easing.type: Easing.InOutQuad }
                        }
                    }

                    Image {
                        id: cardArt
                        anchors.fill: parent
                        source: Media.artUrl || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: cardArtMask
                        anchors.fill: parent
                        radius: 17
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: cardArt
                        maskEnabled: true
                        maskSource: cardArtMask
                        visible: (Media.artUrl && Media.artUrl.length > 0) === true
                    }

                    // Fallback container when no artwork is available
                    Rectangle {
                        anchors.fill: parent
                        radius: 17
                        color: Theme.surfaceVariant
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        visible: !Media.artUrl || Media.artUrl.length === 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: 38
                            height: 38
                            radius: 19
                            color: Qt.rgba(1, 1, 1, 0.05)

                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontIcons
                                font.pixelSize: 22
                                color: Theme.accent
                                text: "graphic_eq"
                            }
                        }
                    }

                    // Cover Art Border Rim
                    Rectangle {
                        anchors.fill: parent
                        radius: 17
                        color: "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                        border.width: 1
                    }
                }

                // 2. Track Info & Live Scrub Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Header: Player Badge, Dancing Visualizer, and Timestamps
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Player Source Capsule
                        Rectangle {
                            Layout.preferredHeight: 18
                            Layout.preferredWidth: identRow.implicitWidth + 12
                            radius: 6
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                            border.width: 1

                            RowLayout {
                                id: identRow
                                anchors.centerIn: parent
                                spacing: 4

                                // Status Dot
                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Media.isPlaying ? Theme.signalLed : Theme.dim
                                }

                                Text {
                                    font.family: Theme.fontPrimary
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accent
                                    text: (Media.identity && Media.identity.length > 0) ? Media.identity.toUpperCase() : "MEDIA"
                                }
                            }
                        }

                        // Animated Dancing Equalizer Bars
                        Row {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter
                            property real wave: 0
                            NumberAnimation on wave {
                                from: 0
                                to: 6.28
                                duration: 1100
                                loops: Animation.Infinite
                                running: Media.isPlaying
                            }
                            Rectangle { width: 2.5; height: Media.isPlaying ? Math.max(3, 3 + 6 * Math.abs(Math.sin(parent.wave))) : 3; radius: 1.25; color: Theme.accent }
                            Rectangle { width: 2.5; height: Media.isPlaying ? Math.max(3, 3 + 8 * Math.abs(Math.sin(parent.wave + 1.2))) : 3; radius: 1.25; color: Theme.accent }
                            Rectangle { width: 2.5; height: Media.isPlaying ? Math.max(3, 3 + 5 * Math.abs(Math.sin(parent.wave + 2.4))) : 3; radius: 1.25; color: Theme.accent }
                        }

                        Item { Layout.fillWidth: true }

                        // Duration text
                        Text {
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.dim
                            text: Media.trackLength > 0 ? `${Media.formatTime(Media.position)} / ${Media.formatTime(Media.trackLength)}` : Media.formatTime(Media.position)
                        }
                    }

                    // Track Title
                    Text {
                        Layout.fillWidth: true
                        font.family: Theme.fontPrimary
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.text
                        text: Media.title || "No Track"
                        elide: Text.ElideRight
                    }

                    // Artist & Album
                    Text {
                        Layout.fillWidth: true
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        color: Theme.subtext
                        text: {
                            var a = Media.artist || "Unknown Artist";
                            if (Media.album && Media.album.length > 0 && Media.album !== Media.title) {
                                a += " • " + Media.album;
                            }
                            return a;
                        }
                        elide: Text.ElideRight
                    }

                    // Interactive Scrub Bar
                    Item {
                        id: scrubArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12

                        property bool isDragging: false
                        property real dragProgress: 0.0
                        readonly property real curProgress: isDragging ? dragProgress : Media.progress

                        // Groove
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 4
                            radius: 2
                            color: Qt.rgba(1, 1, 1, 0.12)

                            // Active Fill
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: Math.max(0, Math.min(parent.width, parent.width * scrubArea.curProgress))
                                radius: 2
                                color: Theme.accent
                            }
                        }

                        // Glow Handle (Thumb)
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * scrubArea.curProgress - (width / 2)))
                            width: seekMouse.containsMouse || scrubArea.isDragging ? 12 : 8
                            height: width
                            radius: width / 2
                            color: Theme.text
                            border.color: Theme.accent
                            border.width: 1.5
                            visible: Media.trackLength > 0

                            Behavior on width { NumberAnimation { duration: Motion.snappy } }
                        }

                        MouseArea {
                            id: seekMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            function updateFromMouse(mouse): void {
                                if (width <= 0) return;
                                const p = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                scrubArea.dragProgress = p;
                            }

                            onPressed: mouse => {
                                scrubArea.isDragging = true;
                                updateFromMouse(mouse);
                            }
                            onPositionChanged: mouse => {
                                if (scrubArea.isDragging) {
                                    updateFromMouse(mouse);
                                }
                            }
                            onReleased: mouse => {
                                if (scrubArea.isDragging) {
                                    updateFromMouse(mouse);
                                    if (Media.trackLength > 0) {
                                        Media.seek(scrubArea.dragProgress * Media.trackLength);
                                    }
                                    scrubArea.isDragging = false;
                                }
                            }
                        }
                    }
                }

                // 3. Transport Controls: Prev, Play/Pause Hero, Next
                RowLayout {
                    spacing: 6

                    // Prev Button
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: prevBtnMouse.containsMouse ? Theme.chipHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 19
                            color: prevBtnMouse.containsMouse ? Theme.accent : Theme.text
                            text: "skip_previous"
                        }

                        MouseArea {
                            id: prevBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.previous()
                        }
                    }

                    // Play / Pause Hero Button
                    Rectangle {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        radius: 23

                        // Halo glow behind Play/Pause button
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: parent.radius + 3
                            color: Theme.accent
                            opacity: Media.isPlaying ? 0.35 : (mediaPlayMouse.containsMouse ? 0.20 : 0.0)
                            Behavior on opacity { NumberAnimation { duration: Motion.snappy } }
                        }

                        color: mediaPlayMouse.containsMouse ?
                               (Media.isPlaying ? Qt.rgba(Theme.accent.r * 1.08, Theme.accent.g * 1.08, Theme.accent.b * 1.08, 1.0) : Theme.accent) :
                               (Media.isPlaying ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22))

                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.50)
                        border.width: 1

                        scale: mediaPlayMouse.pressed ? 0.92 : (mediaPlayMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Motion.snappy } }

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 24
                            color: Media.isPlaying ? Theme.textOnPrimary : (mediaPlayMouse.containsMouse ? Theme.textOnPrimary : Theme.accent)
                            text: Media.isPlaying ? "pause" : "play_arrow"
                        }

                        MouseArea {
                            id: mediaPlayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.togglePlay()
                        }
                    }

                    // Next Button
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: nextBtnMouse.containsMouse ? Theme.chipHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 19
                            color: nextBtnMouse.containsMouse ? Theme.accent : Theme.text
                            text: "skip_next"
                        }

                        MouseArea {
                            id: nextBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.next()
                        }
                    }
                }
            }
        }

        // Faint Emergency Hint
        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.40)
            text: "TTY: CTRL+ALT+F3"
        }
    }

    // ==========================================
    // 4. ANIMATIONS & EVENT HANDLING
    // ==========================================
    NumberAnimation {
        id: entranceAnim
        target: root
        property: "animProgress"
        from: 0.0
        to: 1.0
        duration: 550
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: exitAnim
        target: root
        property: "animProgress"
        from: 1.0
        to: 0.0
        duration: 350
        easing.type: Easing.InQuad
        onFinished: root.context.finishUnlock()
    }

    SequentialAnimation {
        id: shakeAnim
        loops: 1
        NumberAnimation { target: root; property: "shakeOffset"; to: -14; duration: 45; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "shakeOffset"; to: 14; duration: 45; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "shakeOffset"; to: -10; duration: 45; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "shakeOffset"; to: 10; duration: 45; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "shakeOffset"; to: -5; duration: 45; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "shakeOffset"; to: 5; duration: 45; easing.type: Easing.Linear }
        NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 45; easing.type: Easing.Linear }
    }

    Connections {
        target: root.context
        function onUnlockSuccessAnimChanged() {
            if (root.context.unlockSuccessAnim)
                exitAnim.start();
        }
        function onShowFailureChanged() {
            if (root.context.showFailure) {
                shakeAnim.restart();
                passInput.text = "";
                passInput.forceActiveFocus();
            }
        }
        function onCurrentTextChanged() {
            if (passInput.text !== root.context.currentText)
                passInput.text = root.context.currentText;
        }
    }

    Component.onCompleted: {
        entranceAnim.start();
        passInput.forceActiveFocus();
    }
}
