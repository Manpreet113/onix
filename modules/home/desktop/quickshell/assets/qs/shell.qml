import Quickshell
import Quickshell.Services.Pipewire

// Onix bar in Quickshell — bar-only milestone.
// Run with: quickshell -c onix
ShellRoot {
    // Pipewire audio props are invalid unless bound through a tracker.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
