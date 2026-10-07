# Helium Browser: upstream linux binary tarball, wrapped nixpkgs-style.
# Recipe follows nixpkgs' brave/make-brave.nix (binary Chromium pattern).
# The tarball ships no chrome-sandbox, so it relies on unprivileged user
# namespaces (enabled on NixOS); --no-sandbox is the fallback, not the default.
{
  lib,
  stdenv,
  fetchurl,
  patchelf,
  makeWrapper,
  glib,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  adwaita-icon-theme,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  libx11,
  libGL,
  libxkbcommon,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libdrm,
  libuuid,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  libpulseaudio,
  libva,
  udev,
  wayland,
  libxcb,
  zlib,
  snappy,
  libkrb5,
  xdg-utils,
  coreutils,
  qt5,
  qt6,
  version,
  url,
  hash,
  ...
}: let
  inherit (lib) makeLibraryPath makeBinPath;

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libx11
    libGL
    libxkbcommon
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libuuid
    libgbm
    nspr
    nss
    pango
    pipewire
    libpulseaudio
    libva
    udev
    wayland
    libxcb
    zlib
    snappy
    libkrb5
  ];

  # Qt base dirs as plain store paths (NOT in buildInputs: the Qt setup hooks
  # refuse mixed Qt5+Qt6 closures, and we only need the paths for rpath)

  rpath = makeLibraryPath deps + ":${qt5.qtbase}/lib:${qt6.qtbase}/lib";
  binpath = makeBinPath deps;
in
  stdenv.mkDerivation {
    pname = "helium-browser";
    inherit version;

    src = fetchurl {inherit url hash;};
    sourceRoot = "helium-${version}-x86_64_linux";

    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [
      patchelf
      makeWrapper
    ];

    buildInputs =
      [
        glib
        gsettings-desktop-schemas
        gtk3
        gtk4
        adwaita-icon-theme
      ]
      # Full dep closure here so autoPatchelfHook can resolve every .so
      ++ deps;

    installPhase = ''
      runHook preInstall

      mkdir -p $out $out/bin
      mkdir -p $out/opt/helium
      cp -R . $out/opt/helium

      # Fix interpreter + rpath on the executables (bundled .so files
      # resolve transitively through the executable's RUNPATH; patchelf'ing
      # them is unnecessary)
      for exe in $out/opt/helium/helium $out/opt/helium/helium_crashpad_handler; do
        patchelf \
          --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath "${rpath}" $exe
      done

      # Fix interpreter path in the upstream wrapper script (kept for
      # reference; the actual launcher below bypasses its $HERE logic,
      # which is incompatible with store wrapping)
      substituteInPlace $out/opt/helium/helium-wrapper \
        --replace-fail /bin/sh ${stdenv.shell}
      # Launcher: wrap the ELF directly. (Wrapping the upstream
      # helium-wrapper script instead would self-exec: its
      # `exec $HERE/helium` resolves back to the wrapper.)
      # (wrapper invocation below)

      # Desktop file + icon from the tarball
      mkdir -p $out/share/applications
      cp $out/opt/helium/helium.desktop $out/share/applications/helium.desktop
      substituteInPlace $out/share/applications/helium.desktop \
        --replace-fail "Exec=helium" "Exec=$out/bin/helium"
      mkdir -p $out/share/icons/hicolor/256x256/apps
      ln -s $out/opt/helium/product_logo_256.png \
        $out/share/icons/hicolor/256x256/apps/helium.png

      # Prefer store xdg helpers over the bundled scripts
      ln -sf ${xdg-utils}/bin/xdg-settings $out/opt/helium/xdg-settings
      ln -sf ${xdg-utils}/bin/xdg-mime $out/opt/helium/xdg-mime

      # Manual wrapper (wrapGAppsHook refuses mixed Qt5+Qt6 dep closures;
      # both shim sets ship in the tarball). Mirrors its env handling.
      makeWrapper $out/opt/helium/helium $out/bin/helium \
        --set CHROME_VERSION_EXTRA custom \
        --set CHROME_WRAPPER $out/bin/helium \
        --prefix LD_LIBRARY_PATH : ${rpath} \
        --prefix PATH : ${binpath} \
        --suffix PATH : ${lib.makeBinPath [xdg-utils coreutils]} \
        --prefix XDG_DATA_DIRS : "${adwaita-icon-theme}/share:${gsettings-desktop-schemas}/share:${gtk3}/share:${gtk4}/share:${glib}/share" \
        --set GSETTINGS_SCHEMAS_PATH "${glib}/share/gsettings-schemas/${glib.name}:${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}:${gtk4}/share/gsettings-schemas/${gtk4.name}" \
        --prefix QT_PLUGIN_PATH : "${qt5.qtbase}/${qt5.qtbase.qtPluginPrefix}:${qt6.qtbase}/${qt6.qtbase.qtPluginPrefix}" \
        --add-flags "--disable-features=OutdatedBuildDetector" \
        --add-flags "''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"

      runHook postInstall
    '';

    installCheckPhase = ''
      $out/opt/helium/helium --version
    '';

    meta = {
      description = "Private, fast and honest Chromium-based web browser";
      homepage = "https://github.com/imputnet/helium";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = "helium";
    };
  }
