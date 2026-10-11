// Wallpaper picker: grid of ~/Pictures/Wallpapers, sets via awww + skein.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createState, For } from "ags";
import { execAsync } from "ags/process";
import Gio from "gi://Gio?version=2.0";
import GLib from "gi://GLib?version=2.0";

const WALL_DIR = `${GLib.getenv("HOME") ?? "/home/manpreet"}/Pictures/Wallpapers`;

function listWallpapers(): string[] {
  try {
    const dir = Gio.File.new_for_path(WALL_DIR);
    const en = dir.enumerate_children("standard::name", Gio.FileQueryInfoFlags.NONE, null);
    const out: string[] = [];
    let info = en.next_file(null);
    while (info) {
      const name = info.get_name();
      if (/\.(png|jpe?g|webp|gif)$/i.test(name)) out.push(`${WALL_DIR}/${name}`);
      info = en.next_file(null);
    }
    return out.sort();
  } catch {
    return [];
  }
}

export default function WallpaperPicker() {
  const { CENTER } = Astal.WindowAnchor;
  const [walls, setWalls] = createState<string[]>([]);

  const setWall = (path: string) => {
    const q = path.replace(/'/g, "'\\''");
    execAsync(["bash", "-c", `awww img '${q}' && skeinc set '${q}'`]).catch((e) =>
      console.error(e),
    );
    app.get_window("onix-wallpaper")?.hide();
  };

  return (
    <window
      name="onix-wallpaper"
      namespace="onix-wallpaper"
      class="Wallpaper"
      visible={false}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={CENTER}
      widthRequest={720}
      application={app}
      onShow={() => setWalls(listWallpapers())}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={10} class="wall-inner">
        <box spacing={8}>
          <label label="Wallpaper" class="sheet-title" hexpand halign={Gtk.Align.START} />
          <button label="Close" onClicked={() => app.get_window("onix-wallpaper")?.hide()} />
        </box>
        <scrolledwindow maxContentHeight={480} hexpand vexpand>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            <For each={walls}>
              {(w) => (
                <button class="wall-row" onClicked={() => setWall(w)}>
                  <box spacing={10}>
                    <image file={w} pixelSize={64} />
                    <label label={w.split("/").pop() ?? w} hexpand halign={Gtk.Align.START} />
                    <label label="Set" class="ico" />
                  </box>
                </button>
              )}
            </For>
          </box>
        </scrolledwindow>
        <label label="~/Pictures/Wallpapers — videos (.mp4) play via awww but are hidden here" class="hint" />
      </box>
    </window>
  );
}
