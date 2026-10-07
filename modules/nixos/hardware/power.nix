{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.onix.hardware.power;
in {
  options.onix.hardware.power.enable = mkEnableOption "UPower battery service and power-profiles-daemon";

  config = mkIf cfg.enable {
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
  };
}
