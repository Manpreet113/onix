# Niri session for the Exo desktop shell (upstream: github:debuggyo/Exo).
#
# Single source of truth for keybinds: `exoBinds` below generates the niri
# `binds` section (binds reference stock `ignis` commands; window management
# is native Niri). Fields per bind: keys (Niri KDL key expr), props (bind
# properties like hotkey-overlay-title), run (action node), desc, group
# (documentation only now that the overlay cheatsheet is gone).
{
  lib,
  pkgs,
  ...
}: let
  # Shorthand constructors for the KDL action nodes.
  spawn = cmd: {spawn = cmd;};
  act = name: {"${name}" = {};};
  actArg = name: arg: {"${name}" = arg;};

  exoBinds = [
    {
      keys = "Mod+Return";
      props = {hotkey-overlay-title = "Terminal";};
      run = spawn ["ghostty"];
      desc = "Terminal";
      group = "Apps";
    }
    {
      keys = "Mod+E";
      props = {hotkey-overlay-title = "Editor";};
      run = spawn ["code"];
      desc = "Editor";
      group = "Apps";
    }
    {
      keys = "Mod+B";
      props = {hotkey-overlay-title = "Browser";};
      run = spawn ["zen"];
      desc = "Browser";
      group = "Apps";
    }
    {
      keys = "Mod+Shift+B";
      props = {};
      run = spawn ["zen" "--private-window"];
      desc = "Private window";
      group = "Apps";
    }
    {
      keys = "Mod+A";
      props = {hotkey-overlay-title = "Files";};
      run = spawn ["nautilus"];
      desc = "Files";
      group = "Apps";
    }
    {
      keys = "Mod+Space";
      props = {hotkey-overlay-title = "Launcher";};
      run = spawn ["ignis" "open-window" "Launcher"];
      desc = "Launcher";
      group = "Apps";
    }
    {
      keys = "Mod+Shift+Slash";
      props = {};
      run = act "show-hotkey-overlay";
      desc = "Hotkey overlay";
      group = "Apps";
    }
    {
      keys = "Mod+S";
      props = {hotkey-overlay-title = "Settings";};
      run = spawn ["ignis" "open-window" "Settings"];
      desc = "Settings";
      group = "Apps";
    }

    {
      keys = "Mod+Shift+Q";
      props = {hotkey-overlay-title = "Power menu";};
      run = spawn ["ignis" "open-window" "PowerMenu"];
      desc = "Power menu";
      group = "Shell";
    }
    {
      keys = "Mod+Escape";
      props = {
        hotkey-overlay-title = "Power menu";
        allow-inhibiting = false;
      };
      run = spawn ["ignis" "open-window" "PowerMenu"];
      desc = "Power menu (always)";
      group = "Shell";
    }
    {
      keys = "Super+L";
      props = {hotkey-overlay-title = "Lock the Screen";};
      run = spawn ["hyprlock"];
      desc = "Lock screen";
      group = "Shell";
    }
    {
      keys = "Mod+Shift+E";
      props = {};
      run = act "quit";
      desc = "Log out (confirm)";
      group = "Shell";
    }
    {
      keys = "Mod+O";
      props = {};
      run = act "toggle-overview";
      desc = "Overview";
      group = "Shell";
    }

    {
      keys = "Print";
      props = {};
      run = {"spawn-sh" = "mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png";};
      desc = "Screenshot to file";
      group = "Screenshots";
    }
    {
      keys = "Mod+Shift+P";
      props = {};
      run = {"spawn-sh" = "grim -g \"$(slurp)\" - | wl-copy";};
      desc = "Screenshot region to clipboard";
      group = "Screenshots";
    }
    {
      keys = "Mod+Shift+R";
      props = {hotkey-overlay-title = "Record the screen";};
      run = spawn ["ignis" "run-command" "recorder-record-screen"];
      desc = "Record screen";
      group = "Recorder";
    }
    {
      keys = "Mod+Shift+S";
      props = {hotkey-overlay-title = "Record a region";};
      run = spawn ["ignis" "run-command" "recorder-record-region"];
      desc = "Record region";
      group = "Recorder";
    }
    {
      keys = "Mod+Shift+W";
      props = {hotkey-overlay-title = "Record a window (portal)";};
      run = spawn ["ignis" "run-command" "recorder-record-portal"];
      desc = "Record window";
      group = "Recorder";
    }

    {
      keys = "Mod+Q";
      props = {};
      run = act "close-window";
      desc = "Close window";
      group = "Window";
    }
    {
      keys = "Mod+F";
      props = {};
      run = act "maximize-column";
      desc = "Maximize column";
      group = "Window";
    }
    {
      keys = "Mod+Shift+F";
      props = {};
      run = act "fullscreen-window";
      desc = "Toggle fullscreen";
      group = "Window";
    }
    {
      keys = "Mod+V";
      props = {};
      run = act "toggle-window-floating";
      desc = "Toggle floating";
      group = "Window";
    }
    {
      keys = "Mod+Shift+J";
      props = {};
      run = act "switch-preset-column-width";
      desc = "Cycle column width";
      group = "Window";
    }
    {
      keys = "Mod+R";
      props = {};
      run = act "switch-preset-window-height";
      desc = "Cycle window height";
      group = "Window";
    }
    {
      keys = "Mod+C";
      props = {};
      run = act "center-column";
      desc = "Center column";
      group = "Window";
    }
    {
      keys = "Mod+Minus";
      props = {};
      run = actArg "set-column-width" "-10%";
      desc = "Narrower column";
      group = "Window";
    }
    {
      keys = "Mod+Equal";
      props = {};
      run = actArg "set-column-width" "+10%";
      desc = "Wider column";
      group = "Window";
    }
    {
      keys = "Mod+BracketLeft";
      props = {};
      run = act "consume-or-expel-window-left";
      desc = "Consume/expel left";
      group = "Window";
    }
    {
      keys = "Mod+BracketRight";
      props = {};
      run = act "consume-or-expel-window-right";
      desc = "Consume/expel right";
      group = "Window";
    }

    {
      keys = "Mod+Left";
      props = {};
      run = act "focus-column-left";
      desc = "Focus left";
      group = "Focus";
    }
    {
      keys = "Mod+Right";
      props = {};
      run = act "focus-column-right";
      desc = "Focus right";
      group = "Focus";
    }
    {
      keys = "Mod+Up";
      props = {};
      run = act "focus-window-up";
      desc = "Focus up";
      group = "Focus";
    }
    {
      keys = "Mod+Down";
      props = {};
      run = act "focus-window-down";
      desc = "Focus down";
      group = "Focus";
    }
    {
      keys = "Mod+H";
      props = {};
      run = act "focus-column-left";
      desc = "Focus left";
      group = "Focus";
    }
    {
      keys = "Mod+L";
      props = {};
      run = act "focus-column-right";
      desc = "Focus right";
      group = "Focus";
    }
    {
      keys = "Mod+K";
      props = {};
      run = act "focus-window-up";
      desc = "Focus up";
      group = "Focus";
    }
    {
      keys = "Mod+J";
      props = {};
      run = act "focus-window-down";
      desc = "Focus down";
      group = "Focus";
    }
    {
      keys = "Mod+Home";
      props = {};
      run = act "focus-column-first";
      desc = "First column";
      group = "Focus";
    }
    {
      keys = "Mod+End";
      props = {};
      run = act "focus-column-last";
      desc = "Last column";
      group = "Focus";
    }
    {
      keys = "Mod+U";
      props = {};
      run = act "focus-workspace-down";
      desc = "Workspace down";
      group = "Focus";
    }
    {
      keys = "Mod+I";
      props = {};
      run = act "focus-workspace-up";
      desc = "Workspace up";
      group = "Focus";
    }

    {
      keys = "Mod+Ctrl+Left";
      props = {};
      run = act "move-column-left";
      desc = "Move left";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+Right";
      props = {};
      run = act "move-column-right";
      desc = "Move right";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+Up";
      props = {};
      run = act "move-window-up";
      desc = "Move up";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+Down";
      props = {};
      run = act "move-window-down";
      desc = "Move down";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+H";
      props = {};
      run = act "move-column-left";
      desc = "Move left";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+L";
      props = {};
      run = act "move-column-right";
      desc = "Move right";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+K";
      props = {};
      run = act "move-window-up";
      desc = "Move up";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+J";
      props = {};
      run = act "move-window-down";
      desc = "Move down";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+Home";
      props = {};
      run = act "move-column-to-first";
      desc = "Move to first";
      group = "Move";
    }
    {
      keys = "Mod+Ctrl+End";
      props = {};
      run = act "move-column-to-last";
      desc = "Move to last";
      group = "Move";
    }
    {
      keys = "Mod+Shift+Left";
      props = {};
      run = act "focus-monitor-left";
      desc = "Focus monitor left";
      group = "Move";
    }
    {
      keys = "Mod+Shift+Right";
      props = {};
      run = act "focus-monitor-right";
      desc = "Focus monitor right";
      group = "Move";
    }
    {
      keys = "Mod+Shift+Up";
      props = {};
      run = act "focus-monitor-up";
      desc = "Focus monitor up";
      group = "Move";
    }
    {
      keys = "Mod+Shift+Down";
      props = {};
      run = act "focus-monitor-down";
      desc = "Focus monitor down";
      group = "Move";
    }

    {
      keys = "Mod+WheelScrollDown";
      props = {"cooldown-ms" = 150;};
      run = act "focus-workspace-down";
      desc = "Next workspace";
      group = "Mouse";
    }
    {
      keys = "Mod+WheelScrollUp";
      props = {"cooldown-ms" = 150;};
      run = act "focus-workspace-up";
      desc = "Previous workspace";
      group = "Mouse";
    }

    {
      keys = "XF86AudioRaiseVolume";
      props = {allow-when-locked = true;};
      run = spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" "-l" "1.0"];
      desc = "Volume up";
      group = "Media";
    }
    {
      keys = "XF86AudioLowerVolume";
      props = {allow-when-locked = true;};
      run = spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
      desc = "Volume down";
      group = "Media";
    }
    {
      keys = "XF86AudioMute";
      props = {allow-when-locked = true;};
      run = spawn ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
      desc = "Mute";
      group = "Media";
    }
    {
      keys = "XF86AudioPlay";
      props = {allow-when-locked = true;};
      run = spawn ["playerctl" "play-pause"];
      desc = "Play / pause";
      group = "Media";
    }
    {
      keys = "XF86AudioNext";
      props = {allow-when-locked = true;};
      run = spawn ["playerctl" "next"];
      desc = "Next track";
      group = "Media";
    }
    {
      keys = "XF86AudioPrev";
      props = {allow-when-locked = true;};
      run = spawn ["playerctl" "previous"];
      desc = "Previous track";
      group = "Media";
    }
    {
      keys = "XF86MonBrightnessUp";
      props = {allow-when-locked = true;};
      run = spawn ["brightnessctl" "--class=backlight" "set" "5%+"];
      desc = "Brightness up";
      group = "Media";
    }
    {
      keys = "XF86MonBrightnessDown";
      props = {allow-when-locked = true;};
      run = spawn ["brightnessctl" "--class=backlight" "set" "5%-"];
      desc = "Brightness down";
      group = "Media";
    }
  ];

  workspaceBinds =
    lib.concatMap (i: [
      {
        keys = "Mod+${toString i}";
        props = {};
        run = actArg "focus-workspace" i;
        desc = "Workspace ${toString i}";
        group = "Workspaces";
      }
      {
        keys = "Mod+Ctrl+${toString i}";
        props = {};
        run = actArg "move-column-to-workspace" i;
        desc = "Move to ${toString i}";
        group = "Workspaces";
      }
    ]) (lib.range 1 9);

  allBinds = exoBinds ++ workspaceBinds;

  # "Mod+J" -> { _props = {...}; focus-window-down = {}; }
  mkBind = b: {
    "${b.keys}" =
      (lib.optionalAttrs (b.props != {}) {_props = b.props;})
      // b.run;
  };

  bindsAttr = lib.foldl' (acc: b: acc // (mkBind b)) {} allBinds;
