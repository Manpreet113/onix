{ config, lib, pkgs, inputs, ... }: let
  lucien = pkgs.rustPlatform.buildRustPackage {
    pname = "lucien";
    version = "git";
    src = inputs.lucien;
    cargoLock = {
      # lucien may not have Cargo.lock checked? Try to use vendor
      lockFile = "${inputs.lucien}/Cargo.lock";
    };
    nativeBuildInputs = with pkgs; [pkg-config];
    buildInputs = with pkgs; [
      gtk4
      gtk4-layer-shell
      glib
    ];
  };
in {
  home.packages = [lucien];

  # Ensure lucien is reachable via hyprland bind; already bound in hyprland.nix
  # Optional: xdg desktop entry
  xdg.desktopEntries.lucien = {
    name = "Lucien";
    exec = "${lucien}/bin/lucien";
    comment = "App launcher for Hyprland";
    categories = ["Utility"];
  };
}
