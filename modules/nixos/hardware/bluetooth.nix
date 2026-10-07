{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.hardware.bluetooth;
in {
  options.onix.hardware.bluetooth.enable = mkEnableOption "Bluetooth stack (bluez + blueman)";

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
    services.blueman.enable = true;

    environment.systemPackages = with pkgs; [
      bluetui
    ];
  };
}
