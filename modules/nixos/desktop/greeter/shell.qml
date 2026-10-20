import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Services.UPower
import "components"

FloatingWindow {
    id: win

    title: "Onix Greeter"
    visible: true
    color: Theme.background

    // Greeter state
    property string username: "manpreet"
    property string currentPassword: ""
    property bool authenticating: false
    property bool authFailed: false
    property bool launching: false
    property bool showPassword: false
    property bool powerMenuOpen: false
    property string sessionCmd: "onix-session-hyprland"
    property real shakeX: 0.0

    // Dynamic Wallpaper source resolution
    FileView {
        id: varTypeView
        path: "/var/cache/onix/wallpaper.type"
        printErrors: false
    }

    FileView {
        id: tmpTypeView
        path: "/tmp/onix/wallpaper.type"
        printErrors: false
    }

    readonly property string wallSource: {
        const envWall = Quickshell.env("ONIX_GREETER_WALLPAPER");
        if (envWall && envWall.length > 0)
            return envWall;

        const vt = varTypeView.text().trim();
        if (vt.length > 0)
            return "/var/cache/onix/" + vt;

        const tt = tmpTypeView.text().trim();
        if (tt.length > 0)
            return "/tmp/onix/" + tt;

        return Qt.resolvedUrl("assets/wallpaper.mp4").toString();
    }
    readonly property bool isVideoWall: wallSource.endsWith(".mp4") || wallSource.endsWith(".mkv") || wallSource.endsWith(".webm")

    // Battery
    readonly property real battPctRaw: UPower.displayDevice?.percentage ?? 0
    readonly property real battPct: battPctRaw > 1 ? battPctRaw : battPctRaw * 100
    readonly property bool battCharging: {
        const s = UPower.displayDevice?.state;
        return s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged;
    }
    readonly property string battIcon: {
        if (battCharging) return "battery_charging_full";
        if (battPct <= 20) return "battery_alert";
        if (battPct <= 40) return "battery_2_bar";
        if (battPct <= 60) return "battery_4_bar";
        if (battPct <= 85) return "battery_5_bar";
        return "battery_full";
    }

    // Live Clock
    property string clockHours: Qt.formatDateTime(new Date(), "HH")
    property string clockMins: Qt.formatDateTime(new Date(), "mm")
    property string clockDate: Qt.formatDateTime(new Date(), "dddd, MMMM d")

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            win.clockHours = Qt.formatDateTime(now, "HH");
            win.clockMins = Qt.formatDateTime(now, "mm");
            win.clockDate = Qt.formatDateTime(now, "dddd, MMMM d");
        }
    }

    // Keyboard handling
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            win.currentPassword = "";
            pwdInput.text = "";
            win.powerMenuOpen = false;
            pwdInput.forceActiveFocus();
        }
    }

    // Shake animation on authentication failure
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: win; property: "shakeX"; from: 0; to: -18; duration: 55; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeX"; from: -18; to: 18; duration: 90; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; from: 18; to: -12; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; from: -12; to: 12; duration: 70; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; from: 12; to: -6; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; from: -6; to: 0; duration: 50; easing.type: Easing.OutQuad }
    }

    function tryLogin(): void {
        if (authenticating || launching)
            return;
        if (currentPassword.length === 0)
            return;

        authenticating = true;
        authFailed = false;

        if (Greetd.available) {
            if (Greetd.state === GreetdState.Inactive) {
                Greetd.createSession(win.username);
            } else {
                Greetd.respond(win.currentPassword);
            }
        } else {
            console.log("[Greeter Test Mode] Simulating auth for user:", win.username);
            simTimer.restart();
        }
    }

    Timer {
        id: simTimer
        interval: 650
        onTriggered: {
            win.authenticating = false;
            if (win.currentPassword === "test" || win.currentPassword.length > 0) {
                console.log("[Greeter Test Mode] Authenticated successfully! Target session:", win.sessionCmd);
                win.launching = true;
                simExitTimer.restart();
            } else {
                win.authFailed = true;
                shakeAnim.restart();
            }
        }
    }

    Timer {
        id: simExitTimer
        interval: 500
        onTriggered: {
            console.log("[Greeter Test Mode] Exiting test window.");
            Qt.quit();
        }
    }

    Timer {
        id: launchTimer
        interval: 220
        onTriggered: {
            Greetd.launch([win.sessionCmd]);
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            console.log("[Greeter Greetd] authMessage:", message, "responseRequired:", responseRequired);
            if (responseRequired && win.currentPassword.length > 0) {
                Greetd.respond(win.currentPassword);
            }
        }

        function onAuthFailure(message: string): void {
            console.log("[Greeter Greetd] authFailure:", message);
            win.authenticating = false;
            win.authFailed = true;
            win.currentPassword = "";
            shakeAnim.restart();
            pwdInput.forceActiveFocus();
            Greetd.cancelSession();
        }

        function onReadyToLaunch(): void {
            console.log("[Greeter Greetd] readyToLaunch! Launching session:", win.sessionCmd);
            win.authenticating = false;
            win.authFailed = false;
            win.launching = true;
            launchTimer.restart();
        }

        function onError(error: string): void {
            console.log("[Greeter Greetd] error:", error);
            win.authenticating = false;
            win.authFailed = true;
            shakeAnim.restart();
        }
    }

    // ==========================================
    // BACKDROP WALLPAPER (Live Video or High-Res Image)
    // ==========================================
    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Image {
        id: bgWallpaper
        anchors.fill: parent
        visible: !win.isVideoWall && win.wallSource.length > 0
        source: visible ? win.wallSource : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        scale: 1.02
        opacity: 0.88
    }

    Loader {
        anchors.fill: parent
        active: win.isVideoWall
        sourceComponent: Component {
            Video {
                anchors.fill: parent
                source: win.wallSource
                fillMode: VideoOutput.PreserveAspectCrop
                muted: true
                loops: MediaPlayer.Infinite
                autoPlay: true
                scale: 1.02
                opacity: 0.88
                onSourceChanged: play()
                Component.onCompleted: play()
            }
        }
    }

    // Frosted dark overlay & soft cinematic vignette
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.04, 0.06, 0.58)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                win.powerMenuOpen = false;
                pwdInput.forceActiveFocus();
            }
        }
    }

    // Center ambient radial glow
    Rectangle {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 20
        width: 600
        height: 420
        radius: 210
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.09)
        opacity: 0.6
    }

    // ==========================================
    // TOP BAR
    // ==========================================
    Item {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 68
        opacity: win.launching ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Brand Pill (Top Left)
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.verticalCenter: parent.verticalCenter
            height: 36
            width: brandRow.implicitWidth + 24
            radius: 18
            color: Theme.glassBg
            border.color: Theme.glassBorder
            border.width: 1

            RowLayout {
                id: brandRow
                anchors.centerIn: parent
                spacing: 8

                OnixLogo {
                    size: 17
                    color: Theme.accent
                }

                Text {
                    text: "ONIX OS"
                    font.family: Theme.fontDisplay
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: Theme.text
                }
            }
        }

        // Status & Power (Top Right)
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            // Battery / Power Pill
            Rectangle {
                height: 36
                implicitWidth: battRow.implicitWidth + 22
                radius: 18
                color: Theme.glassBg
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    id: battRow
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        color: win.battCharging ? Theme.success : Theme.accent
                        text: win.battIcon
                    }

                    Text {
                        font.family: Theme.fontBody
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.text
                        text: (UPower.displayDevice ? Math.round(win.battPct) : 100) + "%"
                    }
                }
            }

            // Power Actions Button
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: win.powerMenuOpen ? Theme.accent : Theme.glassBg
                border.color: win.powerMenuOpen ? Theme.accent : Theme.glassBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: win.powerMenuOpen ? "#060605" : Theme.text
                    text: "power_settings_new"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.powerMenuOpen = !win.powerMenuOpen
                }
            }
        }
    }

    // ==========================================
    // CENTER HERO CONTENT
    // ==========================================
    ColumnLayout {
        id: centerHero
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        spacing: 24
        opacity: win.launching ? 0.0 : 1.0
        scale: win.launching ? 0.94 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Typographic Clock
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Text {
                    text: win.clockHours
                    font.family: Theme.fontDisplay
                    font.pixelSize: 88
                    font.weight: Font.Bold
                    color: Theme.text
                }

                Text {
                    text: ":"
                    font.family: Theme.fontDisplay
                    font.pixelSize: 80
                    font.weight: Font.Light
                    color: Theme.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: win.clockMins
                    font.family: Theme.fontDisplay
                    font.pixelSize: 88
                    font.weight: Font.Bold
                    color: Theme.text
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: win.clockDate
                font.family: Theme.fontBody
                font.pixelSize: 14
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                color: Theme.accent
            }
        }

        // User Avatar & Name
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            // Avatar Ring
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 76
                height: 76
                radius: 38
                color: Theme.glassBg
                border.color: Theme.accent
                border.width: 1.5

                Rectangle {
                    anchors.centerIn: parent
                    width: 66
                    height: 66
                    radius: 33
                    color: Theme.surfaceVariant

                    Text {
                        anchors.centerIn: parent
                        text: win.username.charAt(0).toUpperCase()
                        font.family: Theme.fontDisplay
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        color: Theme.accent
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: win.username.charAt(0).toUpperCase() + win.username.slice(1)
                font.family: Theme.fontDisplay
                font.pixelSize: 19
                font.weight: Font.Bold
                color: Theme.text
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "onix-workstation"
                font.family: Theme.fontBody
                font.pixelSize: 11
                color: Theme.dim
            }
        }

        // Password Input Capsule
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 320
            height: 48
            x: win.shakeX

            Rectangle {
                id: inputCapsule
                anchors.fill: parent
                radius: 24
                color: win.authFailed ? Theme.errorBg : Theme.glassBg
                border.color: win.authFailed ? Theme.error : (pwdInput.activeFocus ? Theme.accent : Theme.glassBorder)
                border.width: pwdInput.activeFocus || win.authFailed ? 1.5 : 1

                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        font.family: Theme.fontIcons
                        text: win.launching ? "lock_open" : "lock"
                        font.pixelSize: 18
                        color: pwdInput.activeFocus ? Theme.accent : Theme.dim
                    }

                    TextInput {
                        id: pwdInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontBody
                        font.pixelSize: 14
                        color: Theme.text
                        echoMode: win.showPassword ? TextInput.Normal : TextInput.Password
                        focus: true
                        clip: true

                        onTextChanged: {
                            win.currentPassword = text;
                            if (win.authFailed)
                                win.authFailed = false;
                        }

                        onAccepted: {
                            win.tryLogin();
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: pwdInput.text.length === 0 && !pwdInput.inputMethodComposing
                            text: "Enter password..."
                            font.family: Theme.fontBody
                            font.pixelSize: 14
                            color: Theme.dim
                        }
                    }

                    // Eye reveal toggle
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: "transparent"
                        visible: pwdInput.text.length > 0 && !win.authenticating

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            text: win.showPassword ? "visibility" : "visibility_off"
                            font.pixelSize: 18
                            color: Theme.dim
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.showPassword = !win.showPassword
                        }
                    }

                    // Action / Submit button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: pwdInput.text.length > 0 ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            text: win.authenticating ? "sync" : "arrow_forward"
                            font.pixelSize: 18
                            color: pwdInput.text.length > 0 ? "#060605" : Theme.dim

                            NumberAnimation on rotation {
                                running: win.authenticating
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 800
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.tryLogin();
                        }
                    }
                }
            }
        }

        // Error message label
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: win.authFailed
            text: "Incorrect password, please try again."
            font.family: Theme.fontBody
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Theme.error
            opacity: win.authFailed ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }

        // Session Choice Pill
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            height: 32
            implicitWidth: sessRow.implicitWidth + 24
            radius: 16
            color: Theme.chipBg
            border.color: Theme.chipBorder
            border.width: 1

            RowLayout {
                id: sessRow
                anchors.centerIn: parent
                spacing: 7

                Text {
                    font.family: Theme.fontIcons
                    text: "desktop_windows"
                    font.pixelSize: 15
                    color: Theme.accent
                }

                Text {
                    text: "Hyprland Session"
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.subtext
                }
            }
        }
    }

    // ==========================================
    // FLOATING POWER ACTION POPUP
    // ==========================================
    Rectangle {
        id: powerMenu
        visible: win.powerMenuOpen
        anchors.top: topBar.bottom
        anchors.topMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 32
        width: 220
        implicitHeight: powerCol.implicitHeight + 24
        radius: 16
        color: Theme.surfaceVariant
        border.color: Theme.glassBorder
        border.width: 1

        // Drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -4
            radius: parent.radius + 2
            color: "#000000"
            opacity: 0.65
        }

        ColumnLayout {
            id: powerCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: "POWER OPTIONS"
                font.family: Theme.fontBody
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1
                color: Theme.dim
                Layout.leftMargin: 8
                Layout.topMargin: 4
            }

            Repeater {
                model: [
                    { label: "Sleep", icon: "bedtime", action: "suspend" },
                    { label: "Restart", icon: "restart_alt", action: "reboot" },
                    { label: "Shut Down", icon: "power_settings_new", action: "poweroff" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 38
                    radius: 10
                    color: actionMouse.containsMouse ? Theme.chipHover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            font.family: Theme.fontIcons
                            text: modelData.icon
                            font.pixelSize: 18
                            color: modelData.action === "poweroff" ? Theme.error : Theme.accent
                        }

                        Text {
                            text: modelData.label
                            font.family: Theme.fontBody
                            font.pixelSize: 13
                            color: modelData.action === "poweroff" ? Theme.error : Theme.text
                        }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.powerMenuOpen = false;
                            if (modelData.action === "suspend") {
                                Quickshell.execDetached(["systemctl", "suspend"]);
                            } else if (modelData.action === "reboot") {
                                Quickshell.execDetached(["systemctl", "reboot"]);
                            } else if (modelData.action === "poweroff") {
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // FOOTER HINT
    // ==========================================
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Press Enter to log in • Tab to navigate • ESC to clear"
        font.family: Theme.fontBody
        font.pixelSize: 11
        color: Theme.dim
        opacity: win.launching ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // Fade to black on successful authentication for a completely seamless handoff
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        z: 9999
        opacity: win.launching ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
        }
    }
}
