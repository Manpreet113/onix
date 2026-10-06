{ config, lib, pkgs, ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 300;
        hide_cursor = true;
        no_fade_in = false;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(235, 219, 178)";
          inner_color = "rgb(60, 56, 54)";
          outer_color = "rgb(69, 133, 136)";
          outline_thickness = 2;
          placeholder_text = "<i>Password...</i>";
          shadow_passes = 2;
        }
      ];
      label = [
        {
          text = "cmd[update:1000] echo \"$TIME\"";
          color = "rgba(235,219,178,1.0)";
          font_size = 55;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
