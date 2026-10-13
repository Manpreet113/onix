{pkgs, ...}: {
  # Media apps, packaged in-tree (pkgs/): nuvio (video library) and
  # bitchord (YouTube Music client) ship upstream AppImages, wrapped with
  # the host graphics/audio stack.
  home.packages = with pkgs; [
    nuvio
    bitchord
  ];
}
