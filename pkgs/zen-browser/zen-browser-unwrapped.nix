# Zen Browser, unwrapped: upstream linux tarball + patchelf.
# Mirrors youwen5/zen-browser-flake's recipe (wrapFirefox does the rest).
{
  stdenv,
  config,
  wrapGAppsHook3,
  autoPatchelfHook,
  patchelfUnstable,
  adwaita-icon-theme,
  dbus-glib,
  libXtst,
  curl,
  gtk3,
  alsa-lib,
  libva,
  pciutils,
  pipewire,
  writeText,
  fetchurl,
  version,
  firefoxVersion,
  url,
  hash,
  ...
}: let
  policies =
    {
      DisableAppUpdate = true;
    }
    // config.zen.policies or {};

  policiesJson = writeText "firefox-policies.json" (builtins.toJSON {inherit policies;});
in
  stdenv.mkDerivation (finalAttrs: {
    inherit version;
    pname = "zen-browser-unwrapped";
    applicationName = "Zen Browser";

    src = fetchurl {
      inherit url hash;
    };

    nativeBuildInputs = [
      wrapGAppsHook3
      autoPatchelfHook
      patchelfUnstable
    ];

    buildInputs = [
      gtk3
      alsa-lib
      adwaita-icon-theme
      dbus-glib
      libXtst
    ];

    runtimeDependencies = [
      curl
      libva.out
      pciutils
    ];

    appendRunpaths = [
      "${pipewire}/lib"
    ];

    installPhase = ''
      mkdir -p "$prefix/lib/zen-${version}"
      cp -r * "$prefix/lib/zen-${version}"

      mkdir -p $out/bin
      ln -s "$prefix/lib/zen-${version}/zen" $out/bin/zen

      mkdir -p "$out/lib/zen-${version}/distribution"
      ln -s ${policiesJson} "$out/lib/zen-${version}/distribution/policies.json"

      # Icons from the tarball for the wrapFirefox desktop entry (Icon=zen)
      for size in 16 32 48 64 128; do
        mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
        ln -s "$prefix/lib/zen-${version}/browser/chrome/icons/default/default''${size}.png" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/zen.png"
      done
    '';

    patchelfFlags = ["--no-clobber-old-sections"];

    meta = {
      mainProgram = "zen";
      description = "Privacy-focused Firefox-based browser with a vertical tab layout";
    };

    passthru = {
      inherit gtk3 firefoxVersion;

      libName = "zen-${version}";
      binaryName = finalAttrs.meta.mainProgram;

      # Keep both names for compatibility with old and new nixpkgs wrapFirefox.
      gssSupport = true;
      ffmpegSupport = true;
      withGSSAPI = true;
      withFFmpeg = true;
    };
  })
