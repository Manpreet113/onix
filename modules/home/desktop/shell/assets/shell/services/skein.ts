// Skein integration: watch ~/.cache/skein/theme.json + gtk.css,
// re-apply shell CSS vars live. Falls back to Nord when skein is absent.
import app from "ags/gtk4/app";
import { monitorFile, readFile } from "ags/file";
import GLib from "gi://GLib?version=2.0";

const HOME = GLib.getenv("HOME") ?? "/home/manpreet";
const THEME_JSON = `${HOME}/.cache/skein/theme.json`;
const GTK_CSS = `${HOME}/.cache/skein/gtk.css`;

function themeJsonToCss(raw: string): string {
  try {
    const j = JSON.parse(raw) as Record<string, string>;
    const pick = (k: string, fb: string) => j[k] ?? j[k.replace(/-/g, "_")] ?? fb;
    const bg = pick("background", "#2e3440");
    const surface = pick("surface", "#3b4252");
    const primary = pick("primary", "#88c0d0");
    const onPrimary = pick("on-primary", "#2e3440");
    const secondary = pick("secondary", "#81a1c1");
    const error = pick("error", "#bf616a");
    const onSurface = pick("on-surface", "#eceff4");
    const muted = pick("outline", "#4c566a");
    return `
:root {
  --onix-bg: ${bg};
  --onix-surface: ${surface};
  --onix-primary: ${primary};
  --onix-on-primary: ${onPrimary};
  --onix-secondary: ${secondary};
  --onix-error: ${error};
  --onix-fg: ${onSurface};
  --onix-muted: ${muted};
}`;
  } catch {
    return "";
  }
}

export function initSkein() {
  const apply = () => {
    try {
      const raw = readFile(THEME_JSON);
      const css = themeJsonToCss(raw);
      if (css) app.apply_css(css);
    } catch {
      // first boot: skein hasn't rendered yet — silent no-op
    }
    // GTK overlay from skein (same file theme.nix imports for gtk3/4)
    try {
      const gtkCss = readFile(GTK_CSS);
      if (gtkCss.trim()) app.apply_css(gtkCss);
    } catch {
      /* noop */
    }
  };

  apply();
  try {
    monitorFile(`${HOME}/.cache/skein`, () => apply());
  } catch {
    /* monitor unavailable — polling fallback below */
  }
  // Backstop: re-apply every 5s in case the monitor misses rapid `skeinc set`.
  const src = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 5, () => {
    apply();
    return GLib.SOURCE_CONTINUE;
  });
  void src;
}
