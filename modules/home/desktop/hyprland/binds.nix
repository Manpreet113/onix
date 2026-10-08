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
    settings = {
      mod = {
        _var = "SUPER";
      };

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
          (mkBind ''mod .. " + SHIFT + F"'' ''hl.dsp.exec_cmd("nautilus")'' null)
          (mkBind ''mod .. " + SHIFT + W"'' ''hl.dsp.exec_cmd("quickshell --config shell ipc call wallpaper toggle")'' null)

          # Screenshots (grim + slurp)
          (mkBind ''"Print"'' ''hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png")'' null)
          (mkBind ''mod .. " + SHIFT + S"'' ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'' null)

          # Clipboard history
          (mkBind ''mod .. " + SHIFT + V"'' ''hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy")'' null)

          # Power menu
          (mkBind ''mod .. " + SHIFT + Q"'' ''hl.dsp.exec_cmd("onix-power-menu")'' null)

          # Window management
          (mkBind ''mod .. " + Q"'' ''hl.dsp.window.close()'' null)
          (mkBind ''mod .. " + F"'' ''hl.dsp.window.fullscreen()'' null)
          (mkBind ''mod .. " + V"'' ''hl.dsp.window.float({ action = "toggle" })'' null)
          (mkBind ''mod .. " + P"'' ''hl.dsp.window.pin()'' null)
          (mkBind ''mod .. " + J"'' ''hl.dsp.layout("togglesplit")'' null)
          (mkBind ''mod .. " + R"'' ''hl.dsp.submap("resize")'' null)

          # Scratchpad
          (mkBind ''mod .. " + S"'' ''hl.dsp.workspace.toggle_special()'' null)
          (mkBind ''mod .. " + SHIFT + T"'' ''hl.dsp.window.move({ workspace = "special" })'' null)

          # Lock
          (mkBind ''mod .. " + SHIFT + L"'' ''hl.dsp.exec_cmd("hyprlock")'' null)

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
          (mkBind ''"XF86AudioPlay"'' ''hl.dsp.exec_cmd("playerctl play-pause")'' null)
          (mkBind ''"XF86AudioNext"'' ''hl.dsp.exec_cmd("playerctl next")'' null)
          (mkBind ''"XF86AudioPrevious"'' ''hl.dsp.exec_cmd("playerctl previous")'' null)
          (mkBind ''"XF86MonBrightnessUp"'' ''hl.dsp.exec_cmd("brightnessctl set +5%")'' {repeating = true;})
          (mkBind ''"XF86MonBrightnessDown"'' ''hl.dsp.exec_cmd("brightnessctl set 5%-")'' {repeating = true;})
        ]
        # Workspaces 1-9 and shift-move to them
        ++ lib.concatMap (i: [
          (mkBind ''mod .. " + ${toString i}"'' ''hl.dsp.focus({ workspace = ${toString i} })'' null)
          (mkBind ''mod .. " + SHIFT + ${toString i}"'' ''hl.dsp.window.move({ workspace = ${toString i} })'' null)
        ]) (lib.range 1 9);
    };
  };

  # Wofi power menu (Lock/Suspend/Reboot/Shutdown)
  home.packages = with pkgs; [
    (writeShellScriptBin "onix-power-menu" ''
      choice=$(printf "Lock\nSuspend\nReboot\nShutdown" | ${wofi}/bin/wofi --dmenu --prompt "Power")
      case "$choice" in
        Lock) ${hyprlock}/bin/hyprlock ;;
        Suspend) ${systemd}/bin/systemctl suspend ;;
        Reboot) ${systemd}/bin/systemctl reboot ;;
        Shutdown) ${systemd}/bin/systemctl poweroff ;;
      esac
    '')
  ];
}
