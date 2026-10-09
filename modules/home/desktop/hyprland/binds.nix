{lib, ...}: let
  raw = lib.generators.mkLuaInline;

  # Single source of truth for every keybind: the lua in `settings.bind`
  # AND ~/.config/quickshell/keybinds.json (for the Keybinds.qml cheatsheet)
  # are both generated from this list. Fields: lua key expr, lua dispatcher
  # expr, human description, group, optional bind flags (e.g. repeating).
  bindDefs = [
    {
      keys = ''mod .. " + RETURN"'';
      run = ''hl.dsp.exec_cmd("ghostty")'';
      desc = "Terminal";
      group = "Apps";
    }
    {
      keys = ''mod .. " + E"'';
      run = ''hl.dsp.exec_cmd("code")'';
      desc = "Editor";
      group = "Apps";
    }
    {
      keys = ''mod .. " + B"'';
      run = ''hl.dsp.exec_cmd("zen")'';
      desc = "Browser";
      group = "Apps";
    }
    {
      keys = ''mod .. " + SHIFT + B"'';
      run = ''hl.dsp.exec_cmd("zen --private-window")'';
      desc = "Private window";
      group = "Apps";
    }
    {
      keys = ''mod .. " + SPACE"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call launcher toggle")'';
      desc = "Launcher";
      group = "Apps";
    }
    {
      keys = ''mod .. " + SHIFT + F"'';
      run = ''hl.dsp.exec_cmd("nautilus")'';
      desc = "Files";
      group = "Apps";
    }
    {
      keys = ''mod .. " + SHIFT + W"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call wallpaper toggle")'';
      desc = "Wallpaper picker";
      group = "Apps";
    }
    {
      keys = ''mod .. " + slash"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call keybinds toggle")'';
      desc = "Keybind cheatsheet";
      group = "Apps";
    }

    {
      keys = ''"Print"'';
      run = ''hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png")'';
      desc = "Screenshot to file";
      group = "Screenshots";
    }
    {
      keys = ''mod .. " + SHIFT + S"'';
      run = ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'';
      desc = "Screenshot region to clipboard";
      group = "Screenshots";
    }

    {
      keys = ''mod .. " + SHIFT + V"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call clipboard toggle")'';
      desc = "Clipboard history";
      group = "Clipboard";
    }

    {
      keys = ''mod .. " + C"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call calendar toggle")'';
      desc = "Calendar";
      group = "Panels";
    }
    {
      keys = ''mod .. " + M"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call sound toggle")'';
      desc = "Sound mixer";
      group = "Panels";
    }
    {
      keys = ''mod .. " + SHIFT + M"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call media toggle")'';
      desc = "Now playing";
      group = "Panels";
    }
    {
      keys = ''mod .. " + SHIFT + N"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call network toggle")'';
      desc = "Network";
      group = "Panels";
    }
    {
      keys = ''mod .. " + Y"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call battery toggle")'';
      desc = "Battery";
      group = "Panels";
    }
    {
      keys = ''mod .. " + D"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call bluetooth toggle")'';
      desc = "Bluetooth";
      group = "Panels";
    }
    {
      keys = ''mod .. " + SHIFT + I"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call system toggle")'';
      desc = "System monitor";
      group = "Panels";
    }

    {
      keys = ''mod .. " + SHIFT + Q"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call power toggle")'';
      desc = "Power menu";
      group = "System";
    }
    {
      keys = ''mod .. " + SHIFT + L"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call lock lock")'';
      desc = "Lock screen";
      group = "System";
    }
    {
      keys = ''mod .. " + N"'';
      run = ''hl.dsp.exec_cmd("quickshell --config shell ipc call notifs toggle")'';
      desc = "Notification center";
      group = "System";
    }

    {
      keys = ''mod .. " + Q"'';
      run = ''hl.dsp.window.close()'';
      desc = "Close window";
      group = "Window";
    }
    {
      keys = ''mod .. " + F"'';
      run = ''hl.dsp.window.fullscreen()'';
      desc = "Toggle fullscreen";
      group = "Window";
    }
    {
      keys = ''mod .. " + V"'';
      run = ''hl.dsp.window.float({ action = "toggle" })'';
      desc = "Toggle floating";
      group = "Window";
    }
    {
      keys = ''mod .. " + P"'';
      run = ''hl.dsp.window.pin()'';
      desc = "Pin window";
      group = "Window";
    }
    {
      keys = ''mod .. " + J"'';
      run = ''hl.dsp.layout("togglesplit")'';
      desc = "Toggle split";
      group = "Window";
    }
    {
      keys = ''mod .. " + R"'';
      run = ''hl.dsp.submap("resize")'';
      desc = "Resize mode";
      group = "Window";
    }

    {
      keys = ''mod .. " + S"'';
      run = ''hl.dsp.workspace.toggle_special()'';
      desc = "Scratchpad";
      group = "Window";
    }
    {
      keys = ''mod .. " + SHIFT + T"'';
      run = ''hl.dsp.window.move({ workspace = "special" })'';
      desc = "Send to scratchpad";
      group = "Window";
    }

    {
      keys = ''mod .. " + left"'';
      run = ''hl.dsp.focus({ direction = "left" })'';
      desc = "Focus left";
      group = "Focus";
    }
    {
      keys = ''mod .. " + right"'';
      run = ''hl.dsp.focus({ direction = "right" })'';
      desc = "Focus right";
      group = "Focus";
    }
    {
      keys = ''mod .. " + up"'';
      run = ''hl.dsp.focus({ direction = "up" })'';
      desc = "Focus up";
      group = "Focus";
    }
    {
      keys = ''mod .. " + down"'';
      run = ''hl.dsp.focus({ direction = "down" })'';
      desc = "Focus down";
      group = "Focus";
    }

    {
      keys = ''mod .. " + SHIFT + left"'';
      run = ''hl.dsp.window.move({ direction = "left" })'';
      desc = "Move left";
      group = "Move";
    }
    {
      keys = ''mod .. " + SHIFT + right"'';
      run = ''hl.dsp.window.move({ direction = "right" })'';
      desc = "Move right";
      group = "Move";
    }
    {
      keys = ''mod .. " + SHIFT + up"'';
      run = ''hl.dsp.window.move({ direction = "up" })'';
      desc = "Move up";
      group = "Move";
    }
    {
      keys = ''mod .. " + SHIFT + down"'';
      run = ''hl.dsp.window.move({ direction = "down" })'';
      desc = "Move down";
      group = "Move";
    }

    {
      keys = ''mod .. " + mouse_down"'';
      run = ''hl.dsp.focus({ workspace = "e+1" })'';
      desc = "Next workspace";
      group = "Mouse";
    }
    {
      keys = ''mod .. " + mouse_up"'';
      run = ''hl.dsp.focus({ workspace = "e-1" })'';
      desc = "Previous workspace";
      group = "Mouse";
    }
    {
      keys = ''mod .. " + mouse:272"'';
      run = ''hl.dsp.window.drag()'';
      desc = "Drag window";
      group = "Mouse";
      opts = {mouse = true;};
    }
    {
      keys = ''mod .. " + mouse:273"'';
      run = ''hl.dsp.window.resize()'';
      desc = "Resize window";
      group = "Mouse";
      opts = {mouse = true;};
    }

    {
      keys = ''"XF86AudioRaiseVolume"'';
      run = ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+; quickshell --config shell ipc call osd volume")'';
      desc = "Volume up";
      group = "Media";
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86AudioLowerVolume"'';
      run = ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; quickshell --config shell ipc call osd volume")'';
      desc = "Volume down";
      group = "Media";
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86AudioMute"'';
      run = ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; quickshell --config shell ipc call osd volume")'';
      desc = "Mute";
      group = "Media";
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86AudioPlay"'';
      run = ''hl.dsp.exec_cmd("playerctl play-pause")'';
      desc = "Play / pause";
      group = "Media";
    }
    {
      keys = ''"XF86AudioNext"'';
      run = ''hl.dsp.exec_cmd("playerctl next")'';
      desc = "Next track";
      group = "Media";
    }
    {
      keys = ''"XF86AudioPrev"'';
      run = ''hl.dsp.exec_cmd("playerctl previous")'';
      desc = "Previous track";
      group = "Media";
    }
    {
      keys = ''"XF86MonBrightnessUp"'';
      run = ''hl.dsp.exec_cmd("brightnessctl set +5%; quickshell --config shell ipc call osd brightness")'';
      desc = "Brightness up";
      group = "Media";
      opts = {repeating = true;};
    }
    {
      keys = ''"XF86MonBrightnessDown"'';
      run = ''hl.dsp.exec_cmd("brightnessctl set 5%-; quickshell --config shell ipc call osd brightness")'';
      desc = "Brightness down";
      group = "Media";
      opts = {repeating = true;};
    }
  ];

  workspaceBindDefs = lib.concatMap (i: [
    {
      keys = ''mod .. " + ${toString i}"'';
      run = ''hl.dsp.focus({ workspace = ${toString i} })'';
      desc = "Workspace ${toString i}";
      group = "Workspaces";
    }
    {
      keys = ''mod .. " + SHIFT + ${toString i}"'';
      run = ''hl.dsp.window.move({ workspace = ${toString i} })'';
      desc = "Move to ${toString i}";
      group = "Workspaces";
    }
  ]) (lib.range 1 9);

  allBindDefs = bindDefs ++ workspaceBindDefs;

  mkBindEntry = b: {
    _args = [(raw b.keys) (raw b.run)] ++ lib.optional ((b.opts or null) != null) b.opts;
  };

  # `mod .. " + X"` -> "SUPER + X" for human display
  displayKeys = k:
    lib.concatStringsSep " + " (
      lib.filter (p: p != "") (
        map lib.trim (
          lib.splitString "+" (
            lib.replaceStrings ["mod" "\"" ".."] ["SUPER" "" ""] k
          )
        )
      )
    );

  toDoc = b: {
    keys = displayKeys b.keys;
    inherit (b) run desc;
  };

  groupNames = lib.unique (map (b: b.group) allBindDefs);
in {
  wayland.windowManager.hyprland = {
    settings = {
      mod = {
        _var = "SUPER";
      };

      bind = map mkBindEntry allBindDefs;
    };
  };

  # Machine-readable cheatsheet for the Keybinds.qml overlay.
  # Mirror of submaps.nix lives here so QML needs no lua parsing.
  xdg.configFile."quickshell/keybinds.json".text = builtins.toJSON {
    groups =
      map (g: {
        name = g;
        binds = map toDoc (lib.filter (b: b.group == g) allBindDefs);
      })
      groupNames;
    submaps = [
      {
        name = "resize";
        keys = "SUPER + R";
        binds = [
          {
            keys = "h / left";
            desc = "Resize left";
          }
          {
            keys = "j / down";
            desc = "Resize down";
          }
          {
            keys = "k / up";
            desc = "Resize up";
          }
          {
            keys = "l / right";
            desc = "Resize right";
          }
          {
            keys = "escape";
            desc = "Exit resize mode";
          }
        ];
      }
    ];
  };
}
