{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.desktop.greetd;
in {
  options.onix.desktop.greetd.enable = mkEnableOption "greetd + tuigreet display manager";

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          # No --cmd: tuigreet offers the wayland-sessions menu (Niri).
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember";
          user = "greeter";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      tuigreet
    ];

    # Disable GDM/GNOME if previously enabled — already removed, but ensure no conflict
    services.displayManager.gdm.enable = mkForce false;
    services.desktopManager.gnome.enable = mkForce false;
  };
}