in {
  wayland.windowManager.niri = {
    enable = true;

    settings = {
      input = {
        keyboard.xkb.layout = "us";
        touchpad = {
          tap = {};
          natural-scroll = {};
          dwt = {};
        };
        mouse.accel-speed = 0.0;
        focus-follows-mouse._props = {max-scroll-amount = "0%";};
      };

      layout = {
        gaps = 8;
        default-column-width.proportion = 0.5;
        focus-ring = {
          width = 2;
          active-color = "#81a1c1";
          inactive-color = "#4c566a";
          urgent-color = "#bf616a";
        };
        border.off = {};
      };

      prefer-no-csd = {};
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      hotkey-overlay.skip-at-startup = {};

      spawn-at-startup = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];

      binds = bindsAttr;
    };

    # Window rules as raw KDL: the settings generator merges same-named
    # nodes, but niri wants one match per window-rule block. Same for the
    # repeated spawn-at-startup nodes below.
    extraConfig = ''
      spawn-at-startup "swww-daemon"
      spawn-at-startup "ignis" "init"
      window-rule {
          match app-id="^(org.gnome.Nautilus)$"
          open-floating true
      }
      window-rule {
          match app-id="^(pavucontrol)$"
          open-floating true
      }
      window-rule {
          match app-id="^(blueman-manager)$"
          open-floating true
      }
      window-rule {
          match title="^(Picture-in-Picture)$"
          open-floating true
      }
    '';
  };

  # Tools referenced by binds and the Exo recorder.
  home.packages = with pkgs; [
    brightnessctl
    playerctl
    wl-clipboard
    grim
    slurp
    libnotify
    gpu-screen-recorder
    polkit_gnome
  ];
}
