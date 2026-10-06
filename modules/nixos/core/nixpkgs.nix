{ config, lib, pkgs, inputs, ... }:
with lib; let
  cfg = config.onix.core.nixpkgs;
in {
  options.onix.core.nixpkgs.enable = mkEnableOption "nixpkgs overlays and allowUnfree";

  config = mkIf cfg.enable {
    nixpkgs = {
      overlays = [
        (import ../../../overlays/default.nix {inherit inputs;})
      ];
      config = {
        allowUnfree = true;
      };
    };
  };
}
