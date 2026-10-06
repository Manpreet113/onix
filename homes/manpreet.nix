{ config, lib, pkgs, inputs, ... }: {
  imports = [
    # Import-tree for home modules — auto-imports everything under modules/home
    (inputs.import-tree ../modules/home)
  ];

  home.username = "manpreet";
  home.homeDirectory = "/home/manpreet";
  home.stateVersion = "26.05";

  # Let Home Manager install itself
  programs.home-manager.enable = true;

  # Ensure font config
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Keep minimal — heavy pkgs are in modules/home/shell/cli.nix
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  # XDG
  xdg.enable = true;

  # Session vars
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
