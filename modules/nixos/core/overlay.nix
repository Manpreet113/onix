{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.onix.core.overlay;
in {
  options.onix.core.overlay.enable = mkEnableOption "onix package overlay (zen-browser, helium-browser)";

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: _: {
        zen-browser = final.callPackage ../../../pkgs/zen-browser {};
        helium-browser = final.callPackage ../../../pkgs/helium-browser {};
      })
    ];
  };
}
