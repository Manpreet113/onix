# BitChord entry point: versioned upstream AppImage -> wrapped binary.
{callPackage}: let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
  callPackage ./bitchord.nix {
    inherit (sources) version url hash;
  }
