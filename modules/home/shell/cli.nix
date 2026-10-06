{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    ripgrep
    fd
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
  ];

  programs.btop.enable = true;

  # Less pager with colors
  programs.lesspipe.enable = true;
}
