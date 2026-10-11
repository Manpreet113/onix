-- Floating rules.
hl.window_rule({
  ["float"] = true,
  ["match"] = {
    ["class"] = "^(org.gnome.Nautilus)$",
  },
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["class"] = "^(pavucontrol)$",
  },
  ["size"] = "800 600",
})
hl.window_rule({
  ["center"] = true,
  ["float"] = true,
  ["match"] = {
    ["class"] = "^(blueman-manager)$",
  },
  ["size"] = "800 600",
})
hl.window_rule({
  ["float"] = true,
  ["match"] = {
    ["title"] = "^(Picture-in-Picture)$",
  },
})
