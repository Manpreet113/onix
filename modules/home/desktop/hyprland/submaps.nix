{lib, ...}: let
  raw = lib.generators.mkLuaInline;
in {
  wayland.windowManager.hyprland = {
    # Resize mode: SUPER+R enters, hjkl/arrows resize, Esc exits.
    # (String entries would render for hyprlang only; attrsets render for lua.)
    submaps = {
      resize = {
        settings = {
          bind = [
            {
              _args = [
                "h"
                (raw ''hl.dsp.window.resize({ x = -20, y = 0, relative = true })'')
              ];
            }
            {
              _args = [
                "j"
                (raw ''hl.dsp.window.resize({ x = 0, y = 20, relative = true })'')
              ];
            }
            {
              _args = [
                "k"
                (raw ''hl.dsp.window.resize({ x = 0, y = -20, relative = true })'')
              ];
            }
            {
              _args = [
                "l"
                (raw ''hl.dsp.window.resize({ x = 20, y = 0, relative = true })'')
              ];
            }
            {
              _args = [
                "left"
                (raw ''hl.dsp.window.resize({ x = -20, y = 0, relative = true })'')
              ];
            }
            {
              _args = [
                "right"
                (raw ''hl.dsp.window.resize({ x = 20, y = 0, relative = true })'')
              ];
            }
            {
              _args = [
                "up"
                (raw ''hl.dsp.window.resize({ x = 0, y = -20, relative = true })'')
              ];
            }
            {
              _args = [
                "down"
                (raw ''hl.dsp.window.resize({ x = 0, y = 20, relative = true })'')
              ];
            }
            {
              _args = [
                "escape"
                (raw ''hl.dsp.submap("reset")'')
              ];
            }
          ];
        };
      };
    };
  };
}
