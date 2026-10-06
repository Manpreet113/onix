{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.core.autoUpgrade;
in {
  options.onix.core.autoUpgrade.enable = mkEnableOption "daily system auto-upgrade from this flake";

  config = mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "/home/manpreet/onix#onix";
      dates = "04:30";
      randomizedDelaySec = "30min";
      allowReboot = false;
    };
  };
}
