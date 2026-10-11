# Stock Exo desktop shell on Ignis (upstream: github:debuggyo/Exo).
#
# Strategy: pinned upstream source, one documented compat patch for
# matugen 4 (see exo-matugen4.patch), deployed as WRITABLE copies under
# ~/.config/ignis (Exo mutates user_settings.json + colors.scss at
# runtime, so a read-only store symlink cannot work). Activation refreshes
# code + templates every switch but never touches user state. Theming comes
# from matugen (Exo stock); skein keeps covering terminal/apps untouched.
{
  lib,
  pkgs,
  inputs,
  ...
}: let
  exoRev = "d8ca44a3c4e71777ec70eef3f886b3fdd0b5f614";
  exoSrc = pkgs.fetchFromGitHub {
    owner = "debuggyo";
    repo = "Exo";
    rev = exoRev;
    hash = "sha256-080NIKZa8GhNNMAF7wmUkORetSd4NraPAOIcLw0cgAk=";
  };

  # Upstream tree + the matugen-4 compat patch, as a writable source for
  # the activation script below.
  exoPatched = pkgs.runCommand "exo-config" {
    nativeBuildInputs = [pkgs.patch];
  } ''
    mkdir -p $out
    cp -r ${exoSrc}/ignis $out/ignis
    chmod -R u+w $out/ignis
    patch -p1 -d $out -i ${./exo-matugen4.patch}
  '';

  # awww renamed swww's binaries; Exo + matugen call `swww` /
  # `swww-daemon`. This compat wrapper translates the one flag matugen
  # passes that awww dropped (--transition-type) and forwards the rest.
  swwwBin = pkgs.writeShellScriptBin "swww" ''
    if [ "$1" = "img" ]; then
      shift
      args=()
      skip=0
      for a in "$@"; do
        if [ "$skip" = 1 ]; then skip=0; continue; fi
        case "$a" in
          --transition-type|--transition-step|--transition-duration|--transition-fps|--transition-angle|--transition-pos|--transition-bezier) skip=1 ;;
          --transition-type=*|--transition-step=*|--transition-duration=*|--transition-fps=*|--transition-angle=*|--transition-pos=*|--transition-bezier=*) ;;
          *) args+=("$a") ;;
        esac
      done
      exec ${pkgs.awww}/bin/awww img "''${args[@]}"
    else
      exec ${pkgs.awww}/bin/awww "$@"
    fi
  '';
  swwwCompat = pkgs.symlinkJoin {
    name = "swww-compat";
    paths = [swwwBin pkgs.awww];
    postBuild = ''
      ln -s ${pkgs.awww}/bin/awww-daemon $out/bin/swww-daemon
    '';
  };
in {
  programs.ignis = {
    enable = true;
    services.audio.enable = true;
    services.network.enable = true;
    services.bluetooth.enable = true;
    sass.enable = true;
    sass.useDartSass = true;
  };

  # programs.ignis (ignis HM module) installs the final wrapped package
  # itself; listing it here too would collide in home.packages.
  home.packages = with pkgs; [
    matugen
    awww
    swwwCompat
    hyprlock
    gnome-bluetooth
  ];

  # Trimmed matugen setup (Exo stock otherwise): wallpaper engine +
  # shell colors + hyprlock theming. GTK/kitty/qt/vscode templates are
  # deliberately absent — skein owns GTK, ghostty is static, no Hyprland.
  xdg.configFile."matugen/config.toml".text = ''
    [config.wallpaper]
    command = "${swwwCompat}/bin/swww"
    arguments = ["img", "--transition-type", "simple"]
    set = true

    [templates.ignis]
    input_path = './templates/colors.scss'
    output_path = '~/.config/ignis/colors.scss'

    [templates.hyprlock]
    input_path = './templates/hyprlock.conf'
    output_path = '~/.config/hypr/hyprlock.conf'
  '';

  home.activation.exoSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    EXO="$HOME/.config/ignis"
    SRC="${exoPatched}/ignis"
    mkdir -p "$EXO" "$HOME/.config/matugen/templates" "$HOME/.config/hypr"
    for d in modules scripts styles; do
      rm -rf "$EXO/$d"
      cp -r "$SRC/$d" "$EXO/$d"
      chmod -R u+w "$EXO/$d"
    done
    cp "$SRC/config.py" "$SRC/user_settings.py" "$EXO/"
    chmod u+w "$EXO/config.py" "$EXO/user_settings.py"
    [ -f "$EXO/user_settings.json" ] || echo '{}' > "$EXO/user_settings.json"
    cp "${exoSrc}/matugen/templates/colors.scss" "${exoSrc}/matugen/templates/hyprlock.conf" "$HOME/.config/matugen/templates/"
    # Seed shell colors before the first ignis start (which requires
    # colors.scss to exist): adopt the previous wallpaper if there is one,
    # else the first image in Wallpapers, else a compiling stub.
    if [ ! -f "$EXO/colors.scss" ]; then
      WALL=""
      LEG="$HOME/.local/share/onix-shell/wallpaper"
      if [ -f "$LEG" ]; then WALL="$(cat "$LEG")"; fi
      if [ -n "$WALL" ] && [ ! -f "$WALL" ]; then WALL=""; fi
      if [ -z "$WALL" ]; then
        WALL="$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)" || true
      fi
      if [ -n "$WALL" ]; then
        ${pkgs.matugen}/bin/matugen image -t scheme-tonal-spot "$WALL" -m dark --prefer darkness || printf '/* seeded before first wallpaper is set */\n' > "$EXO/colors.scss"
      else
        printf '/* seeded before first wallpaper is set */\n' > "$EXO/colors.scss"
      fi
      [ -f "$EXO/colors.scss" ] || printf '/* seeded before first wallpaper is set */\n' > "$EXO/colors.scss"
    fi
  '';
}
