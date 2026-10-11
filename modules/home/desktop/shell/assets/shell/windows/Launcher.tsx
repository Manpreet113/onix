// App launcher (replaces wofi SUPER+SPACE). Fuzzy over AstalApps.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createState, createComputed, For } from "ags";
import Apps from "gi://AstalApps";

export default function Launcher() {
  const { CENTER } = Astal.WindowAnchor;
  const apps = new Apps.Apps();
  const [query, setQuery] = createState("");

  const filtered = createComputed(() => {
    const q = query().toLowerCase().trim();
    const list = apps.fuzzy_query("");
    if (!q) return list.slice(0, 9);
    return apps.fuzzy_query(q).slice(0, 9);
  });

  const launch = (a: Apps.Application) => {
    app.get_window("onix-launcher")?.hide();
    setQuery("");
    a.launch();
  };

  return (
    <window
      name="onix-launcher"
      namespace="onix-launcher"
      class="Launcher"
      visible={false}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={CENTER}
      widthRequest={560}
      application={app}
      onShow={() => setQuery("")}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} class="launcher-inner">
        <entry
          placeholderText="Type to search apps…"
          text={query}
          onNotifyText={({ text }) => setQuery(text)}
          onActivate={() => {
            const first = filtered()[0];
            if (first) launch(first);
          }}
        />
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <For each={filtered}>
            {(a) => (
              <button class="app-row" onClicked={() => launch(a)}>
                <box spacing={10}>
                  <image iconName={a.iconName} pixelSize={28} />
                  <box orientation={Gtk.Orientation.VERTICAL} spacing={0} hexpand>
                    <label label={a.name} halign={Gtk.Align.START} class="app-name" />
                    <label
                      label={a.description || a.entry || ""}
                      halign={Gtk.Align.START}
                      class="app-desc"
                      ellipsize={3}
                    />
                  </box>
                  <label label="⏎" class="ico" />
                </box>
              </button>
            )}
          </For>
        </box>
        <box spacing={8} halign={Gtk.Align.END}>
          <label label="esc to close" class="hint" />
          <button
            label="Close"
            onClicked={() => app.get_window("onix-launcher")?.hide()}
          />
        </box>
      </box>
    </window>
  );
}
