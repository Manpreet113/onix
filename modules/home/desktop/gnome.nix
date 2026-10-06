{ config, lib, pkgs, ... }: {
  # GNOME HM dconf settings
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-show-weekday = true;
      enable-hot-corners = false;
      font-name = "Cantarell 11";
      document-font-name = "Cantarell 11";
      monospace-font-name = "JetBrainsMono Nerd Font 10";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:close";
      titlebar-font = "Cantarell Bold 11";
    };
    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = true;
      workspaces-only-on-primary = true;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "org.gnome.Terminal.desktop"
        "code.desktop"
        "ghostty.desktop"
      ];
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      natural-scroll = true;
    };
    "org/gnome/desktop/session" = {
      idle-delay = 0; # never suspend automatically (optional)
    };
  };

  # GNOME extensions via HM (optional)
  # home.packages with extensions:
  home.packages = with pkgs.gnomeExtensions; [
    appindicator
    dash-to-panel
    # add more as desired
  ];
}
