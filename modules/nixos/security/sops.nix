{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.security.sops;
in {
  options.onix.security.sops.enable = mkEnableOption "sops-nix secrets management (skeleton)";

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/manpreet/.config/sops/age/keys.txt";

      secrets.example_secret = {
        owner = "manpreet";
      };
    };

    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];
  };
}
