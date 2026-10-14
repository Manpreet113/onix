-- Wallpaper daemon + initial wallpaper + onix shell, started with the compositor.
hl.on("hyprland.start", function()
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("awww img /home/manpreet/Pictures/Wallpapers/ronin-shade.png")
  -- Onix shell (Quickshell). `quickshell -c onix` loads
  -- ~/.config/quickshell/onix/shell.qml (live symlink into ~/onix).
  hl.exec_cmd("quickshell -c onix")
end)
