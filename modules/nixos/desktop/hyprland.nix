{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.desktop.hyprland;
in {
  options.onix.desktop.hyprland.enable = mkEnableOption "Hyprland Wayland compositor";

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Essential portals for Hyprland
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
    };

    # Polkit for privilege escalation (needed for Hyprland)
    security.polkit.enable = true;

    # Keep gnome-keyring for VSCode/Git credentials (lightweight, no GNOME)
    services.gnome.gnome-keyring.enable = true;

    # XKB layout — Hyprland handles it via input, but keep XKB for tty
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # For Electron apps / Ozone
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
