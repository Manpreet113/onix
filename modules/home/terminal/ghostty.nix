_: {
  programs.ghostty = {
    enable = true;
    settings = {
      font-feature = "+calt +liga +ss01";
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
      # Live wallpaper-driven colors (skein renders this on every theme
      # change)
      config-file = "/home/manpreet/.cache/skein/ghostty.conf";
    };
  };

  # Default terminal env
  home.sessionVariables = {
    TERMINAL = "ghostty";
  };
}
