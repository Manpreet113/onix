# Helium Browser entry point: versioned upstream tarball -> wrapped binary.
{callPackage}: let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
  callPackage ./helium-browser.nix {
    inherit (sources) version url hash;
  }
