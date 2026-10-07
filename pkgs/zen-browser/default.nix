# Zen Browser entry point: versioned upstream tarball -> unwrapped -> wrapped.
{
  callPackage,
  firefoxpwa,
}: let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
  callPackage ./zen-browser.nix {
    zen-browser-unwrapped = callPackage ./zen-browser-unwrapped.nix {
      inherit (sources) version firefoxVersion url hash;
    };
    inherit firefoxpwa;
  }
