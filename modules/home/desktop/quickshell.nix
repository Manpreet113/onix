_: {
  programs.quickshell = {
    enable = true;
    configs.shell = ./assets/quickshell;
    activeConfig = "shell";
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };
}
