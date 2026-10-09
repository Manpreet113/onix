import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Session locker: ext-session-lock surface + PAM password auth.
// Engage ONLY via `quickshell --config shell ipc call lock lock`.
// There is deliberately no toggle and no unlock IPC: the session
// unlocks exclusively through a successful password entry.
Scope {
    id: root

    // shared auth state (one per shell, synced across all screens)
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    // typing again clears a previous failure
    onCurrentTextChanged: root.showFailure = false

    function engage(): void {
        root.currentText = "";
        root.showFailure = false;
        root.unlockInProgress = false;
        lock.locked = true;
    }

    function tryUnlock(): void {
        if (root.currentText === "" || root.unlockInProgress)
            return;
        root.unlockInProgress = true;
        pam.start();
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.engage();
        }
    }

    PamContext {
        id: pam
        // "pam/password.conf" next to this file (resolved relative to it)
        configDirectory: "pam"
        config: "password.conf"
        onPamMessage: {
            if (responseRequired)
                respond(root.currentText);
        }
        onError: error => {
            console.log("lock: pam error:", error);
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.currentText = "";
                root.showFailure = false;
                lock.locked = false;
            } else {
                root.currentText = "";
                root.showFailure = true;
            }
            root.unlockInProgress = false;
        }
    }

    WlSessionLock {
        id: lock
        locked: false
        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: root
            }
        }
    }
}
