// Powermenu: shutdown / reboot / lock / logout / suspend.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { execAsync } from "ags/process";

const actions: { label: string; icon: string; cmd: string }[] = [
  { label: "Lock", icon: "󰌾", cmd: "hyprlock &" },
  { label: "Logout", icon: "󰗽", cmd: "hyprctl dispatch exit" },
  { label: "Suspend", icon: "󰤄", cmd: "systemctl suspend" },
  { label: "Reboot", icon: "󰜉", cmd: "systemctl reboot" },
  { label: "Shutdown", icon: "⏻", cmd: "systemctl poweroff" },
];

export default function Powermenu() {
  const { CENTER } = Astal.WindowAnchor;
  return (
    <window
      name="onix-powermenu"
      namespace="onix-powermenu"
      class="Powermenu"
      visible={false}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={CENTER}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={12} class="power-inner">
        <label label="Power" class="sheet-title" />
        <box spacing={10}>
          {actions.map((a) => (
            <button
              class={`power-btn ${a.label.toLowerCase()}`}
              onClicked={() => {
                app.get_window("onix-powermenu")?.hide();
                execAsync(["bash", "-c", a.cmd]).catch((e) => console.error(e));
              }}
            >
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                <label label={a.icon} class="power-ico" />
                <label label={a.label} />
              </box>
            </button>
          ))}
        </box>
        <button label="Cancel" onClicked={() => app.get_window("onix-powermenu")?.hide()} />
      </box>
    </window>
  );
}
