{pkgs, ...}: {
  # Media apps, packaged in-tree (pkgs/): nuvio (video library) ships an
  # upstream AppImage, wrapped with the host graphics/audio stack.
  home.packages = with pkgs; [
    nuvio
  ];
}
