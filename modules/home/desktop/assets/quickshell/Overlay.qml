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
                    return null;
                }
                onLoaded: {
                    root.focusCurrent();
                    if (item && item.onShown)
                        item.onShown();
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
            }
        }
    }
}
