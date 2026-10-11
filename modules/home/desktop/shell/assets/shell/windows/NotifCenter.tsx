// Notification center (history + DND + clear).
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createBinding } from "ags";
import { escToHide } from "../services/keys";
import { useNotifications } from "../services/notifications";
import Notifd from "gi://AstalNotifd";

function Row({ n }: { n: Notifd.Notification }) {
  return (
    <box class="nc-row" spacing={8}>
      <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={2}>
        <label label={n.summary} class="toast-title" halign={Gtk.Align.START} wrap />
        {n.body && <label label={n.body} class="toast-body" halign={Gtk.Align.START} wrap />}
      </box>
      <button
        label="✕"
        onClicked={() => {
          console.log(`[onix] nc-dismiss clicked id=${n.id}`);
          n.dismiss();
        }}
      />
    </box>
  );
}

export default function NotifCenter() {
  const { TOP, RIGHT, BOTTOM } = Astal.WindowAnchor;
  const { notifd, items } = useNotifications();
  const dnd = createBinding(notifd, "dontDisturb");

  // Imperative render (see Notifications.tsx): container diffing does
  // not remove children in this stack.
  let rowsBox: Gtk.Box | null = null;
  const render = () => {
    try {
      if (!rowsBox) return;
      let child = rowsBox.get_first_child();
      while (child) {
        const next = child.get_next_sibling();
        rowsBox.remove(child);
        child = next;
      }
      items().forEach((n) => {
        rowsBox!.append(Row({ n }) as unknown as Gtk.Widget);
      });
    } catch (e) {
      console.error(`[onix] render nc failed: ${e}`);
    }
  };
  items.subscribe(render);

  return (
    <window
      name="onix-notif-center"
      namespace="onix-notif-center"
      class="NotifCenter"
      visible={false}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={TOP | RIGHT | BOTTOM}
      widthRequest={400}
      $={escToHide}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={10} class="nc-inner">
        <box spacing={8}>
          <label label="Notifications" class="sheet-title" hexpand halign={Gtk.Align.START} />
          <switch
            active={dnd}
            onNotifyActive={({ active }) => {
              if (notifd.dontDisturb !== active) notifd.set_dont_disturb(active);
            }}
          />
          <button label="Clear" onClicked={() => items().forEach((n) => n.dismiss())} />
        </box>
        <scrolledwindow hexpand vexpand maxContentHeight={640}>
          <box
            orientation={Gtk.Orientation.VERTICAL}
            spacing={8}
            $={(self) => {
              rowsBox = self as unknown as Gtk.Box;
              render();
            }}
          />
        </scrolledwindow>
      </box>
    </window>
  );
}
