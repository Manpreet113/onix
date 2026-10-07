{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.onix.core.nixpkgs;
in {
  options.onix.core.nixpkgs.enable = mkEnableOption "nixpkgs settings";

  config = mkIf cfg.enable {
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
