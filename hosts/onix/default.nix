{inputs, ...}: {
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
      overlay.enable = true;
      autoUpgrade.enable = true;
    };
    desktop = {
      hyprland.enable = true;
      greetd.enable = true;
      nautilus.enable = true;
      audio.enable = true;
    };
    hardware.intel.enable = true;
    hardware.power.enable = true;
    hardware.bluetooth.enable = true;
    hardware.btrfs.enable = true;
    networking.enable = true;
    printing.enable = true;
    users.enable = true;
    programs.enable = true;
    security.sops.enable = true;
  };
}
