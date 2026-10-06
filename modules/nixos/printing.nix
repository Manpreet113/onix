{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.onix.printing;
in {
  options.onix.printing.enable = mkEnableOption "CUPS printing";

  config = mkIf cfg.enable {
    services.printing.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
