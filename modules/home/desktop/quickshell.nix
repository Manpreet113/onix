{pkgs, ...}: {
  programs.quickshell = {
    enable = true;
    # qtmultimedia enables Video {} for live (mp4) wallpapers
    package = pkgs.quickshell.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [pkgs.qt6.qtmultimedia];
    });
    configs.shell = ./assets/quickshell;
    configs.onix = ./assets/quickshell-onix;
    activeConfig = "onix";
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };
}
