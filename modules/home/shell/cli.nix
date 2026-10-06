{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # modern CLI replacements
    ripgrep
    fd
    htop
    btop
    jq
    yq
    fzf
    eza
    bat
    zoxide
    atuin
    direnv
    nix-direnv
    carapace
    fastfetch
    tealdeer
    dust
    duf
    procs
    bottom
    helix # handy fallback
  ];

  programs.htop.enable = true;
  programs.btop.enable = true;

  # Less pager with colors
  programs.lesspipe.enable = true;
}
