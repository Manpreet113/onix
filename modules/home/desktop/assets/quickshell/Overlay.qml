import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Single overlay host for every shell popup (picker, keybinds, …).
// One card, one open/close animation; switching views morphs the content
// in place instead of closing/reopening windows.
PanelWindow {
    id: root

    visible: false
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // currently displayed view: "picker" | "keybinds" | ...
    property string view: ""
    property real contentOpacity: 1

    // fixed per-view card sizes (explicit sizes map reliably; content-driven
    // implicitHeight loops broke window mapping before)
    function dimsFor(name: string): var {
        if (name === "keybinds")
            return { w: 760, h: 600 };
        if (name === "notifs")
            return { w: 760, h: 600 };
        if (name === "power")
            return { w: 560, h: 430 };
        if (name === "launcher")
            return { w: 640, h: 560 };
        if (name === "battery")
            return { w: 520, h: 600 };
        if (name === "bluetooth")
            return { w: 560, h: 520 };
        if (name === "network")
            return { w: 600, h: 560 };
        if (name === "sound")
            return { w: 620, h: 600 };
        if (name === "calendar")
            return { w: 480, h: 560 };
        if (name === "clipboard")
            return { w: 640, h: 560 };
        if (name === "media")
            return { w: 560, h: 480 };
        if (name === "system")
            return { w: 560, h: 580 };
        return { w: 980, h: 780 };
    }

    function show(name: string): void {
        if (!visible) {
            view = name;
            contentOpacity = 1;
            visible = true;
            card.scale = 0.94;
            card.opacity = 0;
            card.scale = 1.0;
            card.opacity = 1.0;
            focusCurrent();
        } else if (name !== view) {
            pendingView = name;
            contentOpacity = 0;
            swapTimer.restart();
        }
    }

    property string pendingView: ""

    function hide(): void {
        visible = false;
        view = "";
    }

    function toggleView(name: string): void {
        if (visible && view === name)
            hide();
        else
            show(name);
    }

    function focusCurrent(): void {
        var item = contentLoader.item;
        if (item && item.focusView)
            item.focusView();
    }

    Timer {
        id: swapTimer
        interval: Theme.fadeFast
        repeat: false
        onTriggered: {
            view = pendingView;
            contentOpacity = 1;
            focusCurrent();
        }
    }

    // NOTE: `quickshell ipc call` does not forward function arguments in
    // 0.3.1, so every entry point is a zero-arg function.
    IpcHandler {
        target: "shell"
        function picker(): void {
            root.show("picker");
        }
        function keybinds(): void {
            root.show("keybinds");
        }
        function notifs(): void {
            root.show("notifs");
        }
        function power(): void {
            root.show("power");
        }
        function launcher(): void {
            root.show("launcher");
        }
        function battery(): void {
            root.show("battery");
        }
        function bluetooth(): void {
            root.show("bluetooth");
        }
        function network(): void {
            root.show("network");
        }
        function sound(): void {
            root.show("sound");
        }
        function calendar(): void {
            root.show("calendar");
        }
        function clipboard(): void {
            root.show("clipboard");
        }
        function media(): void {
            root.show("media");
        }
        function system(): void {
            root.show("system");
        }
        function hide(): void {
            root.hide();
        }
    }

    // legacy aliases (binds call these)
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.toggleView("picker");
        }
    }
    IpcHandler {
        target: "keybinds"
        function toggle(): void {
            root.toggleView("keybinds");
        }
    }
    IpcHandler {
        target: "notifs"
        function toggle(): void {
            root.toggleView("notifs");
        }
    }
    IpcHandler {
        target: "power"
        function toggle(): void {
            root.toggleView("power");
        }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggleView("launcher");
        }
    }
    IpcHandler {
        target: "battery"
        function toggle(): void {
            root.toggleView("battery");
        }
    }
    IpcHandler {
        target: "bluetooth"
        function toggle(): void {
            root.toggleView("bluetooth");
        }
    }
    IpcHandler {
        target: "network"
        function toggle(): void {
            root.toggleView("network");
        }
    }
    IpcHandler {
        target: "sound"
        function toggle(): void {
            root.toggleView("sound");
        }
    }
    IpcHandler {
        target: "calendar"
        function toggle(): void {
            root.toggleView("calendar");
        }
    }
    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            root.toggleView("clipboard");
        }
    }
    IpcHandler {
        target: "media"
        function toggle(): void {
            root.toggleView("media");
        }
    }
    IpcHandler {
        target: "system"
        function toggle(): void {
            root.toggleView("system");
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.hide()
    }
    Shortcut {
        sequence: "Left"
        enabled: root.visible && root.view === "picker"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.move(-1);
        }
    }
    Shortcut {
        sequence: "Right"
        enabled: root.visible && root.view === "picker"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.move(1);
        }
    }
    Shortcut {
        sequence: "Return"
        enabled: root.visible && root.view === "picker"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.apply();
        }
    }
    Shortcut {
        sequence: "1"
        enabled: root.visible && root.view === "power"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.runIndex(0);
        }
    }
    Shortcut {
        sequence: "2"
        enabled: root.visible && root.view === "power"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.runIndex(1);
        }
    }
    Shortcut {
        sequence: "3"
        enabled: root.visible && root.view === "power"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.runIndex(2);
        }
    }
    Shortcut {
        sequence: "4"
        enabled: root.visible && root.view === "power"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.runIndex(3);
        }
    }
    Shortcut {
        sequence: "Left"
        enabled: root.visible && root.view === "calendar"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.prevMonth();
        }
    }
    Shortcut {
        sequence: "Right"
        enabled: root.visible && root.view === "calendar"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.nextMonth();
        }
    }
    Shortcut {
        sequence: "t"
        enabled: root.visible && root.view === "calendar"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.goToday();
        }
    }
    Shortcut {
        sequence: "Space"
        enabled: root.visible && root.view === "media"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.toggle(null);
        }
    }
    Shortcut {
        sequence: "n"
        enabled: root.visible && root.view === "media"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.step(true);
        }
    }
    Shortcut {
        sequence: "p"
        enabled: root.visible && root.view === "media"
        onActivated: {
            if (contentLoader.item)
                contentLoader.item.step(false);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.backdrop
        opacity: root.visible ? 0.55 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.fadeMed
                easing.type: Easing.OutCubic
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: dimsFor(view).w
        height: dimsFor(view).h
        color: Theme.bg
        radius: Theme.radiusLarge
        border.color: Theme.border
        border.width: 1
        clip: true

        Behavior on scale {
            NumberAnimation {
                duration: Theme.openSpring
                easing.type: Easing.OutBack
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.fadeMed
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Theme.openSpring
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Theme.openSpring
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: content
            anchors.fill: parent
            anchors.margins: 20
            opacity: root.contentOpacity
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fadeFast
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                id: contentLoader
                anchors.fill: parent
                sourceComponent: {
                    if (root.view === "picker")
                        return pickerComp;
                    if (root.view === "keybinds")
                        return keybindsComp;
                    if (root.view === "notifs")
                        return notifsComp;
                    if (root.view === "power")
                        return powerComp;
                    if (root.view === "launcher")
                        return launcherComp;
                    if (root.view === "battery")
                        return batteryComp;
                    if (root.view === "bluetooth")
                        return bluetoothComp;
                    if (root.view === "network")
                        return networkComp;
                    if (root.view === "sound")
                        return soundComp;
                    if (root.view === "calendar")
                        return calendarComp;
                    if (root.view === "clipboard")
                        return clipboardComp;
                    if (root.view === "media")
                        return mediaComp;
                    if (root.view === "system")
                        return systemComp;
                    return null;
                }
                onLoaded: {
                    root.focusCurrent();
                    if (item && item.onShown)
                        item.onShown();
                    // views signal this when an action completes
                    // (launch app, apply wallpaper, run power action…)
                    if (item && item.requestClose)
                        item.requestClose.connect(root.hide);
                }

                Component {
                    id: pickerComp
                    PickerView {}
                }
                Component {
                    id: keybindsComp
                    KeybindsView {}
                }
                Component {
                    id: notifsComp
                    NotifsView {}
                }
                Component {
                    id: powerComp
                    PowerView {}
                }
                Component {
                    id: launcherComp
                    LauncherView {}
                }
                Component {
                    id: batteryComp
                    BatteryView {}
                }
                Component {
                    id: bluetoothComp
                    BluetoothView {}
                }
                Component {
                    id: networkComp
                    NetworkView {}
                }
                Component {
                    id: soundComp
                    SoundView {}
                }
                Component {
                    id: calendarComp
                    CalendarView {}
                }
                Component {
                    id: clipboardComp
                    ClipboardView {}
                }
                Component {
                    id: mediaComp
                    MediaView {}
                }
                Component {
                    id: systemComp
                    SystemView {}
                }
            }
        }
    }
}
