{
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
    inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.nix-index.enable = true;

  programs.btop = {
    enable = true;
    # Live wallpaper-driven theme (skein renders it on every theme change).
    # Missing file falls back to the default theme.
    settings = {
      color_theme = "/home/manpreet/.cache/skein/btop.theme";
    };
  };

  # Less pager with colors
  programs.lesspipe.enable = true;
}
