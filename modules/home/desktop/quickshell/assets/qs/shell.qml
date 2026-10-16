//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import qs.bar
import qs.chrome
import qs.launcher
import qs.powermenu
import qs.spotlight
import qs.wallpaper

// Onix bar in Quickshell — bar-only milestone.
// Run with: quickshell -c onix
ShellRoot {
    // Pipewire audio props are invalid unless bound through a tracker.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Owns org.freedesktop.Notifications so notify-send keeps working
    // now that AstalNotifd is gone. No UI yet — toasts land with panels.
    NotificationServer {
        id: notifd
    }

    // Binds (SUPER+Space etc.) call `quickshell ipc call onix toggle X`.
    // Stub until panels land: acknowledged, no UI yet.
    IpcHandler {
        function toggle(name: string): void {
            if (name === "wallpaper") {
                if (pickerLoader.item)
                    pickerLoader.item.cancel();
                else
                    WallpaperState.pickerOpen = true;
                return;
            }
            if (name === "launcher") {
                if (spotlightLoader.item)
                    spotlightLoader.item.close();
                else
                    SpotlightState.open = true;
                return;
            }
            if (name === "powermenu") {
                PowerState.open = !PowerState.open;
                return;
            }
            console.log(`[onix] ipc toggle ${name} (no panels yet)`);
        }

        target: "onix"
    }

    Loader {
        id: pickerLoader
        active: WallpaperState.pickerOpen
        sourceComponent: Component {
            Picker {}
        }
    }

    Loader {
        id: fanLoader
        active: LauncherState.open
        sourceComponent: Component {
            Fan {}
        }
    }

    Loader {
        id: spotlightLoader
        active: SpotlightState.open
        sourceComponent: Component {
            Spotlight {}
        }
    }

    Variants {
        model: Quickshell.screens

        Edge {}
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        Frame {}
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }
}
