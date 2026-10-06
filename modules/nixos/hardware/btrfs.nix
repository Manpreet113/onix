{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.hardware.btrfs;
in {
  options.onix.hardware.btrfs.enable = mkEnableOption "btrfs maintenance and btrbk snapshots";

  config = mkIf cfg.enable {
    services.btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = ["/"];
    };

    services.fstrim.enable = true;

    # Snapshot dir must exist before btrbk runs
    systemd.tmpfiles.rules = [
      "d /btrbk_snapshots 0755 root root -"
    ];

    services.btrbk.instances."home" = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "2d";
        snapshot_preserve = "24h 7d 4w";
        volume."/" = {
          snapshot_dir = "btrbk_snapshots";
          subvolume = {
            home = {};
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      btrbk
      compsize
      btdu
    ];
  };
}
