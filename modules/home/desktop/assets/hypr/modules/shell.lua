-- Onix shell layer rules: blur + animation policy per namespace.
-- Namespaces match `WlrLayershell.namespace` in qs. Check live with
-- `hyprctl layers`.
hl.layer_rule({
  name = "onix-bar-blur",
  match = { namespace = "^onix-bar$" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.05,
  no_anim = true,
})

hl.layer_rule({
  name = "onix-popups-blur",
  match = { namespace = "^onix-popups$" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.05,
  dim_around = false,
})

hl.layer_rule({
  name = "onix-sheets-blur",
  match = { namespace = "^(onix-control|onix-notif-center|onix-settings|onix-fan|onix-picker|onix-spotlight)$" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.1,
  dim_around = true,
})

hl.layer_rule({
  name = "onix-overlay-noanim",
  match = { namespace = "^(onix-notifs|onix-osd|onix-frame|onix-wallpaper|onix-edge)$" },
  no_anim = true,
  ignore_alpha = 0.0,
})
