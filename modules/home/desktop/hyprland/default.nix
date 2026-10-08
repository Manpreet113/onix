{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = {
        # output = "" means every monitor: preferred mode, auto position
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      env = [
        {
          _args = [
            "XCURSOR_THEME"
            "Bibata-Modern-Classic"
          ];
        }
        {
          _args = [
            "XCURSOR_SIZE"
            "24"
          ];
        }
        {
          _args = [
            "HYPRCURSOR_THEME"
            "Bibata-Modern-Classic"
          ];
        }
        {
          _args = [
            "HYPRCURSOR_SIZE"
            "24"
          ];
        }
      ];
    };
  };

  # Tools referenced by binds
  # Tools referenced by binds and scripts
  home.packages = with pkgs; [
    brightnessctl
    playerctl
    wl-clipboard
    cliphist
    grim
    slurp
    hyprpicker
    libnotify
  ];
}
