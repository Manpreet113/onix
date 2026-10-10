{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Import-tree for home modules — auto-imports everything under modules/home
    (inputs.import-tree ../modules/home)
    inputs.nixvim.homeModules.nixvim
    inputs.nix-index-database.homeModules.nix-index
    inputs.nixcord.homeModules.nixcord
    inputs.skein.homeModules.default
  ];

  home.username = "manpreet";
  home.homeDirectory = "/home/manpreet";
  home.stateVersion = "26.05";

  # Align nixvim with our nixpkgs (silences follows warning)
  programs.nixvim.nixpkgs.source = inputs.nixpkgs.outPath;

  # Let Home Manager install itself
  programs.home-manager.enable = true;

  # Ensure font config
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Keep minimal — heavy pkgs are in modules/home/shell/cli.nix
    # Font packages (availability only — stylix is gone, so nothing
    # provides these anymore; font theming left for later)
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  # XDG
  xdg.enable = true;
}
