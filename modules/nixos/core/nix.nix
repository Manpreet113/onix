{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.onix.core.nix;
in {
  options.onix.core.nix.enable = mkEnableOption "Nix flake settings and GC";

  config = mkIf cfg.enable {
    nix = {
      package = pkgs.nixVersions.stable;

      settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        trusted-users = ["root" "@wheel"];
        substituters = ["https://cache.nixos.org/"];
        trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
        warn-dirty = false;
      };

      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 7d";
      };

      optimise.automatic = true;
    };
  };
}
