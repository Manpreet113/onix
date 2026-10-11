// Notification center (history + DND + clear).
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createBinding, For } from "ags";
import Notifd from "gi://AstalNotifd";

export default function NotifCenter() {
  const { TOP, RIGHT, BOTTOM } = Astal.WindowAnchor;
  const notifd = Notifd.get_default();
  const list = createBinding(notifd, "notifications");
  const dnd = createBinding(notifd, "dontDisturb");

  return (
    <window
      name="onix-notif-center"
      namespace="onix-notif-center"
      class="NotifCenter"
      visible={false}
      anchor={TOP | RIGHT | BOTTOM}
      widthRequest={400}
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
          <button label="Clear" onClicked={() => list().forEach((n) => n.dismiss())} />
        </box>
        <scrolledwindow hexpand vexpand maxContentHeight={640}>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            <For each={list}>
              {(n) => (
                <box class="nc-row" spacing={8}>
                  <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={2}>
                    <label label={n.summary} class="toast-title" halign={Gtk.Align.START} wrap />
                    {n.body && <label label={n.body} class="toast-body" halign={Gtk.Align.START} wrap />}
                  </box>
                  <button label="✕" onClicked={() => n.dismiss()} />
                </box>
              )}
            </For>
          </box>
        </scrolledwindow>
      </box>
    </window>
  );
}
