# Hyprland session (doty philosophy): nix owns the package, the session
# target, and the generated entry stub; all compositor config lives
# hand-written in assets/hypr/modules, symlinked live so edits apply on
# `hyprctl reload` with no rebuild. The repo must stay at ~/onix (the
# symlink below points into the working tree, not the store).
{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;

    # Entry stub: systemd hooks (generated) plus require() of the live
    # modules. Safe-require notifies instead of breaking the session.
    extraLuaFiles = {
      startup = ''
        local function safe_require(module)
            local status, err = pcall(require, module)
            if not status then
                local msg = "Failed to load Hyprland module: " .. tostring(module) .. "\nError: " .. tostring(err)
                print(msg)
                os.execute("notify-send -u critical -a 'Hyprland' 'Config Error' '" .. msg:gsub("'", "'\\'''") .. "'")
            end
        end

        safe_require("modules.core.monitors")
        safe_require("modules.core.input")
        safe_require("modules.gestures")
        safe_require("modules.binds")
        safe_require("modules.autostart")
        safe_require("modules.env")
        safe_require("modules.decorations")
        safe_require("modules.layout")
        safe_require("modules.misc")
        safe_require("modules.windowrules")
        safe_require("modules.shell")
      '';
    };
  };

  # Live tree: ~/.config/hypr/modules -> repo working tree.
  xdg.configFile."hypr/modules".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/onix/modules/home/desktop/assets/hypr/modules";

  # Tools referenced by the binds above. Launcher/notifications are owned
  # by the onix shell (quickshell); wofi is retired.
  home.packages = with pkgs; [
    brightnessctl
    playerctl
    wl-clipboard
    grim
    slurp
    libnotify
  ];
}
