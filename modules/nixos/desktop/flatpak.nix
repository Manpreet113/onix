{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.onix.desktop.flatpak;
in {
  options.onix.desktop.flatpak.enable = mkEnableOption "Flatpak with declarative Zen Browser";

  config = mkIf cfg.enable {
    services.flatpak.enable = true;

    # Declarative Flatpak via nix-flatpak module
    services.flatpak = {
      packages = [
        "app.zen_browser.zen"
      ];
      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };

    # Fonts for flatpak
    fonts.fontconfig.enable = true;
  };
}
