-- Onix shell (owns the background too), started with the compositor.
hl.on("hyprland.start", function()
  -- Onix shell (Quickshell). `quickshell -c onix` loads
  -- ~/.config/quickshell/onix/shell.qml (live symlink into ~/onix).
  hl.exec_cmd("quickshell -c onix")
end)
