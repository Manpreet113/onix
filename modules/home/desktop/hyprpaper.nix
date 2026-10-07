_: {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = [
        # Use a solid color wallpaper via /run/current-system if no image
        # You can set a custom wallpaper path here: e.g. ~/Pictures/wallpaper.jpg
      ];
      wallpaper = [
        ",#282828"
      ];
    };
  };
}
