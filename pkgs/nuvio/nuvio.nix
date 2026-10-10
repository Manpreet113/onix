# Nuvio: upstream linux AppImage, wrapped nixpkgs-style.
# JVM Compose Multiplatform media app bundling its own JRE; the wrap only
# supplies the host graphics/audio/video stack it cannot carry (GTK, X11,
# GL, ALSA, VAAPI). Desktop entry + icons come from inside the AppImage.
{
  lib,
  appimageTools,
  fetchurl,
  alsa-lib,
  libpulseaudio,
  libva,
  expat,
  fontconfig,
  freetype,
  glib,
  gtk3,
  libGL,
  libdrm,
  libgbm,
  libxkbcommon,
  libX11,
  libXext,
  libXi,
  libXrender,
  libXtst,
  libXcursor,
  libXrandr,
  libXfixes,
  libXcomposite,
  libXdamage,
  libxcb,
  zlib,
  wayland,
  version,
  url,
  hash,
  ...
}: let
  appimage = fetchurl {inherit url hash;};
  extracted = appimageTools.extract {
    pname = "nuvio";
    inherit version;
    src = appimage;
  };
in
  appimageTools.wrapType2 {
    pname = "nuvio";
    inherit version;
    src = appimage;

    extraPkgs = pkgs:
      with pkgs; [
        alsa-lib
        libpulseaudio
        libva
        expat
        fontconfig
        freetype
        glib
        gtk3
        libGL
        libdrm
        libgbm
        libxkbcommon
        libX11
        libXext
        libXi
        libXrender
        libXtst
        libXcursor
        libXrandr
        libXfixes
        libXcomposite
        libXdamage
        libxcb
        zlib
        wayland
      ];

    # Upstream AppImage ships Nuvio.desktop + icon but wrapType2 does not
    # install them, so copy them from the extracted tree and wire
    # Exec/Icon at the store paths.
    extraInstallCommands = ''
      mkdir -p $out/share/applications $out/share/icons/hicolor/256x256/apps
      cp ${extracted}/Nuvio.desktop $out/share/applications/nuvio.desktop
      substituteInPlace $out/share/applications/nuvio.desktop \
        --replace-fail "Exec=AppRun %u" "Exec=$out/bin/nuvio %u" \
        --replace-fail "Icon=Nuvio" "Icon=$out/share/icons/hicolor/256x256/apps/nuvio.png"
      cp ${extracted}/Nuvio.png $out/share/icons/hicolor/256x256/apps/nuvio.png
    '';

    meta = {
      description = "Free, open-source media app — bring your own sources";
      homepage = "https://github.com/NuvioMedia/NuvioDesktop";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = "nuvio";
    };
  }
