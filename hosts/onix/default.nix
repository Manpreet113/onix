{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    # Import-tree: auto-import every module under modules/nixos
    (inputs.import-tree ../../modules/nixos)
  ];

  networking.hostName = "onix";

  # Host-specific toggles — enable desired modules
  onix = {
    core = {
      nix.enable = true;
      boot.enable = true;
      nixpkgs.enable = true;
    };
    desktop = {
      gnome.enable = true;
      audio.enable = true;
    };
    hardware.intel.enable = true;
    networking.enable = true;
    printing.enable = true;
    users.enable = true;
    programs.enable = true;
    security.sops.enable = true;
  };

  # Ensure GNOME + GDM are enabled even if module option not yet toggled
  # The modules themselves provide the actual config gated by onix.*.enable
}
