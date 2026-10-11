# Niri Wayland compositor (replaces modules/nixos/desktop/hyprland.nix).
# The session itself is home-manager managed (wayland.windowManager.niri,
# which ships systemd units, portals, and xwayland-satellite); this module
# covers the system-level pieces: session entries for the greeter, portals,
# polkit, credentials, and environment.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.desktop.niri;
in {
  options.onix.desktop.niri.enable = mkEnableOption "Niri Wayland compositor";

  config = mkIf cfg.enable {
    # Session entries (niri.desktop) + binary on PATH for the greeter.
    environment.systemPackages = with pkgs; [
      niri
    ];

    # Essential portals for Niri (gnome portal comes from the HM module).
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    # Polkit for privilege escalation.
    security.polkit.enable = true;

    # Keep gnome-keyring for VSCode/Git credentials (lightweight, no GNOME).
    services.gnome.gnome-keyring.enable = true;

    # XKB layout for tty.
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    environment.sessionVariables = {
      # For Electron apps / Ozone.
      NIXOS_OZONE_WL = "1";
      # Cursor theme inside the Niri session (HM gtk cursor covers apps).
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "24";
    };
  };
}
