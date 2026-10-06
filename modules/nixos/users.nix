{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.users;
in {
  options.onix.users.enable = mkEnableOption "manpreet user with fish shell";

  config = mkIf cfg.enable {
    users.users.manpreet = {
      isNormalUser = true;
      description = "Manpreet";
      extraGroups = ["networkmanager" "wheel" "video" "audio"];
      shell = pkgs.fish;
      # packages moved to home-manager; keep minimal system packages here
      packages = with pkgs; [
        git
      ];
    };

    # Enable fish system-wide so login shell works even before HM
    programs.fish.enable = true;
  };
}
