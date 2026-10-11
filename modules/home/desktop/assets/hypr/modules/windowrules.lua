-- Floating rules.
hl.window_rule({
  name = "nautilus-float",
  match = {
    class = "^(org.gnome.Nautilus)$",
  },
  float = true,
})
hl.window_rule({
  name = "pavucontrol-float",
  match = {
    class = "^(pavucontrol)$",
  },
  float = true,
  center = true,
  size = "800 600",
})
hl.window_rule({
  name = "blueman-float",
  match = {
    class = "^(blueman-manager)$",
  },
  float = true,
  center = true,
  size = "800 600",
})
hl.window_rule({
  name = "pip-float",
  match = {
    title = "^(Picture-in-Picture)$",
  },
  float = true,
})
