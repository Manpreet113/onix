# Basic Hyprland session: compositor settings, core keybinds, floating
# rules, and the small CLI tools the binds rely on. No custom shell.
#
# Binds use the proven lua forms (hl.bind with lua key/dispatcher exprs);
# single-string forms and hyphenated hl.* calls do not parse.
{
  lib,
  pkgs,
  ...
}: let
  raw = lib.generators.mkLuaInline;

  bindDefs = [
    {
      keys = ''mod .. " + RETURN"'';
      run = ''hl.dsp.exec_cmd("ghostty")'';
    }
    {
      keys = ''mod .. " + SPACE"'';
      run = ''hl.dsp.exec_cmd("wofi --show drun")'';
    }
    {
      keys = ''mod .. " + Q"'';
      run = ''hl.dsp.window.close()'';
    }
    {
      keys = ''mod .. " + SHIFT + L"'';
      run = ''hl.dsp.exec_cmd("hyprlock")'';
    }
    {
      keys = ''mod .. " + F"'';
      run = ''hl.dsp.window.fullscreen()'';
    }
    {
      keys = ''mod .. " + V"'';
      run = ''hl.dsp.window.float({ action = "toggle" })'';
    }
    {
      keys = ''"Print"'';
      run = ''hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png")'';
    }
    {
      keys = ''mod .. " + SHIFT + S"'';
      run = ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'';
    }
    {
      keys = ''mod .. " + left"'';
      run = ''hl.dsp.focus({ direction = "left" })'';
    }
    {
      keys = ''mod .. " + right"'';
      run = ''hl.dsp.focus({ direction = "right" })'';
    }
    {
      keys = ''mod .. " + up"'';
      run = ''hl.dsp.focus({ direction = "up" })'';
    }
    {
      keys = ''mod .. " + down"'';
      run = ''hl.dsp.focus({ direction = "down" })'';
    }
    {
      keys = ''mod .. " + SHIFT + left"'';
      run = ''hl.dsp.window.move({ direction = "left" })'';
    }
    {
      keys = ''mod .. " + SHIFT + right"'';
      run = ''hl.dsp.window.move({ direction = "right" })'';
    }
    {
      keys = ''mod .. " + SHIFT + up"'';
      run = ''hl.dsp.window.move({ direction = "up" })'';
    }
    {
      keys = ''mod .. " + SHIFT + down"'';
      run = ''hl.dsp.window.move({ direction = "down" })'';
    }
    {
      keys = ''mod .. " + mouse_down"'';
      run = ''hl.dsp.focus({ workspace = "e+1" })'';
    }
    {
      keys = ''mod .. " + mouse_up"'';
      run = ''hl.dsp.focus({ workspace = "e-1" })'';
    }
    {
      keys = ''mod .. " + mouse:272"'';
      run = ''hl.dsp.window.drag()'';
      opts = {mouse = true;};
    }
    {
      keys = ''mod .. " + mouse:273"'';
      run = ''hl.dsp.window.resize()'';
      opts = {mouse = true;};
    }
    {
      keys = ''"XF86AudioRaiseVolume"'';
      run = ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")'';
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86AudioLowerVolume"'';
      run = ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'';
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86AudioMute"'';
      run = ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'';
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86AudioPlay"'';
      run = ''hl.dsp.exec_cmd("playerctl play-pause")'';
    }
    {
      keys = ''"XF86AudioNext"'';
      run = ''hl.dsp.exec_cmd("playerctl next")'';
    }
    {
      keys = ''"XF86AudioPrev"'';
      run = ''hl.dsp.exec_cmd("playerctl previous")'';
    }
    {
      keys = ''"XF86MonBrightnessUp"'';
      run = ''hl.dsp.exec_cmd("brightnessctl set 5%+")'';
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86MonBrightnessDown"'';
      run = ''hl.dsp.exec_cmd("brightnessctl set 5%-")'';
      opts = {repeating = true;};
    }
  ];

  workspaceBindDefs = lib.concatMap (i: [
    {
      keys = ''mod .. " + ${toString i}"'';
      run = ''hl.dsp.focus({ workspace = ${toString i} })'';
    }
    {
      keys = ''mod .. " + SHIFT + ${toString i}"'';
      run = ''hl.dsp.window.move({ workspace = ${toString i} })'';
    }
  ]) (lib.range 1 9);

  allBindDefs = bindDefs ++ workspaceBindDefs;

  mkBindEntry = b: {
    _args = [(raw b.keys) (raw b.run)] ++ lib.optional ((b.opts or null) != null) b.opts;
  };
in {
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      mod = {
        _var = "SUPER";
      };

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
        {
          _args = [
            "NIXOS_OZONE_WL"
            "1"
          ];
        }
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

      bind = map mkBindEntry allBindDefs;

      window_rule = [
        {
          match.class = "^(org.gnome.Nautilus)$";
          float = true;
        }
        {
          match.class = "^(pavucontrol)$";
          float = true;
          size = "800 600";
          center = true;
        }
        {
          match.class = "^(blueman-manager)$";
          float = true;
          size = "800 600";
          center = true;
        }
        {
          match.title = "^(Picture-in-Picture)$";
          float = true;
        }
      ];
    };

    # Wallpaper daemon + initial wallpaper, as a required lua file (raw
    # lua -- hyphenated hl.* calls like hl.exec-once do not parse).
    extraLuaFiles = {
      autostart = ''
        hl.on("hyprland.start", function()
          hl.exec_cmd("awww-daemon")
          hl.exec_cmd("awww img /home/manpreet/Pictures/Wallpapers/ronin-shade.png")
        end)
      '';
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
