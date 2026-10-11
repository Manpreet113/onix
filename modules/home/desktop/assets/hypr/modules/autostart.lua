-- Wallpaper daemon + initial wallpaper + onix shell, started with the compositor.
hl.on("hyprland.start", function()
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("awww img /home/manpreet/Pictures/Wallpapers/ronin-shade.png")
  -- Onix shell (AGS v3). `ags run` picks up ~/.config/ags/app.ts (live
  -- symlink into ~/onix). Restart-safe: single instance named "onix".
  hl.exec_cmd("ags run")
end)
