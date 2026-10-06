{
  config,
  pkgs,
  inputs,
  ...
}: {
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
    comma
    inputs.opencode.packages.${pkgs.system}.default
  ];

  programs.nix-index.enable = true;

  programs.btop.enable = true;

  # Less pager with colors
  programs.lesspipe.enable = true;
}
