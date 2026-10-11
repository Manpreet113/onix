// App launcher (replaces wofi SUPER+SPACE). Fuzzy over AstalApps.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createState, createComputed, For } from "ags";
import { escToHide, onKeys, Gdk } from "../services/keys";
import Apps from "gi://AstalApps";

export default function Launcher() {
  const { TOP } = Astal.WindowAnchor;
  const apps = new Apps.Apps();
  const [query, setQuery] = createState("");
  const [sel, setSel] = createState(0);
  query.subscribe(() => setSel(0));

  const filtered = createComputed(() => {
    const q = query().toLowerCase().trim();
    const list = apps.fuzzy_query("");
    if (!q) return list.slice(0, 9);
    return apps.fuzzy_query(q).slice(0, 9);
  });

  const launch = (a: Apps.Application) => {
    app.get_window("onix-launcher")?.hide();
    setQuery("");
    setSel(0);
    a.launch();
  };

  const launchSelected = () => {
    const list = filtered();
    const target = list[sel()] ?? list[0];
    if (target) launch(target);
  };

  return (
    <window
      name="onix-launcher"
      namespace="onix-launcher"
      class="Launcher"
      visible={false}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={TOP}
      widthRequest={680}
      $={(self) => {
        escToHide(self);
        onKeys(self, (keyval) => {
          if (keyval === Gdk.KEY_Up) {
            setSel((s) => Math.max(0, s - 1));
            return true;
          }
          if (keyval === Gdk.KEY_Down) {
            setSel((s) => Math.min(Math.max(0, filtered().length - 1), s + 1));
            return true;
          }
          return false;
        });
      }}
      application={app}
      onShow={() => {
        setQuery("");
        setSel(0);
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} class="launcher-inner">
        <box spacing={8} class="launcher-head">
          <label label="✦ SPOTLIGHT" class="launcher-title" hexpand halign={Gtk.Align.START} />
          <label label={filtered((l) => `${l.length} results · ↑↓ navigate · ⏎ launch`)} class="hint" />
        </box>
        <entry
          placeholderText="Type to search apps…"
          text={query}
          onNotifyText={({ text }) => setQuery(text)}
          onActivate={launchSelected}
        />
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4} class="app-list">
          <For each={filtered}>
            {(a, index) => (
              <button
                class={createComputed(() =>
                  index() === sel() ? "app-row selected" : "app-row",
                )}
                onClicked={() => launch(a)}
              >
                <box spacing={10}>
                  <box class="app-icon-tile">
                    <image iconName={a.iconName} pixelSize={28} />
                  </box>
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
