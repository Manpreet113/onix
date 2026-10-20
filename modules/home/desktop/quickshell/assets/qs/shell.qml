//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import qs.theme
import qs.services
import qs.bar
import qs.chrome
import qs.launcher
import qs.powermenu
import qs.spotlight
import qs.wallpaper
import qs.popups
import qs.lock
import qs.screenshot

ShellRoot {
    FontLoader {
        id: pjsBold
        source: "./assets/fonts/PlusJakartaSans-Bold.ttf"
    }
    FontLoader {
        id: pjsExtraBold
        source: "./assets/fonts/PlusJakartaSans-ExtraBold.ttf"
    }
    FontLoader {
        id: outfitFont
        source: "./assets/fonts/Outfit-Variable.ttf"
    }

    // Pipewire audio props are invalid unless bound through a tracker.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Owns org.freedesktop.Notifications and feeds the morphing center island toast
    NotificationServer {
        id: notifd
        onNotification: notif => {
            Notif.push(notif);
        }
    }

    // Binds (SUPER+Space etc.) call `quickshell ipc call onix toggle X`.
    IpcHandler {
        function toggle(name: string): void {
            if (name === "wallpaper") {
                if (pickerLoader.item)
                    pickerLoader.item.cancel();
                else
                    WallpaperState.pickerOpen = true;
                return;
            }
            if (name === "launcher" || name === "spotlight") {
                if (SpotlightState.open && SpotlightState.mode === "all")
                    SpotlightState.open = false;
                else
                    SpotlightState.openWithMode("all");
                return;
            }
            if (name === "clipboard" || name === "clip") {
                if (SpotlightState.open && SpotlightState.mode === "clipboard")
                    SpotlightState.open = false;
                else
                    SpotlightState.openWithMode("clipboard");
                return;
            }
            if (name === "notifications" || name === "notif") {
                if (SpotlightState.open && SpotlightState.mode === "notifications")
                    SpotlightState.open = false;
                else
                    SpotlightState.openWithMode("notifications");
                return;
            }
            if (name === "audio" || name === "network" || name === "wifi" || name === "bluetooth" || name === "battery" || name === "calendar" || name === "media" || name === "power" || name === "powermenu") {
                PopupState.toggle(name === "powermenu" ? "power" : name);
                return;
            }
            if (name === "lock") {
                sessionLock.engage();
                return;
            }
            if (name === "fan" || name === "drawer" || name === "apps") {
                PopupState.toggle("apps");
                return;
            }
            if (name === "screenshot" || name === "snip" || name === "shot") {
                ScreenshotState.toggle();
                return;
            }
            console.log(`[onix] ipc toggle ${name}`);
        }

        function screenshot(): void {
            ScreenshotState.toggle();
        }

        function setSnipRegion(x: real, y: real, w: real, h: real): void {
            ScreenshotState.selX = x;
            ScreenshotState.selY = y;
            ScreenshotState.selW = w;
            ScreenshotState.selH = h;
        }

        function capture(): void {
            ScreenshotState.captureSelection();
        }

        function cancelScreenshot(): void {
            ScreenshotState.cancel();
        }

        function lock(): void {
            sessionLock.engage();
        }

        function brightness(step: string): void {
            Sys.adjustBrightness(step);
        }

        function playPause(): void {
            Media.togglePlay();
        }

        function nextTrack(): void {
            Media.next();
        }

        function prevTrack(): void {
            Media.previous();
        }

        target: "onix"
    }

    Lock {
        id: sessionLock
    }

    Loader {
        id: pickerLoader
        active: WallpaperState.pickerOpen
        sourceComponent: Component {
            Picker {}
        }
    }

    Loader {
        id: spotlightLoader
        active: SpotlightState.open
        sourceComponent: Component {
            Spotlight {}
        }
    }

    ScreenshotOverlay {}
    ScreenshotToast {}

    // Single cohesive top bar dock
    Bar {}
    Wallpaper {}
}
