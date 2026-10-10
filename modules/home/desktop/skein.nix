_: {
  # Wallpaper-driven theming: skeind extracts a palette from the
  # current wallpaper and snapshots it to ~/.cache/skein/theme.json, which
  # Theme.qml reads. The shell pushes explicit selections via `skeinc set`
  # (see WallpaperState.set); the watched dir is only a backstop.
  # Skein is the only theming system (stylix was removed); apps without a
  # live source keep their static configs.
  services.skein = {
    enable = true;
    mode = "dark";
    scheme = "tonal";
    wallpaperDir = "~/Pictures/Wallpapers";

    # File placement for apps with no include/source mechanism. Symlinks
    # only, conflicts back up once; none of these paths are HM-managed.
    # Zen profile dir contains a random suffix — stable absent a profile
    # refresh, re-check if chrome ever stops following.
    deploy = {
      enable = true;
      onConflict = "backup";
      targets = {
        "skein.lua" = "~/.config/nvim/colors/skein.lua";
        "skein.theme.css" = "~/.config/Vencord/themes/skein.css";
        "zen-userChrome.css" = "~/.config/zen/ejbelto2.Default Profile/chrome/zen-userChrome.css";
        "skein-color-theme.json" = "~/.vscode/extensions/skein-theme/skein-color-theme.json";
      };
    };
  };
}
