{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Common host configuration — shared between all hosts.
  # Uses import-tree to auto-import modules under modules/nixos if needed,
  # but we explicitly import via hosts/onix for clarity.

  time.timeZone = lib.mkDefault "Asia/Kolkata";

  i18n.defaultLocale = lib.mkDefault "en_IN";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Internationalisation for GNOME
  console.keyMap = lib.mkDefault "us";

  system.stateVersion = "26.05";
}
