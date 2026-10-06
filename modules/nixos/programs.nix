{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.onix.programs;
in {
  options.onix.programs.enable = mkEnableOption "common system programs";

  config = mkIf cfg.enable {
    programs.firefox.enable = true;

    # Remove nano — use nvim instead
    environment.defaultPackages = with pkgs; [
      # keep minimal
    ];

    environment.systemPackages = with pkgs; [
      vim # keep vim as fallback, nvim is HM; nano explicitly removed
      wget
      curl
      git
      htop
      nh
      nix-output-monitor
      alejandra
      nixd
      nil
    ];

    # Disable nano if it sneaks via defaultPackages
    # We override via environment.defaultPackages = [] is not safe, so ensure nano not installed
    # programs.nano.enable is not an option — just not listing it

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    # Enable dconf for GNOME HM integration
    programs.dconf.enable = true;
  };
}
