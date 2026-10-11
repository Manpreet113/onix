-- Keybinds. Edit live, then `hyprctl reload` -- no rebuild needed.
local mod = "SUPER"

-- Apps (onix shell owns launcher/notifications — wofi retired)
hl.bind((mod .. " + RETURN"), (hl.dsp.exec_cmd("ghostty")))
hl.bind((mod .. " + SPACE"), (hl.dsp.exec_cmd("ags request -i onix launcher")))
hl.bind((mod .. " + COMMA"), (hl.dsp.exec_cmd("ags request -i onix control")))
hl.bind((mod .. " + N"), (hl.dsp.exec_cmd("ags request -i onix notifications")))
hl.bind((mod .. " + P"), (hl.dsp.exec_cmd("ags request -i onix powermenu")))
hl.bind((mod .. " + W"), (hl.dsp.exec_cmd("ags request -i onix wallpaper")))
hl.bind((mod .. " + S"), (hl.dsp.exec_cmd("ags request -i onix settings")))
hl.bind((mod .. " + Q"), (hl.dsp.window.close()))
hl.bind((mod .. " + SHIFT + L"), (hl.dsp.exec_cmd("hyprlock")))
hl.bind((mod .. " + F"), (hl.dsp.window.fullscreen()))
hl.bind((mod .. " + V"), (hl.dsp.window.float({ action = "toggle" })))

-- Screenshots (~/Pictures/Screenshots, clipboard via wl-copy)
hl.bind(("Print"), (hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png")))
hl.bind((mod .. " + SHIFT + S"), (hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")))

-- Focus
hl.bind((mod .. " + left"), (hl.dsp.focus({ direction = "left" })))
hl.bind((mod .. " + right"), (hl.dsp.focus({ direction = "right" })))
hl.bind((mod .. " + up"), (hl.dsp.focus({ direction = "up" })))
hl.bind((mod .. " + down"), (hl.dsp.focus({ direction = "down" })))

-- Move
hl.bind((mod .. " + SHIFT + left"), (hl.dsp.window.move({ direction = "left" })))
hl.bind((mod .. " + SHIFT + right"), (hl.dsp.window.move({ direction = "right" })))
hl.bind((mod .. " + SHIFT + up"), (hl.dsp.window.move({ direction = "up" })))
hl.bind((mod .. " + SHIFT + down"), (hl.dsp.window.move({ direction = "down" })))

-- Mouse
hl.bind((mod .. " + mouse_down"), (hl.dsp.focus({ workspace = "e+1" })))
hl.bind((mod .. " + mouse_up"), (hl.dsp.focus({ workspace = "e-1" })))
hl.bind((mod .. " + mouse:272"), (hl.dsp.window.drag()), {
  ["mouse"] = true,
})
hl.bind((mod .. " + mouse:273"), (hl.dsp.window.resize()), {
  ["mouse"] = true,
})

-- Media keys (repeating where held)
hl.bind(("XF86AudioRaiseVolume"), (hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")), {
  ["repeating"] = true,
})
hl.bind(("XF86AudioLowerVolume"), (hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")), {
  ["repeating"] = true,
})
hl.bind(("XF86AudioMute"), (hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")), {
  ["repeating"] = true,
})
hl.bind(("XF86AudioPlay"), (hl.dsp.exec_cmd("playerctl play-pause")))
hl.bind(("XF86AudioNext"), (hl.dsp.exec_cmd("playerctl next")))
hl.bind(("XF86AudioPrev"), (hl.dsp.exec_cmd("playerctl previous")))
hl.bind(("XF86MonBrightnessUp"), (hl.dsp.exec_cmd("brightnessctl set 5%+")), {
  ["repeating"] = true,
})
hl.bind(("XF86MonBrightnessDown"), (hl.dsp.exec_cmd("brightnessctl set 5%-")), {
  ["repeating"] = true,
})

-- Workspaces 1-9
for i = 1, 9 do
  hl.bind((mod .. " + " .. i), (hl.dsp.focus({ workspace = i })))
  hl.bind((mod .. " + SHIFT + " .. i), (hl.dsp.window.move({ workspace = i })))
end
