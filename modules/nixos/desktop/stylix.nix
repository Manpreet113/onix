{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.desktop.stylix;
in {
  options.onix.desktop.stylix.enable = mkEnableOption "stylix system-wide theming (nord)";

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
      polarity = "dark";

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
        sansSerif = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };
        serif = {
          package = pkgs.noto-fonts;
          name = "Noto Serif";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };

      opacity.terminal = 0.95;
    };
  };
}
