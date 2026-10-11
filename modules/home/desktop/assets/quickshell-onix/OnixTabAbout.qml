// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixTabAbout: system information (ports upstream AboutTab, sysfs +
// gsettings edition).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Column {
    id: root
    spacing: 8
    width: 800

    property string osName: "…"
    property string desktop: "Niri"
    property string hostname: "…"
    property string gtkTheme: "…"
    property string iconTheme: "…"
    property string cpu: "…"
    property string mem: "…"

    Process {
        id: osProc
        command: ["sh", "-c", "grep -m1 PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim();
                if (t !== "")
                    root.osName = t;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: hostProc
        command: ["hostname"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim();
                if (t !== "")
                    root.hostname = t;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: gtkProc
        command: ["dconf", "read", "/org/gnome/desktop/interface/gtk-theme"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim().replace(/^'|'$/g, "");
                if (t !== "")
                    root.gtkTheme = t;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: iconProc
        command: ["dconf", "read", "/org/gnome/desktop/interface/icon-theme"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim().replace(/^'|'$/g, "");
                if (t !== "")
                    root.iconTheme = t;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim();
                if (t !== "")
                    root.cpu = t;
            }
        }
        stderr: StdioCollector {
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "awk '/MemTotal/ {printf \"%.2f GiB\", $2/1024/1024}' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim();
                if (t !== "")
                    root.mem = t;
            }
        }
        stderr: StdioCollector {
        }
    }

    Component.onCompleted: {
        osProc.running = true;
        hostProc.running = true;
        gtkProc.running = true;
        iconProc.running = true;
        cpuProc.running = true;
        memProc.running = true;
    }

    OnixCatLabel {
        icon: ""
        title: "Software"
    }

    OnixSetRow {
        title: "Operating System"
        description: root.osName
        control: Component {
            IconImage {
                width: 30
                height: 30
                source: Quickshell.iconPath("nix-snowflake", "")
            }
        }
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Desktop"
        description: root.desktop
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Hostname"
        description: root.hostname
    }

    OnixCatLabel {
        icon: ""
        title: "Appearance"
    }

    OnixSetRow {
        title: "GTK Theme"
        description: root.gtkTheme
    }

    OnixSep {
    }

    OnixSetRow {
        title: "Icon Theme"
        description: root.iconTheme
    }

    OnixCatLabel {
        icon: ""
        title: "Hardware"
    }

    OnixSetRow {
        title: "CPU"
        description: root.cpu
    }

    OnixSep {
    }

    OnixSetRow {
        title: "RAM"
        description: root.mem
    }
}
