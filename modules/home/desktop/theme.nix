{pkgs, ...}: {
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
    font = {
      name = "Cantarell";
      size = 11;
    };
    # Live wallpaper-driven color overlay (skein renders gtk.css on every
    # theme change; plain adw-gtk3-dark underneath). Missing file at first
    # boot is a silent no-op.
    gtk3.extraCss = ''
      @import url("file:///home/manpreet/.cache/skein/gtk.css");
    '';
    gtk4.extraCss = ''
      @import url("file:///home/manpreet/.cache/skein/gtk.css");
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  home.sessionVariables = {
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
