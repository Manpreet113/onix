{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.onix.hardware.intel;
in {
  options.onix.hardware.intel.enable = mkEnableOption "Intel hardware tweaks";

  config = mkIf cfg.enable {
    hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    hardware.enableRedistributableFirmware = true;
    hardware.graphics.enable = true;
    # Intel GPU tools optional
    environment.systemPackages = with pkgs; [
      intel-gpu-tools
    ];
  };
}
