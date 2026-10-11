// Wallpaper picker: grid of ~/Pictures/Wallpapers, sets via awww + skein.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createState, createComputed, For } from "ags";
import { execAsync } from "ags/process";
import { escToHide } from "../services/keys";
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
  const rows = createComputed(() => {
    const w = walls();
    const out: string[][] = [];
    for (let i = 0; i < w.length; i += 3) out.push(w.slice(i, i + 3));
    return out;
  });

  const shortName = (p: string) => {
    const base = p.split("/").pop() ?? p;
    const noExt = base.replace(/\.[a-z0-9]+$/i, "");
    return noExt.length > 18 ? `${noExt.slice(0, 17)}…` : noExt;
  };

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
      widthRequest={780}
      $={escToHide}
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
            <For each={rows}>
              {(row) => (
                <box spacing={8} homogeneous>
                  {row.map((w) => (
                    <button class="wall-cell" onClicked={() => setWall(w)}>
                      <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                        <image file={w} pixelSize={112} />
                        <label label={shortName(w)} class="hint" />
                      </box>
                    </button>
                  ))}
                </box>
              )}
            </For>
          </box>
        </scrolledwindow>
        <label label="~/Pictures/Wallpapers — videos (.mp4) play via awww but are hidden here" class="hint" />
      </box>
    </window>
  );
}
