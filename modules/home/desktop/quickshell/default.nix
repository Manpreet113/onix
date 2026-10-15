# Onix bar in Quickshell (QML) — bar-only milestone.
# Nix owns the package; QML source lives in assets/qs, symlinked live so
# edits apply on quickshell reload with no rebuild. Repo must stay at
# ~/onix (out-of-store symlink, same pattern as hypr/modules).
{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # qtmultimedia provides QtMultimedia/Video for live wallpapers.
    (quickshell.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [ qt6.qtmultimedia ];
    }))
    # ffmpeg extracts first-frame stills for video picker thumbnails.
    ffmpeg-headless
  ];

  # Live tree: ~/.config/quickshell/onix -> repo working tree.
  # `quickshell -c onix` loads shell.qml from there.
  xdg.configFile."quickshell/onix".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/onix/modules/home/desktop/quickshell/assets/qs";
}
