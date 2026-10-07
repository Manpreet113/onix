{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.programs;
in {
  options.onix.programs.enable = mkEnableOption "common system programs";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vim # keep vim as fallback, nvim is HM
      wget
      curl
      git
      nh
      nix-output-monitor
      alejandra
      nixd
      nil
    ];

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };

    programs.dconf.enable = true;
  };
}
