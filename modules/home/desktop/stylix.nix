_: {
  # Inherits base16Scheme/fonts/opacity from the NixOS stylix module
  stylix.targets = {
    # Keep adw-gtk3 + Papirus + Bibata from theme.nix
    gtk.enable = false;
    qt.enable = false;
    # dconf fonts/theme are managed in theme.nix
    gnome.enable = false;
    # Screenshot-blur background conflicts with stylix's solid background
    hyprlock.enable = false;
    # Solid-color wallpaper stays in hyprpaper.nix
    hyprpaper.enable = false;
    # Custom powerline format with hand-ported nord palette in starship.nix
    starship.enable = false;
    # Nord extension managed in vscode.nix
    vscode.enable = false;
    # wofi is used instead of rofi; avoids deprecated HM rofi.font option
    rofi.enable = false;
  };
}
