{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.onix.core.boot;
in {
  options.onix.core.boot.enable = mkEnableOption "systemd-boot EFI boot";

  config = mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.kernelParams = [
      "i915.enable_guc=2"
      "quiet"
      "loglevel=3"
      "systemd.show_status=false"
      "rd.udev.log_level=3"
      "vt.global_cursor_default=0"
    ];
    boot.consoleLogLevel = 3;
    boot.initrd.verbose = false;
    zramSwap.enable = true;
  };
}
