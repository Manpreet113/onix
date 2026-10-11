// Notification toasts (top-right, auto-expire). Daemon: AstalNotifd.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createBinding, For, timeout } from "ags";
import Notifd from "gi://AstalNotifd";

function Toast({ n }: { n: Notifd.Notification }) {
  timeout(6000, () => {
    try {
      n.dismiss();
    } catch {
      /* already gone */
    }
  });
  return (
    <box class="toast" spacing={10} widthRequest={380}>
      {(n.get_image() || n.appIcon) && (
        <image iconName={n.appIcon || "dialog-information-symbolic"} pixelSize={32} />
      )}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
        <box spacing={8}>
          <label label={n.appName || "Notification"} class="toast-app" halign={Gtk.Align.START} hexpand />
          <label label={new Date(n.time * 1000).toLocaleTimeString()} class="hint" />
        </box>
        <label label={n.summary} class="toast-title" halign={Gtk.Align.START} wrap />
        {n.body && <label label={n.body} class="toast-body" halign={Gtk.Align.START} wrap maxWidthChars={48} />}
        <box spacing={6}>
          {n.get_actions().map((a) => (
            <button label={a.label} onClicked={() => n.invoke(a.id)} class="toast-act" />
          ))}
          <button label="Dismiss" onClicked={() => n.dismiss()} class="toast-act" />
        </box>
      </box>
    </box>
  );
}

export default function Notifications() {
  const { TOP, RIGHT } = Astal.WindowAnchor;
  const notifd = Notifd.get_default();
  const list = createBinding(notifd, "notifications");

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
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} class="notifs-inner">
        <For each={list}>
          {(n) => <Toast n={n} />}
        </For>
      </box>
    </window>
  );
}
