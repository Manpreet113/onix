import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications

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
            console.log(`[onix] ipc toggle ${name} (no panels yet)`);
        }

        target: "onix"
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
