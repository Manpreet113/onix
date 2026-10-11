// Settings sheet: links into the pieces Onix owns (theme, audio, displays).
// v1 is a hub — full custom sliders/pages land here incrementally.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { execAsync } from "ags/process";
import { escToHide } from "../services/keys";

const rows: { title: string; sub: string; action: string }[] = [
  { title: "Wallpaper", sub: "Pick + re-theme via skein", action: "ags request -i onix wallpaper" },
  { title: "Quick settings", sub: "Volume, brightness, wifi, bluetooth", action: "ags request -i onix control" },
  { title: "Notifications", sub: "History + do-not-disturb", action: "ags request -i onix notifications" },
  { title: "Audio", sub: "Open pavucontrol", action: "pavucontrol" },
  { title: "Bluetooth", sub: "Open blueman", action: "blueman-manager" },
  { title: "Power", sub: "Suspend, reboot, shutdown", action: "ags request -i onix powermenu" },
];

export default function Settings() {
  const { CENTER } = Astal.WindowAnchor;
  return (
    <window
      name="onix-settings"
      namespace="onix-settings"
      class="Settings"
      visible={false}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={CENTER}
      widthRequest={520}
      $={escToHide}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={10} class="settings-inner">
        <box spacing={8}>
          <label label="Onix settings" class="sheet-title" hexpand halign={Gtk.Align.START} />
          <button label="Close" onClicked={() => app.get_window("onix-settings")?.hide()} />
        </box>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          {rows.map((r) => (
            <button
              class="settings-row"
              onClicked={() => execAsync(["bash", "-c", r.action]).catch((e) => console.error(e))}
            >
              <box spacing={10}>
                <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={0}>
                  <label label={r.title} halign={Gtk.Align.START} class="row-title" />
                  <label label={r.sub} halign={Gtk.Align.START} class="hint" />
                </box>
                <label label="›" class="ico" />
              </box>
            </button>
          ))}
        </box>
        <label label="Shell: AGS v3 + Astal + GTK4 — config lives in ~/onix" class="hint" />
      </box>
    </window>
  );
}
