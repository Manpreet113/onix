// Notification toasts (top-right, auto-expire). Daemon: AstalNotifd.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createBinding } from "ags";
import { useNotifications } from "../services/notifications";
import Notifd from "gi://AstalNotifd";
import GLib from "gi://GLib?version=2.0";

function Toast({ n }: { n: Notifd.Notification }) {
  // NOTE: ags/time timeout() return must be retained (GC cancels it),
  // so use a raw GLib source id here instead.
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 6000, () => {
    console.log(`[onix] toast timeout id=${n.id}`);
    try {
      n.dismiss();
    } catch {
      /* already gone */
    }
    return GLib.SOURCE_REMOVE;
  });
  return (
    <box class="toast" spacing={10} widthRequest={380}>
      {(n.get_image() || n.appIcon) && (
        <box class="app-icon-tile" valign={Gtk.Align.START}>
          <image iconName={n.appIcon || "dialog-information-symbolic"} pixelSize={28} />
        </box>
      )}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={3} hexpand>
        <box spacing={8}>
          <label label={n.appName || "Notification"} class="toast-app" halign={Gtk.Align.START} hexpand />
          <label label={new Date(n.time * 1000).toLocaleTimeString()} class="hint" />
          <button
            label="✕"
            class="toast-x"
            onClicked={() => {
              console.log(`[onix] dismiss clicked id=${n.id}`);
              n.dismiss();
            }}
          />
        </box>
        <label label={n.summary} class="toast-title" halign={Gtk.Align.START} wrap />
        {n.body && <label label={n.body} class="toast-body" halign={Gtk.Align.START} wrap maxWidthChars={48} />}
        {n.get_actions().length > 0 && (
          <box spacing={6}>
            {n.get_actions().map((a) => (
              <button label={a.label} onClicked={() => n.invoke(a.id)} class="toast-act" />
            ))}
          </box>
        )}
      </box>
    </box>
  );
}

export default function Notifications() {
  const { TOP, RIGHT } = Astal.WindowAnchor;
  const { notifd, items } = useNotifications();
  const dnd = createBinding(notifd, "dontDisturb");

  // Imperative render: container diffing (For/With) does not remove
  // children in this stack, so manage the box contents directly.
  // The window itself hides when empty (also keeps an invisible
  // overlay from eating clicks in the corner).
  let listBox: Gtk.Box | null = null;
  const render = () => {
    try {
      if (!listBox) return;
      let child = listBox.get_first_child();
      while (child) {
        const next = child.get_next_sibling();
        listBox.remove(child);
        child = next;
      }
      const arr = dnd() ? [] : items();
      console.log(`[onix] render popups: ${arr.length}`);
      arr.forEach((n) => {
        listBox!.append(Toast({ n }) as unknown as Gtk.Widget);
      });
      const win = app.get_window("onix-notifs");
      if (win) win.visible = arr.length > 0;
    } catch (e) {
      console.error(`[onix] render popups failed: ${e}`);
    }
  };
  items.subscribe(render);
  dnd.subscribe(render);

  return (
    <window
      name="onix-notifs"
      namespace="onix-notifs"
      class="Notifs"
      visible
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      layer={Astal.Layer.OVERLAY}
      application={app}
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
        class="notifs-inner"
        $={(self) => {
          listBox = self as unknown as Gtk.Box;
          render();
        }}
      />
    </window>
  );
}
