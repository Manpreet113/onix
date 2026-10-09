_: {
  # Wallpaper-driven theming: skeind extracts a 12-role palette from the
  # current wallpaper and snapshots it to ~/.cache/skein/theme.json, which
  # Theme.qml reads. The shell pushes explicit selections via `skeinc set`
  # (see WallpaperState.set); the watched dir is only a backstop.
  # Everything outside the shell stays on stylix — no template wars.
  services.skein = {
    enable = true;
    mode = "dark";
    scheme = "tonal";
    wallpaperDir = "~/Pictures/Wallpapers";
  };
}
