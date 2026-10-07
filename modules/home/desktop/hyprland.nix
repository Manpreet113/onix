{
  lib,
  pkgs,
  ...
}: let
  raw = lib.generators.mkLuaInline;

  mkBind = keys: dispatcher: opts: {
    _args = [(raw keys) (raw dispatcher)] ++ lib.optional (opts != null) opts;
  };
in {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      mod = {
        _var = "SUPER";
      };

      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      on = {
        _args = [
          "hyprland.start"
          (raw ''function() hl.exec_cmd("hyprpaper &") end'')
        ];
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

      config = {
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
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          layout = "dwindle";
        };

        decoration = {
          rounding = 8;
          blur = {
            enabled = true;
            size = 5;
            passes = 3;
          };
          shadow.enabled = true;
        };

        animations.enabled = true;

        dwindle = {
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };
      };

      curve = [
        {
          _args = [
            "myBezier"
            {
              type = "bezier";
              points = [
                [
                  0.05
                  0.9
                ]
                [
                  0.1
                  1.05
                ]
              ];
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 7;
          bezier = "myBezier";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 7;
          bezier = "default";
          style = "popin 80%";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 7;
          bezier = "default";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 6;
          bezier = "default";
        }
      ];

      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        }
      ];

      bind =
        [
          # Apps
          (mkBind ''mod .. " + RETURN"'' ''hl.dsp.exec_cmd("ghostty")'' null)
          (mkBind ''mod .. " + E"'' ''hl.dsp.exec_cmd("code")'' null)
          (mkBind ''mod .. " + B"'' ''hl.dsp.exec_cmd("zen")'' null)
          (
            mkBind ''mod .. " + SHIFT + B"'' ''hl.dsp.exec_cmd("zen --private-window")'' null
          )
          (mkBind ''mod .. " + SPACE"'' ''hl.dsp.exec_cmd("wofi --show drun")'' null)

          # Window management
          (mkBind ''mod .. " + Q"'' ''hl.dsp.window.close()'' null)
          (mkBind ''mod .. " + F"'' ''hl.dsp.window.fullscreen()'' null)
          (mkBind ''mod .. " + V"'' ''hl.dsp.window.float({ action = "toggle" })'' null)
          (mkBind ''mod .. " + J"'' ''hl.dsp.layout("togglesplit")'' null)

          # Focus
          (mkBind ''mod .. " + left"'' ''hl.dsp.focus({ direction = "left" })'' null)
          (mkBind ''mod .. " + right"'' ''hl.dsp.focus({ direction = "right" })'' null)
          (mkBind ''mod .. " + up"'' ''hl.dsp.focus({ direction = "up" })'' null)
          (mkBind ''mod .. " + down"'' ''hl.dsp.focus({ direction = "down" })'' null)

          # Move window
          (mkBind ''mod .. " + SHIFT + left"'' ''hl.dsp.window.move({ direction = "left" })'' null)
          (mkBind ''mod .. " + SHIFT + right"'' ''hl.dsp.window.move({ direction = "right" })'' null)
          (mkBind ''mod .. " + SHIFT + up"'' ''hl.dsp.window.move({ direction = "up" })'' null)
          (mkBind ''mod .. " + SHIFT + down"'' ''hl.dsp.window.move({ direction = "down" })'' null)

          # Scroll through workspaces
          (mkBind ''mod .. " + mouse_down"'' ''hl.dsp.focus({ workspace = "e+1" })'' null)
          (mkBind ''mod .. " + mouse_up"'' ''hl.dsp.focus({ workspace = "e-1" })'' null)

          # Move/resize with mouse (bindm)
          (mkBind ''mod .. " + mouse:272"'' ''hl.dsp.window.drag()'' {mouse = true;})
          (mkBind ''mod .. " + mouse:273"'' ''hl.dsp.window.resize()'' {mouse = true;})

          # Media keys (binde)
          (
            mkBind ''"XF86AudioRaiseVolume"'' ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")'' {
              repeating = true;
            }
          )
          (
            mkBind ''"XF86AudioLowerVolume"'' ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'' {
              repeating = true;
            }
          )
          (
            mkBind ''"XF86AudioMute"'' ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'' {
              repeating = true;
            }
          )
          (mkBind ''"XF86MonBrightnessUp"'' ''hl.dsp.exec_cmd("brightnessctl set +5%")'' {repeating = true;})
          (mkBind ''"XF86MonBrightnessDown"'' ''hl.dsp.exec_cmd("brightnessctl set 5%-")'' {repeating = true;})
        ]
        # Workspaces 1-9 and shift-move to them
        ++ lib.concatMap (i: [
          (mkBind ''mod .. " + ${toString i}"'' ''hl.dsp.focus({ workspace = ${toString i} })'' null)
          (mkBind ''mod .. " + SHIFT + ${toString i}"'' ''hl.dsp.window.move({ workspace = ${toString i} })'' null)
        ]) (lib.range 1 9);

      window_rule = [
        {
          match.class = "^(org.gnome.Nautilus)$";
          float = true;
        }
        {
          match.class = "^(pavucontrol)$";
          float = true;
        }
        {
          match.title = "^(Picture-in-Picture)$";
          float = true;
        }
      ];
    };
  };

  # Required packages for Hyprland
  home.packages = with pkgs; [
    brightnessctl
    playerctl
    wl-clipboard
    cliphist
    grim
    slurp
    hyprpicker
  ];
}
