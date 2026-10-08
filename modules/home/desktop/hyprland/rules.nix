_: {
  wayland.windowManager.hyprland = {
    settings = {
      window_rule = [
        {
          match.class = "^(org.gnome.Nautilus)$";
          float = true;
        }
        {
          match.class = "^(pavucontrol)$";
          float = true;
          size = "800 600";
          center = true;
        }
        {
          match.class = "^(blueman-manager)$";
          float = true;
          size = "800 600";
          center = true;
        }
        {
          match.title = "^(Picture-in-Picture)$";
          float = true;
        }
      ];
    };
  };
}
