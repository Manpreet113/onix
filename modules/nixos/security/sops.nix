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
      # Key must be readable at early boot and outside /home.
      # Install once with: sudo install -m 600 ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
      age.keyFile = "/var/lib/sops-nix/key.txt";

      secrets.example_secret = {
        owner = "manpreet";
      };
    };

    systemd.tmpfiles.rules = ["d /var/lib/sops-nix 0700 root root -"];

    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];
  };
}
