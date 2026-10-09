_: {
  # Inherits base16Scheme/fonts/opacity from the NixOS stylix module.
  # Anything skein owns live (ghostty/hyprland/fish/btop/fzf) is disabled
  # here so the two systems never fight; the rest stays static Nord.
  stylix.targets = {
    # Keep adw-gtk3 + Papirus + Bibata from theme.nix (skein only overlays
    # color vars via gtk.css, it does not replace the theme)
    gtk.enable = false;
    qt.enable = false;
    # dconf fonts/theme are managed in theme.nix
    gnome.enable = false;
    # Screenshot-blur background conflicts with stylix's solid background
    hyprlock.enable = false;
    # Custom powerline format with hand-ported nord palette in starship.nix
    starship.enable = false;
    # Nord extension managed in vscode.nix
    vscode.enable = false;
    # nixvim manages colorschemes.nord itself
    neovim.enable = false;
    # --- skein-owned live theming ---
    ghostty.enable = false;
    hyprland.enable = false;
    fish.enable = false;
    btop.enable = false;
    fzf.enable = false;
  };
}
