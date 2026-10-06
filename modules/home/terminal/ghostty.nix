{ config, lib, pkgs, ... }: let
  # ghostty may be in unstable on 26.05 — overlay provides `unstable`
  ghosttyPkg =
    if pkgs ? ghostty
    then pkgs.ghostty
    else if pkgs ? unstable && pkgs.unstable ? ghostty
    then pkgs.unstable.ghostty
    else pkgs.foot; # fallback
in {
  # ghostty is installed via programs.ghostty; foot is fallback/alternative
  home.packages = [pkgs.foot];

  programs.ghostty = lib.mkIf (builtins.hasAttr "ghostty" pkgs) {
    enable = true;
    package = ghosttyPkg;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      font-feature = "+calt +liga +ss01";
      theme = "Gruvbox Dark";
      background-opacity = 0.95;
      window-decoration = true;
      window-padding-x = 8;
      window-padding-y = 8;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "cursor,sudo,title";
      copy-on-select = true;
      confirm-close-surface = false;
      clipboard-read = "allow";
      clipboard-write = "allow";
      gtk-single-instance = true;
      gtk-titlebar = true;
    };
  };

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        pad = "8x8";
      };
      colors = {
        alpha = "0.95";
        background = "282828";
        foreground = "ebdbb2";
      };
    };
  };

  # Default terminal env
  home.sessionVariables = {
    TERMINAL = "ghostty";
  };
}
