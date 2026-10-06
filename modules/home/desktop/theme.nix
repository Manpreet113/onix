{
  config,
  lib,
  pkgs,
  ...
}: {
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
    font = {
      name = "Cantarell";
      size = 11;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    GTK_THEME = "adw-gtk3-dark";
  };

  # Dark mode for all apps
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
      font-name = "Cantarell 11";
      document-font-name = "Cantarell 11";
      monospace-font-name = "JetBrainsMono Nerd Font 10";
    };
  };
}
