# Onix shell (AGS v3 + Astal + Gnim, GTK4): nix owns the package + HM
# module; TSX source lives hand-edited in assets/shell, symlinked live so
# edits apply on `ags run` / `ags request` with no rebuild. Repo must stay
# at ~/onix (out-of-store symlink, same pattern as hypr/modules).
{
  config,
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  astal = inputs.astal.packages.${system};
in {
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  programs.ags = {
    enable = true;

    # Live tree: ~/.config/ags -> repo working tree.
    configDir = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/onix/modules/home/desktop/shell/assets/shell";

    # Astal libs used by windows/*.tsx. Core astal3/astal4/io come from the
    # HM module itself; everything else must be listed here (Nix cannot
    # resolve GObject libs globally).
    extraPackages = [
      astal.battery
      astal.bluetooth
      astal.network
      astal.wireplumber
      astal.hyprland
      astal.tray
      astal.mpris
      astal.notifd
      astal.powerprofiles
      astal.apps
      astal.auth
      astal.brightness
      # Runtime bins available inside the gjs process (execAsync PATH).
      pkgs.brightnessctl
      pkgs.playerctl
      pkgs.pavucontrol
      pkgs.blueman
      pkgs.libnotify
      pkgs.dart-sass
    ];
  };

  # GUI helpers launched from Settings rows — installed for real, not just
  # in the gjs runtime.
  home.packages = with pkgs; [
    pavucontrol
    blueman
  ];
}
