{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.hardware.intel;
in {
  options.onix.hardware.intel.enable = mkEnableOption "Intel hardware tweaks";

  config = mkIf cfg.enable {
    hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    hardware.enableRedistributableFirmware = true;
    hardware.graphics.enable = true;
    # VAAPI (intel-media-driver) for hardware video decode, e.g. quickshell
    # live wallpapers; also exposes intel_gpu_top to user services
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
    # Intel GPU tools optional
    environment.systemPackages = with pkgs; [
      intel-gpu-tools
    ];
  };
}
