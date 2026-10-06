{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.onix.desktop.nautilus;
in {
  options.onix.desktop.nautilus.enable = mkEnableOption "Nautilus file manager for Hyprland";

  config = mkIf cfg.enable {
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    environment.systemPackages = with pkgs; [
      nautilus
      file-roller
    ];
  };
}
