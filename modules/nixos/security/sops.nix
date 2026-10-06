{ config, lib, pkgs, inputs, ... }:
with lib; let
  cfg = config.onix.security.sops;
in {
  options.onix.security.sops.enable = mkEnableOption "sops-nix secrets management (skeleton)";

  config = mkIf cfg.enable {
    # sops-nix skeleton — no secrets yet.
    # To use:
    # 1. Generate age key: age-keygen -o ~/.config/sops/age/keys.txt
    # 2. Add public key to .sops.yaml
    # 3. Create secrets/secrets.yaml via `sops secrets/secrets.yaml`
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/manpreet/.config/sops/age/keys.txt";
      # age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Example secret (commented):
      # secrets.example = { };
    };

    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];
  };
}
