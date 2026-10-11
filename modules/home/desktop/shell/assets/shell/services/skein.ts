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
    // Real skein keys (see ~/.cache/skein/theme.json): background, surface,
    // surface_variant, primary, accent, text, subtext, dim, border, error.
    const bg = j["background"] ?? "#1a1b26";
    const surface = j["surface"] ?? "#24283b";
    const surface2 = j["surface_variant"] ?? "#2b3048";
    const primary = j["accent"] ?? j["primary"] ?? "#7aa2f7";
    const secondary = j["primary"] ?? "#bb9af7";
    const error = j["error"] ?? "#f7768e";
    const fg = j["text"] ?? "#c0caf5";
    const muted = j["dim"] ?? j["subtext"] ?? "#565f89";
    const border = j["border"] ?? "#2b2b2b";
    return `
:root {
  --onix-bg: ${bg};
  --onix-surface: ${surface};
  --onix-surface2: ${surface2};
  --onix-primary: ${primary};
  --onix-on-primary: ${bg};
  --onix-secondary: ${secondary};
  --onix-error: ${error};
  --onix-fg: ${fg};
  --onix-muted: ${muted};
  --onix-border: ${border};
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
