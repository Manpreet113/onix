// Onix shell — AGS v3 (Astal + Gnim) on GTK4.
// Entry point: instantiates every window, exposes `ags request` commands.
// NOTE: keep all `get_default()` calls inside main()/components (client-safe).

import app from "ags/gtk4/app";
import style from "./style.scss";
import Bar from "./windows/Bar";
import Launcher from "./windows/Launcher";
import ControlCenter from "./windows/ControlCenter";
import Notifications from "./windows/Notifications";
import NotifCenter from "./windows/NotifCenter";
import OSD from "./windows/OSD";
import Powermenu from "./windows/Powermenu";
import WallpaperPicker from "./windows/WallpaperPicker";
import Settings from "./windows/Settings";
import { initSkein } from "./services/skein";

app.start({
  instanceName: "onix",
  css: style,
  requestHandler(argv, response) {
    console.log(`[onix] request: ${JSON.stringify(argv)}`);
    const [cmd = "", arg = "", ...rest] = argv;
    const win = (name: string) => app.get_window(name);
    const toggle = (name: string) => {
      const w = win(name);
      if (w) {
        w.visible = !w.visible;
        console.log(`[onix] ${name} -> ${w.visible ? "visible" : "hidden"}`);
        response(w.visible ? "visible" : "hidden");
      } else {
        response(`no window: ${name}`);
      }
    };

    switch (cmd) {
      case "launcher":
        toggle("onix-launcher");
        break;
      case "control":
        toggle("onix-control");
        break;
      case "notifications":
        toggle("onix-notif-center");
        break;
      case "powermenu":
        toggle("onix-powermenu");
        break;
      case "wallpaper":
        toggle("onix-wallpaper");
        break;
      case "settings":
        toggle("onix-settings");
        break;
      case "osd":
        // e.g. `ags request osd volume` — OSD service listens via polling,
        // this just ensures the window exists.
        toggle("onix-osd");
        break;
      case "state":
        // Live introspection: `ags request -i onix state` then read the log.
        (async () => {
          try {
            const { default: Network } = await import("gi://AstalNetwork");
            const { default: Bluetooth } = await import("gi://AstalBluetooth");
            const { default: Notifd } = await import("gi://AstalNotifd");
            const wifi = Network.get_default().wifi;
            console.log(
              `[onix] state wifi=${wifi && wifi.enabled} bt=${Bluetooth.get_default().isPowered} dnd=${Notifd.get_default().dontDisturb}`,
            );
            response("logged");
          } catch (e) {
            response(`state failed: ${e}`);
          }
        })();
        break;
      case "lock":
        // Hyprlock stays the source of truth for v1 (see Powermenu).
        // `arg` reserved for future astal-auth lockscreen.
        import("ags/process").then(({ execAsync }) =>
          execAsync(["bash", "-c", "hyprlock &"])
            .then(() => response("locking"))
            .catch((e) => response(`lock failed: ${e}`)),
        );
        break;
      case "wallpaper-set":
        // `ags request wallpaper-set /path/to/img`
        import("ags/process").then(({ execAsync }) => {
          const img = arg || rest.join(" ");
          if (!img) return response("usage: wallpaper-set <path>");
          execAsync(["bash", "-c", `awww img '${img.replace(/'/g, "'\\''")}' && skeinc set '${img.replace(/'/g, "'\\''")}'`])
            .then(() => response("ok"))
            .catch((e) => response(`failed: ${e}`));
        });
        break;
      default:
        if (cmd) toggle(cmd);
        else response("onix: launcher|control|notifications|powermenu|wallpaper|settings|lock");
        break;
    }
  },
  main() {
    initSkein(style);
    Bar();
    Launcher();
    ControlCenter();
    Notifications();
    NotifCenter();
    OSD();
    Powermenu();
    WallpaperPicker();
    Settings();
  },
});
