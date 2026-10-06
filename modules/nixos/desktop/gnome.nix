{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.onix.desktop.gnome;
in {
  options.onix.desktop.gnome.enable = mkEnableOption "GNOME desktop with GDM";

  config = mkIf cfg.enable {
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # GNOME keyring, etc. — default enabled with GNOME
    services.gnome.gnome-keyring.enable = true;

    # Exclude some default GNOME bloat if desired (optional, keep minimal)
    environment.gnome.excludePackages = with pkgs; [
      # uncomment to exclude: gnome-tour, epiphany, geary etc.
      # gnome-tour
      # epiphany
    ];

    # Wayland is default in GNOME 50 — no need to set gdm.wayland
  };
}
