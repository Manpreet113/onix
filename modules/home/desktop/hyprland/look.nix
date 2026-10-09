_: {
  wayland.windowManager.hyprland = {
    # Live wallpaper colors: skein rewrites ~/.cache/skein/hyprland.lua on
    # every theme change and the shell runs `hyprctl reload` right after.
    # Guarded so a fresh boot without the daemon keeps the static colors.
    # Appended after all settings; later hl.config() calls win per-key.
    extraConfig = ''
      -- skein live colors
      do
        local p = os.getenv("HOME") .. "/.cache/skein/hyprland.lua"
        local f = io.open(p, "r")
        if f then f:close() dofile(p) end
      end
    '';

    settings = {
      config = {
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

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
          focus_on_activate = true;
          allow_session_lock_restore = true;
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
    };
  };
}
