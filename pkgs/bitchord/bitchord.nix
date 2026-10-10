# BitChord: upstream linux AppImage, wrapped nixpkgs-style.
# JVM Compose Multiplatform app bundling its own JRE + codecs; the wrap
# only supplies the host graphics/audio stack it cannot carry (GTK, X11,
# GL, ALSA). Desktop entry + icons come from inside the AppImage.
{
  lib,
  appimageTools,
  fetchurl,
  alsa-lib,
  libpulseaudio,
  expat,
  fontconfig,
  freetype,
  glib,
  gtk3,
  libGL,
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
    pname = "bitchord";
    inherit version;
    src = appimage;
  };
in
  appimageTools.wrapType2 {
    pname = "bitchord";
    inherit version;
    src = appimage;

    extraPkgs = pkgs:
      with pkgs; [
        alsa-lib
        libpulseaudio
        expat
        fontconfig
        freetype
        glib
        gtk3
        libGL
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

    # Upstream AppImage ships bitchord.desktop + icon but wrapType2 does
    # not install them, so copy them from the extracted tree and wire
    # Exec/Icon at the store paths.
    extraInstallCommands = ''
      mkdir -p $out/share/applications $out/share/icons/hicolor/256x256/apps
      cp ${extracted}/bitchord.desktop $out/share/applications/bitchord.desktop
      substituteInPlace $out/share/applications/bitchord.desktop \
        --replace-fail "Exec=BitChord" "Exec=$out/bin/bitchord" \
        --replace-fail "Icon=bitchord" "Icon=$out/share/icons/hicolor/256x256/apps/bitchord.png"
      cp ${extracted}/bitchord.png $out/share/icons/hicolor/256x256/apps/bitchord.png
    '';

    meta = {
      description = "Modern YouTube Music client with Apple-Music-inspired aesthetics";
      homepage = "https://github.com/kushagrasinghx/BitChord";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = "bitchord";
    };
  }
