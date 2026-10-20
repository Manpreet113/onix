import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Session Locker Singleton Scope: controls ext-session-lock + PAM authentication.
Scope {
    id: root

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool unlockSuccessAnim: false

    onCurrentTextChanged: {
        root.showFailure = false;
    }

    function engage(): void {
        root.currentText = "";
        root.showFailure = false;
        root.unlockInProgress = false;
        root.unlockSuccessAnim = false;
        lock.locked = true;
    }

    function tryUnlock(): void {
        if (root.currentText.length === 0 || root.unlockInProgress)
            return;
        root.unlockInProgress = true;
        root.showFailure = false;
        pam.start();
    }

    function finishUnlock(): void {
        lock.locked = false;
        root.currentText = "";
        root.unlockInProgress = false;
        root.unlockSuccessAnim = false;
        root.showFailure = false;
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.engage();
        }
        function unlock(): void {
            root.finishUnlock();
        }
    }

    PamContext {
        id: pam
        configDirectory: Qt.resolvedUrl("../pam").toString().replace("file://", "")
        config: "password.conf"
        user: Quickshell.env("USER") || "manpreet"

        onPamMessage: {
            if (responseRequired)
                respond(root.currentText);
        }

        onError: error => {
            console.log("[Lock] PAM error:", error);
            root.unlockInProgress = false;
            root.showFailure = true;
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.showFailure = false;
                root.unlockInProgress = false;
                root.unlockSuccessAnim = true;
            } else {
                root.currentText = "";
                root.showFailure = true;
                root.unlockInProgress = false;
            }
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
