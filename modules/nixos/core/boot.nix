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
    boot.loader.systemd-boot.editor = false;
    boot.kernelParams = ["i915.enable_guc=2"];
    zramSwap.enable = true;
  };
}
