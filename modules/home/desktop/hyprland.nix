# Basic Hyprland session: compositor settings, core keybinds, floating
# rules, and the small CLI tools the binds rely on. No custom shell.
{
  lib,
  pkgs,
  ...
}: let
  workspaces = lib.concatMap (i: [
    "SUPER,${toString i},workspace,${toString i}"
    "SUPER+SHIFT,${toString i},movetoworkspace,${toString i}"
  ]) (lib.range 1 9);
in {
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = [",preferred,auto,1"];

      env = [
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Bibata-Modern-Classic"
        "HYPRCURSOR_SIZE,24"
        "NIXOS_OZONE_WL,1"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          tap_to_click = true;
          disable_while_typing = true;
        };
      };

      general = {
        gaps_in = 8;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgba(81a1c1ff)";
        "col.inactive_border" = "rgba(4c566aff)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 12;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      bind =
        [
          "SUPER,RETURN,exec,ghostty"
          "SUPER,SPACE,exec,wofi --show drun"
          "SUPER,Q,killactive,"
          "SUPER,SHIFT+L,exec,hyprlock"
          "SUPER,F,fullscreen,"
          "SUPER,V,togglefloating,"
          "SUPER,Print,exec,sh -c 'grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png'"
          "SUPER+SHIFT,S,exec,sh -c 'grim -g \"$(slurp)\" - | wl-copy'"
          "SUPER,mouse_down,workspace,e+1"
          "SUPER,mouse_up,workspace,e-1"
          ",XF86AudioPlay,exec,playerctl play-pause"
          ",XF86AudioNext,exec,playerctl next"
          ",XF86AudioPrev,exec,playerctl previous"
        ]
        ++ workspaces;

      binde = [
        ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86MonBrightnessUp,exec,brightnessctl set 5%+"
        ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
      ];

      windowrule = [
        "float,^(org.gnome.Nautilus)$"
        "float,^(pavucontrol)$"
        "float,^(blueman-manager)$"
        "float,title:^(Picture-in-Picture)$"
      ];

      exec-once = [
        "awww-daemon"
        "awww img /home/manpreet/Pictures/Wallpapers/ronin-shade.png"
      ];
    };
  };

  # Tools referenced by the binds above.
  home.packages = with pkgs; [
    brightnessctl
    playerctl
    wl-clipboard
    grim
    slurp
    libnotify
    wofi
    awww
  ];
}
