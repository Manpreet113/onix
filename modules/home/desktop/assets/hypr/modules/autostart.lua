-- Wallpaper daemon + initial wallpaper, started with the compositor.
hl.on("hyprland.start", function()
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("awww img /home/manpreet/Pictures/Wallpapers/ronin-shade.png")
end)
